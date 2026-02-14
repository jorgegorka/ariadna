module Ariadna
  module Tools
    module CLI
      def self.run(argv)
        command = argv.shift
        raw = argv.delete("--raw")

        case command
        when "state"
          require_relative "state_manager"
          StateManager.dispatch(argv, raw: raw)
        when "resolve-model"
          require_relative "model_profiles"
          ModelProfiles.resolve(argv, raw: raw)
        when "find-phase"
          require_relative "phase_manager"
          PhaseManager.find(argv, raw: raw)
        when "commit"
          require_relative "git_integration"
          GitIntegration.commit(argv, raw: raw)
        when "generate-slug"
          require_relative "utilities"
          Utilities.generate_slug(argv, raw: raw)
        when "current-timestamp"
          require_relative "utilities"
          Utilities.current_timestamp(argv, raw: raw)
        when "list-todos"
          require_relative "utilities"
          Utilities.list_todos(argv, raw: raw)
        when "verify-path-exists"
          require_relative "utilities"
          Utilities.verify_path_exists(argv, raw: raw)
        when "verify-summary"
          require_relative "verification"
          Verification.verify_summary(argv, raw: raw)
        when "config-ensure-section"
          require_relative "config_manager"
          ConfigManager.ensure_section(argv, raw: raw)
        when "config-set"
          require_relative "config_manager"
          ConfigManager.set(argv, raw: raw)
        when "history-digest"
          require_relative "state_manager"
          StateManager.history_digest(argv, raw: raw)
        when "summary-extract"
          require_relative "state_manager"
          StateManager.summary_extract(argv, raw: raw)
        when "state-snapshot"
          require_relative "state_manager"
          StateManager.snapshot(argv, raw: raw)
        when "phase-plan-index"
          require_relative "phase_manager"
          PhaseManager.plan_index(argv, raw: raw)
        when "phase"
          require_relative "phase_manager"
          PhaseManager.dispatch(argv, raw: raw)
        when "phases"
          require_relative "phase_manager"
          PhaseManager.phases_dispatch(argv, raw: raw)
        when "roadmap"
          require_relative "roadmap_analyzer"
          RoadmapAnalyzer.dispatch(argv, raw: raw)
        when "milestone"
          require_relative "phase_manager"
          PhaseManager.milestone_dispatch(argv, raw: raw)
        when "validate"
          require_relative "verification"
          Verification.validate_dispatch(argv, raw: raw)
        when "progress"
          require_relative "roadmap_analyzer"
          RoadmapAnalyzer.progress(argv, raw: raw)
        when "todo"
          require_relative "utilities"
          Utilities.todo_dispatch(argv, raw: raw)
        when "scaffold"
          require_relative "template_filler"
          TemplateFiller.scaffold(argv, raw: raw)
        when "template"
          require_relative "template_filler"
          TemplateFiller.dispatch(argv, raw: raw)
        when "frontmatter"
          require_relative "frontmatter"
          Frontmatter.dispatch(argv, raw: raw)
        when "verify"
          require_relative "verification"
          Verification.dispatch(argv, raw: raw)
        when "init"
          require_relative "init"
          Init.dispatch(argv, raw: raw)
        else
          warn "Error: Unknown command: #{command}"
          warn "Run ariadna-tools --help for available commands."
          exit 1
        end
      end
    end
  end
end
