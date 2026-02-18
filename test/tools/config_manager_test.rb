require "test_helper"
require "ariadna/tools/config_manager"

class ConfigManagerTest < Minitest::Test
  def setup
    @dir = Dir.mktmpdir
    @planning_dir = File.join(@dir, ".planning")
    FileUtils.mkdir_p(@planning_dir)
  end

  def teardown
    FileUtils.rm_rf(@dir)
  end

  def test_load_defaults_when_no_config
    config = Ariadna::Tools::ConfigManager.load_config(@dir)
    assert_equal "balanced", config["model_profile"]
    assert_equal true, config["commit_docs"]
    assert_equal "none", config["branching_strategy"]
    assert_equal true, config["parallelization"]
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

  def test_load_nested_workflow_config
    config_data = {
      "model_profile" => "budget",
      "workflow" => {
        "research" => false,
        "plan_check" => false,
        "verifier" => true
      }
    }
    File.write(File.join(@planning_dir, "config.json"), JSON.pretty_generate(config_data))

    config = Ariadna::Tools::ConfigManager.load_config(@dir)
    assert_equal "budget", config["model_profile"]
    assert_equal false, config["research"]
    assert_equal false, config["plan_checker"]
    assert_equal true, config["verifier"]
  end

  def test_load_malformed_json_returns_defaults
    File.write(File.join(@planning_dir, "config.json"), "not json")
    config = Ariadna::Tools::ConfigManager.load_config(@dir)
    assert_equal "balanced", config["model_profile"]
  end

  def test_load_defaults_include_execution_mode
    config = Ariadna::Tools::ConfigManager.load_config(@dir)
    assert_equal "vertical", config["execution_mode"]
    assert_equal false, config["team_execution"]
  end

  def test_load_custom_execution_mode
    config_data = {
      "execution_mode" => "domain-split",
      "team_execution" => true
    }
    File.write(File.join(@planning_dir, "config.json"), JSON.pretty_generate(config_data))

    config = Ariadna::Tools::ConfigManager.load_config(@dir)
    assert_equal "domain-split", config["execution_mode"]
    assert_equal true, config["team_execution"]
  end

  def test_load_auto_team_execution
    config_data = { "team_execution" => "auto" }
    File.write(File.join(@planning_dir, "config.json"), JSON.pretty_generate(config_data))

    config = Ariadna::Tools::ConfigManager.load_config(@dir)
    assert_equal "auto", config["team_execution"]
  end

  def test_load_auto_team_execution_nested
    config_data = { "execution" => { "team" => "auto" } }
    File.write(File.join(@planning_dir, "config.json"), JSON.pretty_generate(config_data))

    config = Ariadna::Tools::ConfigManager.load_config(@dir)
    assert_equal "auto", config["team_execution"]
  end

  def test_load_invalid_team_execution_returns_default
    config_data = { "team_execution" => "invalid" }
    File.write(File.join(@planning_dir, "config.json"), JSON.pretty_generate(config_data))

    config = Ariadna::Tools::ConfigManager.load_config(@dir)
    assert_equal false, config["team_execution"]
  end

  def test_load_nested_execution_config
    config_data = {
      "execution" => {
        "mode" => "domain-split",
        "team" => true
      }
    }
    File.write(File.join(@planning_dir, "config.json"), JSON.pretty_generate(config_data))

    config = Ariadna::Tools::ConfigManager.load_config(@dir)
    assert_equal "domain-split", config["execution_mode"]
    assert_equal true, config["team_execution"]
  end
end
