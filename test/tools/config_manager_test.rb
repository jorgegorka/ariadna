require "test_helper"
require "ariadna/tools/config_manager"

class ConfigManagerTest < Minitest::Test
  def setup
    @dir = Dir.mktmpdir
    @planning_dir = File.join(@dir, ".ariadna_planning")
    FileUtils.mkdir_p(@planning_dir)
  end

  def teardown
    FileUtils.rm_rf(@dir)
  end

  def test_default_config_2_0
    config = Ariadna::Tools::ConfigManager.load_config(@dir)
    assert_equal "balanced", config["model_profile"]
    assert_equal true, config["verifier"]
    assert_equal "none", config["branching_strategy"]
    assert_equal "ariadna/phase-{phase}-{slug}", config["phase_branch_template"]
    assert_equal "ariadna/{milestone}-{slug}", config["milestone_branch_template"]
    assert_equal true, config["commit_docs"]
    assert_equal false, config["search_gitignored"]
    assert_equal true, config["parallelization"]
    # Removed settings should not be present
    refute config.key?("team_execution")
    refute config.key?("research")
    refute config.key?("plan_checker")
    refute config.key?("execution_mode")
  end

  def test_load_custom_config
    config_data = {
      "model_profile" => "quality",
      "commit_docs" => false,
      "parallelization" => false
    }
    File.write(File.join(@planning_dir, "config.json"), JSON.pretty_generate(config_data))

    config = Ariadna::Tools::ConfigManager.load_config(@dir)
    assert_equal "quality", config["model_profile"]
    assert_equal false, config["commit_docs"]
    assert_equal false, config["parallelization"]
  end

  def test_load_partial_config_fills_defaults
    config_data = { "model_profile" => "budget" }
    File.write(File.join(@planning_dir, "config.json"), JSON.pretty_generate(config_data))

    config = Ariadna::Tools::ConfigManager.load_config(@dir)
    assert_equal "budget", config["model_profile"]
    assert_equal true, config["verifier"]
    assert_equal "none", config["branching_strategy"]
    assert_equal true, config["parallelization"]
  end

  def test_load_malformed_json_returns_defaults
    File.write(File.join(@planning_dir, "config.json"), "not json")
    config = Ariadna::Tools::ConfigManager.load_config(@dir)
    assert_equal "balanced", config["model_profile"]
  end

  def test_load_preserves_false_values
    config_data = { "verifier" => false, "commit_docs" => false }
    File.write(File.join(@planning_dir, "config.json"), JSON.pretty_generate(config_data))

    config = Ariadna::Tools::ConfigManager.load_config(@dir)
    assert_equal false, config["verifier"]
    assert_equal false, config["commit_docs"]
  end

  def test_load_ignores_unknown_keys
    config_data = { "model_profile" => "quality", "unknown_setting" => true }
    File.write(File.join(@planning_dir, "config.json"), JSON.pretty_generate(config_data))

    config = Ariadna::Tools::ConfigManager.load_config(@dir)
    assert_equal "quality", config["model_profile"]
    refute config.key?("unknown_setting")
  end
end
