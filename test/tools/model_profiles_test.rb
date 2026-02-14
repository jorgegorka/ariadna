require "test_helper"
require "ariadna/tools/model_profiles"

class ModelProfilesTest < Minitest::Test
  def test_resolve_model_balanced
    assert_equal "opus", Ariadna::Tools::ModelProfiles.resolve_model("ariadna-planner", "balanced")
    assert_equal "sonnet", Ariadna::Tools::ModelProfiles.resolve_model("ariadna-executor", "balanced")
    assert_equal "haiku", Ariadna::Tools::ModelProfiles.resolve_model("ariadna-codebase-mapper", "balanced")
  end

  def test_resolve_model_quality
    assert_equal "opus", Ariadna::Tools::ModelProfiles.resolve_model("ariadna-planner", "quality")
    assert_equal "opus", Ariadna::Tools::ModelProfiles.resolve_model("ariadna-executor", "quality")
    assert_equal "sonnet", Ariadna::Tools::ModelProfiles.resolve_model("ariadna-codebase-mapper", "quality")
  end

  def test_resolve_model_budget
    assert_equal "sonnet", Ariadna::Tools::ModelProfiles.resolve_model("ariadna-planner", "budget")
    assert_equal "sonnet", Ariadna::Tools::ModelProfiles.resolve_model("ariadna-executor", "budget")
    assert_equal "haiku", Ariadna::Tools::ModelProfiles.resolve_model("ariadna-codebase-mapper", "budget")
  end

  def test_resolve_unknown_agent
    assert_equal "sonnet", Ariadna::Tools::ModelProfiles.resolve_model("unknown-agent", "balanced")
  end

  def test_all_agents_have_profiles
    expected = %w[
      ariadna-planner ariadna-roadmapper ariadna-executor
      ariadna-phase-researcher ariadna-project-researcher
      ariadna-research-synthesizer ariadna-debugger
      ariadna-codebase-mapper ariadna-verifier
      ariadna-plan-checker ariadna-integration-checker
    ]
    expected.each do |agent|
      refute_nil Ariadna::Tools::ModelProfiles::PROFILES[agent], "Missing profile for #{agent}"
    end
  end
end
