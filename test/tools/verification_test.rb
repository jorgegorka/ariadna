require "test_helper"
require "ariadna/tools/verification"

class VerificationTest < Minitest::Test
  def setup
    @dir = Dir.mktmpdir
    @planning_dir = File.join(@dir, ".ariadna_planning")
    @phases_dir = File.join(@planning_dir, "phases")
    FileUtils.mkdir_p(@phases_dir)
  end

  def teardown
    FileUtils.rm_rf(@dir)
  end

  def test_verify_summary_passes_for_valid_summary
    summary = <<~MD
      ---
      phase: 01-setup
      plan: 01
      ---

      # Summary

      ## Self-Check
      All checks pass ✅
    MD
    File.write(File.join(@planning_dir, "test-SUMMARY.md"), summary)

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::Verification.verify_summary([".ariadna_planning/test-SUMMARY.md"]) }
      assert result[:passed]
      assert result[:checks][:summary_exists]
    end
  end

  def test_verify_summary_fails_for_missing_file
    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::Verification.verify_summary([".ariadna_planning/missing-SUMMARY.md"]) }
      refute result[:passed]
      refute result[:checks][:summary_exists]
    end
  end

  def test_verify_summary_detects_failed_self_check
    summary = "---\nphase: 01\n---\n\n## Self-Check\nSome tests failed ❌\n"
    File.write(File.join(@planning_dir, "bad-SUMMARY.md"), summary)

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::Verification.verify_summary([".ariadna_planning/bad-SUMMARY.md"]) }
      refute result[:passed]
      assert_equal "failed", result[:checks][:self_check]
    end
  end

  def test_verify_plan_structure_valid
    plan = <<~MD
      ---
      phase: 01-setup
      plan: 01
      type: execute
      wave: 1
      depends_on: []
      files_modified: []
      autonomous: true
      must_haves:
        truths: []
        artifacts: []
        key_links: []
      ---

      # Plan

      <task type="code">
        <name>Create files</name>
        <files>src/main.rb</files>
        <action>Create the main file</action>
        <verify>File exists</verify>
        <done>File created</done>
      </task>
    MD
    File.write(File.join(@dir, "test-PLAN.md"), plan)

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::Verification.verify_plan_structure("test-PLAN.md") }
      assert result[:valid]
      assert_equal 1, result[:task_count]
      assert_empty result[:errors]
    end
  end

  def test_verify_plan_structure_missing_fields
    plan = "---\nphase: 01\n---\n\n# Plan\n"
    File.write(File.join(@dir, "bad-PLAN.md"), plan)

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::Verification.verify_plan_structure("bad-PLAN.md") }
      refute result[:valid]
      assert result[:errors].any? { |e| e.include?("Missing required frontmatter") }
    end
  end

  def test_verify_phase_completeness_complete
    phase_dir = File.join(@phases_dir, "01-setup")
    FileUtils.mkdir_p(phase_dir)
    File.write(File.join(phase_dir, "01-01-PLAN.md"), "plan")
    File.write(File.join(phase_dir, "01-01-SUMMARY.md"), "summary")

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::Verification.verify_phase_completeness("1") }
      assert result[:complete]
      assert_equal 1, result[:plan_count]
      assert_equal 1, result[:summary_count]
      assert_empty result[:incomplete_plans]
    end
  end

  def test_verify_phase_completeness_incomplete
    phase_dir = File.join(@phases_dir, "01-setup")
    FileUtils.mkdir_p(phase_dir)
    File.write(File.join(phase_dir, "01-01-PLAN.md"), "plan")
    File.write(File.join(phase_dir, "01-02-PLAN.md"), "plan2")
    File.write(File.join(phase_dir, "01-01-SUMMARY.md"), "summary")

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::Verification.verify_phase_completeness("1") }
      refute result[:complete]
      assert_equal 1, result[:incomplete_plans].length
    end
  end

  def test_verify_references_finds_existing_files
    FileUtils.mkdir_p(File.join(@dir, "src"))
    File.write(File.join(@dir, "src", "main.rb"), "code")

    content = "Check `src/main.rb` and @src/main.rb for details."
    File.write(File.join(@dir, "test.md"), content)

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::Verification.verify_references("test.md") }
      assert result[:valid]
      assert_equal 0, result[:missing].length
    end
  end

  def test_verify_references_reports_missing
    content = "Check `nonexistent/file.rb` for details."
    File.write(File.join(@dir, "test.md"), content)

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::Verification.verify_references("test.md") }
      refute result[:valid]
      assert_includes result[:missing], "nonexistent/file.rb"
    end
  end

  def test_validate_consistency_passes
    roadmap = "# ROADMAP\n\n### Phase 1: Setup\n\n**Goal:** TBD\n\n### Phase 2: Auth\n\n**Goal:** TBD\n"
    File.write(File.join(@planning_dir, "ROADMAP.md"), roadmap)

    FileUtils.mkdir_p(File.join(@phases_dir, "01-setup"))
    FileUtils.mkdir_p(File.join(@phases_dir, "02-auth"))

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::Verification.validate_consistency }
      assert result[:passed]
      assert_empty result[:errors]
    end
  end

  def test_validate_consistency_detects_gaps
    roadmap = "# ROADMAP\n\n### Phase 1: Setup\n\n### Phase 3: Deploy\n"
    File.write(File.join(@planning_dir, "ROADMAP.md"), roadmap)

    FileUtils.mkdir_p(File.join(@phases_dir, "01-setup"))
    FileUtils.mkdir_p(File.join(@phases_dir, "03-deploy"))

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::Verification.validate_consistency }
      assert result[:passed] # gaps are warnings, not errors
      assert result[:warnings].any? { |w| w.include?("Gap in phase numbering") }
    end
  end

  def test_validate_consistency_no_roadmap
    FileUtils.rm_f(File.join(@planning_dir, "ROADMAP.md"))

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::Verification.validate_consistency }
      refute result[:passed]
      assert_includes result[:errors], "ROADMAP.md not found"
    end
  end

  private

  def capture_json(&block)
    output = capture_output(&block)
    JSON.parse(output, symbolize_names: true)
  end

  def capture_output
    old_stdout = $stdout
    $stdout = StringIO.new
    yield
  rescue SystemExit
    # Output.json calls exit(0)
  ensure
    result = $stdout.string
    $stdout = old_stdout
    return result
  end
end
