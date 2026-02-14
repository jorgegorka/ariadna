# frozen_string_literal: true

require "test_helper"
require "ariadna/tools/template_filler"

class TemplateFillerTest < Minitest::Test
  def setup
    @dir = Dir.mktmpdir
    @planning_dir = File.join(@dir, ".planning")
    @phases_dir = File.join(@planning_dir, "phases")
    @phase_dir = File.join(@phases_dir, "01-setup")
    FileUtils.mkdir_p(@phase_dir)
  end

  def teardown
    FileUtils.rm_rf(@dir)
  end

  def test_select_minimal_template
    plan = "---\nphase: 01\nplan: 01\n---\n\n# Plan\n\n### Task 1\nDo something\n"
    File.write(File.join(@dir, "test-PLAN.md"), plan)

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::TemplateFiller.select("test-PLAN.md") }
      assert_equal "minimal", result[:type]
      assert_includes result[:template], "minimal"
    end
  end

  def test_select_complex_template
    plan = "---\nphase: 01\nplan: 01\n---\n\n# Plan\n\n"
    plan += (1..6).map { |i| "### Task #{i}\nDo something with `src/file#{i}.rb`\n\nA decision was made.\n" }.join("\n")
    File.write(File.join(@dir, "complex-PLAN.md"), plan)

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::TemplateFiller.select("complex-PLAN.md") }
      assert_equal "complex", result[:type]
    end
  end

  def test_select_standard_template
    plan = "---\nphase: 01\nplan: 01\n---\n\n# Plan\n\n"
    plan += (1..3).map { |i| "### Task #{i}\nDo something with `src/path/file#{i}.rb`\n" }.join("\n")
    File.write(File.join(@dir, "std-PLAN.md"), plan)

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::TemplateFiller.select("std-PLAN.md") }
      assert_equal "standard", result[:type]
    end
  end

  def test_fill_summary_template
    Dir.chdir(@dir) do
      result = capture_json do
        Ariadna::Tools::TemplateFiller.fill("summary", { phase: "1", plan: "01", name: "Setup" })
      end
      assert result[:created]
      assert_includes result[:path], "SUMMARY.md"
      assert File.exist?(File.join(@dir, result[:path]))
    end
  end

  def test_fill_plan_template
    Dir.chdir(@dir) do
      result = capture_json do
        Ariadna::Tools::TemplateFiller.fill("plan", { phase: "1", plan: "01", type: "execute", wave: "1" })
      end
      assert result[:created]
      assert_includes result[:path], "PLAN.md"

      content = File.read(File.join(@dir, result[:path]))
      assert_includes content, "## Objective"
      assert_includes content, "## Tasks"
    end
  end

  def test_fill_verification_template
    Dir.chdir(@dir) do
      result = capture_json do
        Ariadna::Tools::TemplateFiller.fill("verification", { phase: "1" })
      end
      assert result[:created]
      assert_includes result[:path], "VERIFICATION.md"
    end
  end

  def test_fill_does_not_overwrite
    File.write(File.join(@phase_dir, "01-01-SUMMARY.md"), "existing")

    Dir.chdir(@dir) do
      result = capture_json do
        Ariadna::Tools::TemplateFiller.fill("summary", { phase: "1", plan: "01" })
      end
      assert result[:error]
      assert_includes result[:error], "already exists"
    end
  end

  def test_scaffold_context
    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::TemplateFiller.scaffold(["context", "--phase", "1"]) }
      assert result[:created]
      assert_includes result[:path], "CONTEXT.md"
    end
  end

  def test_scaffold_uat
    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::TemplateFiller.scaffold(["uat", "--phase", "1"]) }
      assert result[:created]
      assert_includes result[:path], "UAT.md"
    end
  end

  def test_scaffold_verification
    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::TemplateFiller.scaffold(["verification", "--phase", "1"]) }
      assert result[:created]
      assert_includes result[:path], "VERIFICATION.md"
    end
  end

  def test_scaffold_phase_dir
    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::TemplateFiller.scaffold(["phase-dir", "--phase", "3", "--name", "Deploy"]) }
      assert result[:created]
      assert_includes result[:directory], "03-deploy"
      assert File.directory?(File.join(@dir, ".planning", "phases", "03-deploy"))
    end
  end

  def test_scaffold_does_not_overwrite
    File.write(File.join(@phase_dir, "01-CONTEXT.md"), "existing")

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::TemplateFiller.scaffold(["context", "--phase", "1"]) }
      refute result[:created]
      assert_equal "already_exists", result[:reason]
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
