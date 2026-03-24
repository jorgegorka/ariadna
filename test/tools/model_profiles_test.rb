require "test_helper"
require "ariadna/tools/model_profiles"

class ModelProfilesTest < Minitest::Test
  def test_resolve_model_balanced
    assert_equal "opus",   Ariadna::Tools::ModelProfiles.resolve_model("ariadna-planner", "balanced")
    assert_equal "sonnet", Ariadna::Tools::ModelProfiles.resolve_model("ariadna-executor", "balanced")
    assert_equal "sonnet", Ariadna::Tools::ModelProfiles.resolve_model("ariadna-codebase-mapper", "balanced")
  end

  def test_resolve_model_quality
    assert_equal "opus",   Ariadna::Tools::ModelProfiles.resolve_model("ariadna-planner", "quality")
    assert_equal "opus",   Ariadna::Tools::ModelProfiles.resolve_model("ariadna-executor", "quality")
    assert_equal "sonnet", Ariadna::Tools::ModelProfiles.resolve_model("ariadna-codebase-mapper", "quality")
  end

  def test_resolve_model_budget
    assert_equal "sonnet", Ariadna::Tools::ModelProfiles.resolve_model("ariadna-planner", "budget")
    assert_equal "sonnet", Ariadna::Tools::ModelProfiles.resolve_model("ariadna-executor", "budget")
    assert_equal "haiku",  Ariadna::Tools::ModelProfiles.resolve_model("ariadna-codebase-mapper", "budget")
  end

  def test_resolve_unknown_agent
    assert_equal "sonnet", Ariadna::Tools::ModelProfiles.resolve_model("unknown-agent", "balanced")
  end

  def test_new_agent_list
    expected_agents = %w[
      ariadna-planner ariadna-executor ariadna-verifier
      ariadna-debugger ariadna-roadmapper ariadna-codebase-mapper
    ]
    assert_equal expected_agents.sort, Ariadna::Tools::ModelProfiles::PROFILES.keys.sort
  end

  def test_removed_agents_not_in_profiles
    %w[ariadna-backend-executor ariadna-frontend-executor ariadna-test-executor
       ariadna-plan-checker ariadna-phase-researcher ariadna-project-researcher
       ariadna-research-synthesizer ariadna-integration-checker].each do |agent|
      refute Ariadna::Tools::ModelProfiles::PROFILES.key?(agent),
        "Removed agent '#{agent}' should not be in PROFILES"
    end
  end

  def test_all_agents_have_all_profiles
    %w[quality balanced budget].each do |profile|
      Ariadna::Tools::ModelProfiles::PROFILES.each_key do |agent|
        result = Ariadna::Tools::ModelProfiles.resolve_model(agent, profile)
        refute_nil result, "Agent '#{agent}' missing model for profile '#{profile}'"
      end
    end
  end
end
