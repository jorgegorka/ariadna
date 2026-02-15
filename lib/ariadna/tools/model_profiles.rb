require "json"
require_relative "output"
require_relative "config_manager"

module Ariadna
  module Tools
    module ModelProfiles
      PROFILES = {
        "ariadna-planner" =>              { "quality" => "opus", "balanced" => "opus",   "budget" => "sonnet" },
        "ariadna-roadmapper" =>           { "quality" => "opus", "balanced" => "sonnet", "budget" => "sonnet" },
        "ariadna-executor" =>             { "quality" => "opus", "balanced" => "sonnet", "budget" => "sonnet" },
        "ariadna-phase-researcher" =>     { "quality" => "opus", "balanced" => "sonnet", "budget" => "haiku" },
        "ariadna-project-researcher" =>   { "quality" => "opus", "balanced" => "sonnet", "budget" => "haiku" },
        "ariadna-research-synthesizer" => { "quality" => "sonnet", "balanced" => "sonnet", "budget" => "haiku" },
        "ariadna-debugger" =>             { "quality" => "opus", "balanced" => "sonnet", "budget" => "sonnet" },
        "ariadna-codebase-mapper" =>      { "quality" => "sonnet", "balanced" => "haiku", "budget" => "haiku" },
        "ariadna-verifier" =>             { "quality" => "sonnet", "balanced" => "sonnet", "budget" => "haiku" },
        "ariadna-plan-checker" =>         { "quality" => "sonnet", "balanced" => "sonnet", "budget" => "haiku" },
        "ariadna-integration-checker" =>  { "quality" => "sonnet", "balanced" => "sonnet", "budget" => "haiku" },
        "ariadna-backend-executor" =>   { "quality" => "opus", "balanced" => "sonnet", "budget" => "sonnet" },
        "ariadna-frontend-executor" =>  { "quality" => "opus", "balanced" => "sonnet", "budget" => "sonnet" },
        "ariadna-test-executor" =>      { "quality" => "opus", "balanced" => "sonnet", "budget" => "sonnet" }
      }.freeze

      def self.resolve(argv, raw: false)
        agent_type = argv.first
        Output.error("agent-type required") unless agent_type

        config = ConfigManager.load_config
        profile = config["model_profile"] || "balanced"

        agent_models = PROFILES[agent_type]
        unless agent_models
          Output.json({ model: "sonnet", profile: profile, unknown_agent: true }, raw: raw, raw_value: "sonnet")
          return
        end

        model = agent_models[profile] || agent_models["balanced"] || "sonnet"
        Output.json({ model: model, profile: profile }, raw: raw, raw_value: model)
      end

      def self.resolve_model(agent_type, profile = "balanced")
        agent_models = PROFILES[agent_type]
        return "sonnet" unless agent_models

        agent_models[profile] || agent_models["balanced"] || "sonnet"
      end
    end
  end
end
