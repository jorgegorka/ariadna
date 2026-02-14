require "json"
require_relative "output"

module Ariadna
  module Tools
    module ConfigManager
      DEFAULTS = {
        "model_profile" => "balanced",
        "commit_docs" => true,
        "search_gitignored" => false,
        "branching_strategy" => "none",
        "phase_branch_template" => "ariadna/phase-{phase}-{slug}",
        "milestone_branch_template" => "ariadna/{milestone}-{slug}",
        "research" => true,
        "plan_checker" => true,
        "verifier" => true,
        "parallelization" => true
      }.freeze

      def self.load_config(cwd = Dir.pwd)
        config_path = File.join(cwd, ".planning", "config.json")
        return DEFAULTS.dup unless File.exist?(config_path)

        raw = File.read(config_path)
        parsed = JSON.parse(raw)

        get = lambda do |key, nested = nil|
          return parsed[key] if parsed.key?(key)

          if nested && parsed[nested[:section]].is_a?(Hash)
            val = parsed[nested[:section]][nested[:field]]
            return val unless val.nil?
          end
          nil
        end

        parallelization = begin
          val = get.call("parallelization")
          if val.is_a?(Hash) && val.key?("enabled")
            val["enabled"]
          elsif [true, false].include?(val)
            val
          else
            DEFAULTS["parallelization"]
          end
        end

        # nil_or helper: use default only when value is nil (preserves false)
        nil_or = ->(val, default) { val.nil? ? default : val }

        {
          "model_profile" => get.call("model_profile") || DEFAULTS["model_profile"],
          "commit_docs" => nil_or.call(get.call("commit_docs", { section: "planning", field: "commit_docs" }), DEFAULTS["commit_docs"]),
          "search_gitignored" => nil_or.call(get.call("search_gitignored", { section: "planning", field: "search_gitignored" }), DEFAULTS["search_gitignored"]),
          "branching_strategy" => get.call("branching_strategy", { section: "git", field: "branching_strategy" }) || DEFAULTS["branching_strategy"],
          "phase_branch_template" => get.call("phase_branch_template", { section: "git", field: "phase_branch_template" }) || DEFAULTS["phase_branch_template"],
          "milestone_branch_template" => get.call("milestone_branch_template", { section: "git", field: "milestone_branch_template" }) || DEFAULTS["milestone_branch_template"],
          "research" => nil_or.call(get.call("research", { section: "workflow", field: "research" }), DEFAULTS["research"]),
          "plan_checker" => nil_or.call(get.call("plan_checker", { section: "workflow", field: "plan_check" }), DEFAULTS["plan_checker"]),
          "verifier" => nil_or.call(get.call("verifier", { section: "workflow", field: "verifier" }), DEFAULTS["verifier"]),
          "parallelization" => parallelization
        }
      rescue JSON::ParserError
        DEFAULTS.dup
      end

      def self.ensure_section(argv, raw: false)
        cwd = Dir.pwd
        config_path = File.join(cwd, ".planning", "config.json")
        planning_dir = File.join(cwd, ".planning")

        FileUtils.mkdir_p(planning_dir) unless File.directory?(planning_dir)

        if File.exist?(config_path)
          Output.json({ created: false, reason: "already_exists" }, raw: raw, raw_value: "exists")
          return
        end

        defaults = {
          model_profile: "balanced",
          commit_docs: true,
          search_gitignored: false,
          branching_strategy: "none",
          phase_branch_template: "ariadna/phase-{phase}-{slug}",
          milestone_branch_template: "ariadna/{milestone}-{slug}",
          workflow: {
            research: true,
            plan_check: true,
            verifier: true
          },
          parallelization: true
        }

        File.write(config_path, JSON.pretty_generate(defaults))
        Output.json({ created: true, path: ".planning/config.json" }, raw: raw, raw_value: "created")
      end

      def self.set(argv, raw: false)
        key_path = argv[0]
        value = argv[1]
        Output.error("Usage: config-set <key.path> <value>") unless key_path

        cwd = Dir.pwd
        config_path = File.join(cwd, ".planning", "config.json")

        config = {}
        if File.exist?(config_path)
          config = JSON.parse(File.read(config_path))
        end

        parsed_value = case value
                       when "true" then true
                       when "false" then false
                       when /\A\d+\z/ then value.to_i
                       else value
                       end

        keys = key_path.split(".")
        current = config
        keys[0..-2].each do |key|
          current[key] = {} unless current[key].is_a?(Hash)
          current = current[key]
        end
        current[keys.last] = parsed_value

        File.write(config_path, JSON.pretty_generate(config))
        Output.json({ updated: true, key: key_path, value: parsed_value }, raw: raw, raw_value: "#{key_path}=#{parsed_value}")
      rescue JSON::ParserError => e
        Output.error("Failed to read config.json: #{e.message}")
      end
    end
  end
end
