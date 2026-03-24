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

  # --- verify commits ---

  def test_verify_commits_valid
    Dir.chdir(@dir) do
      system("git init -q && git commit --allow-empty -m 'init' -q")
      sha = `git rev-parse HEAD`.strip
      result = capture_json { Ariadna::Tools::Verification.dispatch(["commits", sha]) }
      assert result[:all_valid]
      assert_includes result[:valid], sha
    end
  end

  def test_verify_commits_invalid
    Dir.chdir(@dir) do
      system("git init -q && git commit --allow-empty -m 'init' -q")
      result = capture_json { Ariadna::Tools::Verification.dispatch(%w[commits deadbeef123456]) }
      refute result[:all_valid]
      assert_includes result[:invalid], "deadbeef123456"
    end
  end

  # --- phase-completeness ---

  def test_verify_phase_completeness_complete
    phase_dir = File.join(@phases_dir, "01-setup")
    FileUtils.mkdir_p(phase_dir)
    File.write(File.join(phase_dir, "01-01-PLAN.md"), "plan")
    File.write(File.join(phase_dir, "01-01-SUMMARY.md"), "summary")

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::Verification.dispatch(%w[phase-completeness 1]) }
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
      result = capture_json { Ariadna::Tools::Verification.dispatch(%w[phase-completeness 1]) }
      refute result[:complete]
      assert_equal 1, result[:incomplete_plans].length
    end
  end

  # --- artifacts ---

  def test_verify_artifacts_all_exist
    FileUtils.mkdir_p(File.join(@dir, "src"))
    File.write(File.join(@dir, "src", "main.rb"), "class Main\nend\n")

    plan = <<~MD
      ---
      phase: 01-setup
      plan: 01
      must_haves:
          artifacts:
            - path: src/main.rb
              min_lines: 2
      ---
      # Plan
    MD
    File.write(File.join(@dir, "test-PLAN.md"), plan)

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::Verification.dispatch(["artifacts", "test-PLAN.md"]) }
      assert result[:all_passed]
    end
  end

  def test_verify_artifacts_missing_file
    plan = <<~MD
      ---
      phase: 01-setup
      plan: 01
      must_haves:
          artifacts:
            - path: nonexistent/file.rb
      ---
      # Plan
    MD
    File.write(File.join(@dir, "test-PLAN.md"), plan)

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::Verification.dispatch(["artifacts", "test-PLAN.md"]) }
      refute result[:all_passed]
    end
  end

  # --- removed subcommands ---

  def test_removed_subcommands_return_error
    Dir.chdir(@dir) do
      %w[plan-structure references key-links].each do |cmd|
        assert_raises(SystemExit) { Ariadna::Tools::Verification.dispatch([cmd, "test.md"]) }
      end
    end
  end

  def test_dispatch_unknown_subcommand
    assert_raises(SystemExit) { Ariadna::Tools::Verification.dispatch(["nonexistent"]) }
  end

  private

  def capture_json(&)
    output = capture_output(&)
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
