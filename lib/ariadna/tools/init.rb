require "json"
require "fileutils"
require_relative "output"
require_relative "config_manager"
require_relative "model_profiles"
require_relative "frontmatter"
require_relative "state_manager"

module Ariadna
  module Tools
    # Lightweight workflow initialization: returns paths, metadata, and config.
    module Init # rubocop:disable Metrics/ModuleLength
      def self.dispatch(argv, raw: false) # rubocop:disable Metrics/CyclomaticComplexity
        workflow = argv.shift

        case workflow
        when "execute-phase"
          execute_phase(argv.first, raw: raw)
        when "plan-phase"
          plan_phase(argv.first, raw: raw)
        when "verify-work"
          verify_work(argv.first, raw: raw)
        when "new-project"
          new_project(raw: raw)
        when "new-milestone"
          new_milestone(raw: raw)
        when "quick"
          quick(argv.join(" "), raw: raw)
        when "resume"
          resume(raw: raw)
        when "phase-op"
          phase_op(argv.first, raw: raw)
        when "todos"
          todos(argv.first, raw: raw)
        when "milestone-op"
          milestone_op(raw: raw)
        when "map-codebase"
          map_codebase(raw: raw)
        when "progress"
          init_progress(raw: raw)
        else
          Output.error("Unknown init workflow: #{workflow}")
        end
      end

      def self.execute_phase(phase, raw: false)
        Output.error("phase required for init execute-phase") unless phase

        cwd = Dir.pwd
        config = ConfigManager.load_config(cwd)
        phase_info = find_phase(cwd, phase)
        plans = build_plan_metadata(cwd, phase_info)
        incomplete = incomplete_plan_files(cwd, phase_info)

        result = base_result(config).merge(
          executor_model: resolve_model(cwd, "ariadna-executor"),
          phase_found: !phase_info.nil?,
          phase_dir: phase_info&.dig(:directory),
          phase_number: phase_info&.dig(:phase_number),
          phase_name: phase_info&.dig(:phase_name),
          plans: plans,
          plan_count: plans.length,
          incomplete_plans: incomplete,
          incomplete_count: incomplete.length,
          milestone_version: milestone_version(cwd)
        )

        Output.json(result, raw: raw)
      end

      def self.plan_phase(phase, raw: false) # rubocop:disable Metrics/CyclomaticComplexity
        Output.error("phase required for init plan-phase") unless phase

        cwd = Dir.pwd
        config = ConfigManager.load_config(cwd)
        phase_info = find_phase(cwd, phase)

        result = base_result(config).merge(
          planner_model: resolve_model(cwd, "ariadna-planner"),
          phase_found: !phase_info.nil?,
          phase_dir: phase_info&.dig(:directory),
          phase_number: phase_info&.dig(:phase_number),
          phase_name: phase_info&.dig(:phase_name),
          padded_phase: phase_info&.dig(:phase_number)&.rjust(2, "0"),
          has_research: phase_info&.dig(:has_research) || false,
          has_context: phase_info&.dig(:has_context) || false,
          plan_count: phase_info&.dig(:plans)&.length || 0
        )

        Output.json(result, raw: raw)
      end

      def self.verify_work(phase, raw: false)
        Output.error("phase required for init verify-work") unless phase

        cwd = Dir.pwd
        config = ConfigManager.load_config(cwd)
        phase_info = find_phase(cwd, phase)
        summaries = phase_info&.dig(:summaries) || []

        summary_paths = summaries.map do |s|
          File.join(phase_info[:directory], s)
        end

        result = base_result(config).merge(
          verifier_model: resolve_model(cwd, "ariadna-verifier"),
          phase_found: !phase_info.nil?,
          phase_dir: phase_info&.dig(:directory),
          phase_number: phase_info&.dig(:phase_number),
          phase_name: phase_info&.dig(:phase_name),
          has_verification: phase_info&.dig(:has_verification) || false,
          summary_paths: summary_paths
        )

        Output.json(result, raw: raw)
      end

      def self.new_project(raw: false)
        cwd = Dir.pwd
        config = ConfigManager.load_config(cwd)

        result = base_result(config).merge(
          researcher_model: resolve_model(cwd, "ariadna-project-researcher"),
          roadmapper_model: resolve_model(cwd, "ariadna-roadmapper"),
          is_brownfield: detect_brownfield(cwd),
          has_git: File.exist?(File.join(cwd, ".git")),
          planning_exists: File.directory?(File.join(cwd, ".ariadna_planning"))
        )

        Output.json(result, raw: raw)
      end

      def self.new_milestone(raw: false)
        cwd = Dir.pwd
        config = ConfigManager.load_config(cwd)

        result = base_result(config).merge(
          roadmapper_model: resolve_model(cwd, "ariadna-roadmapper"),
          current_milestone: milestone_version(cwd)
        )

        Output.json(result, raw: raw)
      end

      def self.quick(description, raw: false)
        cwd = Dir.pwd
        config = ConfigManager.load_config(cwd)
        slug = generate_slug(description)&.slice(0, 40) if description && !description.empty?
        next_num = next_quick_number(cwd)

        result = base_result(config).merge(
          planner_model: resolve_model(cwd, "ariadna-planner"),
          executor_model: resolve_model(cwd, "ariadna-executor"),
          next_num: next_num,
          slug: slug,
          description: description && !description.empty? ? description : nil,
          quick_dir: ".ariadna_planning/quick",
          task_dir: slug ? ".ariadna_planning/quick/#{next_num}-#{slug}" : nil
        )

        Output.json(result, raw: raw)
      end

      def self.resume(raw: false)
        cwd = Dir.pwd
        config = ConfigManager.load_config(cwd)

        agent_file = File.join(cwd, ".ariadna_planning", "current-agent-id.txt")
        agent_id = File.exist?(agent_file) ? File.read(agent_file).strip : nil

        result = base_result(config).merge(
          has_interrupted_agent: !agent_id.nil?,
          interrupted_agent_id: agent_id,
          planning_exists: File.directory?(File.join(cwd, ".ariadna_planning"))
        )

        Output.json(result, raw: raw)
      end

      def self.phase_op(phase, raw: false) # rubocop:disable Metrics/CyclomaticComplexity
        cwd = Dir.pwd
        config = ConfigManager.load_config(cwd)
        phase_info = find_phase(cwd, phase)

        result = base_result(config).merge(
          phase_found: !phase_info.nil?,
          phase_dir: phase_info&.dig(:directory),
          phase_number: phase_info&.dig(:phase_number),
          phase_name: phase_info&.dig(:phase_name),
          padded_phase: phase_info&.dig(:phase_number)&.rjust(2, "0"),
          has_research: phase_info&.dig(:has_research) || false,
          has_context: phase_info&.dig(:has_context) || false,
          has_verification: phase_info&.dig(:has_verification) || false,
          plan_count: phase_info&.dig(:plans)&.length || 0
        )

        Output.json(result, raw: raw)
      end

      def self.todos(area, raw: false)
        cwd = Dir.pwd
        config = ConfigManager.load_config(cwd)
        todo_list = collect_todos(cwd, area)

        result = base_result(config).merge(
          todo_count: todo_list.length,
          todos: todo_list,
          area_filter: area,
          pending_dir: ".ariadna_planning/todos/pending"
        )

        Output.json(result, raw: raw)
      end

      def self.milestone_op(raw: false)
        cwd = Dir.pwd
        config = ConfigManager.load_config(cwd)

        result = base_result(config).merge(
          milestone_version: milestone_version(cwd),
          planning_exists: File.directory?(File.join(cwd, ".ariadna_planning"))
        )

        Output.json(result, raw: raw)
      end

      def self.map_codebase(raw: false)
        cwd = Dir.pwd
        config = ConfigManager.load_config(cwd)

        result = base_result(config).merge(
          mapper_model: resolve_model(cwd, "ariadna-codebase-mapper"),
          codebase_dir: ".ariadna_planning/codebase"
        )

        Output.json(result, raw: raw)
      end

      def self.init_progress(raw: false)
        cwd = Dir.pwd
        config = ConfigManager.load_config(cwd)
        phases = scan_phases(cwd)

        result = base_result(config).merge(
          milestone_version: milestone_version(cwd),
          phases: phases,
          phase_count: phases.length,
          completed_count: phases.count { |p| p[:status] == "complete" },
          in_progress_count: phases.count { |p| p[:status] == "in_progress" },
          has_work_in_progress: phases.any? { |p| p[:status] == "in_progress" }
        )

        Output.json(result, raw: raw)
      end

      # --- Private helpers ---

      def self.base_result(config)
        { memory_dir: StateManager::MEMORY_DIR, config: config }
      end

      def self.find_phase(cwd, phase)
        return nil unless phase

        phases_dir = File.join(cwd, ".ariadna_planning", "phases")
        normalized = normalize_phase(phase)
        return nil unless File.directory?(phases_dir)

        dirs = Dir.children(phases_dir).select { |d| File.directory?(File.join(phases_dir, d)) }.sort
        match = dirs.find { |d| d.start_with?(normalized) }
        return nil unless match

        parse_phase_dir(phases_dir, match, normalized)
      rescue StandardError
        nil
      end

      def self.parse_phase_dir(phases_dir, match, _normalized) # rubocop:disable Metrics
        dir_match = match.match(/\A(\d+(?:\.\d+)?)-?(.*)/)
        phase_number = dir_match ? dir_match[1] : match
        phase_name = dir_match && !dir_match[2].empty? ? dir_match[2] : nil

        phase_dir = File.join(phases_dir, match)
        files = Dir.children(phase_dir)

        {
          directory: File.join(".ariadna_planning", "phases", match),
          phase_number: phase_number,
          phase_name: phase_name,
          phase_slug: generate_slug(phase_name),
          plans: files.select { |f| f.end_with?("-PLAN.md") || f == "PLAN.md" }.sort,
          summaries: files.select { |f| f.end_with?("-SUMMARY.md") || f == "SUMMARY.md" }.sort,
          has_research: files.any? { |f| f.end_with?("-RESEARCH.md") || f == "RESEARCH.md" },
          has_context: files.any? { |f| f.end_with?("-CONTEXT.md") || f == "CONTEXT.md" },
          has_verification: files.any? { |f| f.end_with?("-VERIFICATION.md") || f == "VERIFICATION.md" }
        }
      end

      def self.build_plan_metadata(cwd, phase_info)
        return [] unless phase_info

        phase_dir = File.join(cwd, phase_info[:directory])
        phase_info[:plans].map do |plan_file|
          fm = Frontmatter.extract(File.read(File.join(phase_dir, plan_file)))
          { file: plan_file, domain: fm["domain"] || "general", wave: fm["wave"] || "1" }
        end
      end

      def self.incomplete_plan_files(_cwd, phase_info)
        return [] unless phase_info

        completed_ids = (phase_info[:summaries] || []).map { |s| s.sub(/-SUMMARY\.md$/, "") }
        (phase_info[:plans] || []).reject { |p| completed_ids.include?(p.sub(/-PLAN\.md$/, "")) }
      end

      def self.resolve_model(cwd, agent_type)
        config = ConfigManager.load_config(cwd)
        profile = config["model_profile"] || "balanced"
        ModelProfiles.resolve_model(agent_type, profile)
      end

      def self.milestone_version(cwd)
        roadmap = File.read(File.join(cwd, ".ariadna_planning", "ROADMAP.md"))
        match = roadmap.match(/v(\d+\.\d+)/)
        match ? match[0] : "v1.0"
      rescue Errno::ENOENT
        "v1.0"
      end

      def self.normalize_phase(phase)
        match = phase.to_s.match(/\A(\d+(?:\.\d+)?)/)
        return phase.to_s unless match

        parts = match[1].split(".")
        padded = parts[0].rjust(2, "0")
        parts.length > 1 ? "#{padded}.#{parts[1]}" : padded
      end

      def self.generate_slug(text)
        return nil unless text

        text.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "")
      end

      def self.detect_brownfield(cwd)
        package_files = %w[package.json requirements.txt Cargo.toml go.mod Gemfile]
        return true if package_files.any? { |f| File.exist?(File.join(cwd, f)) }

        exts = %w[*.ts *.js *.py *.rb].map { |e| "-name \"#{e}\"" }.join(" -o ")
        cmd = "find #{cwd} -maxdepth 3 \\( #{exts} \\) 2>/dev/null"
        !`#{cmd} | grep -v node_modules | grep -v .git | head -3`.strip.empty?
      rescue StandardError
        false
      end

      def self.next_quick_number(cwd)
        quick_dir = File.join(cwd, ".ariadna_planning", "quick")
        return 1 unless File.directory?(quick_dir)

        existing = Dir.children(quick_dir).filter_map do |f|
          m = f.match(/\A(\d+)-/)
          m ? m[1].to_i : nil
        end
        existing.any? ? existing.max + 1 : 1
      end

      def self.collect_todos(cwd, area) # rubocop:disable Metrics
        pending_dir = File.join(cwd, ".ariadna_planning", "todos", "pending")
        return [] unless File.directory?(pending_dir)

        Dir[File.join(pending_dir, "*.md")].filter_map do |file|
          content = File.read(file)
          todo_area = content[/^area:\s*(.+)$/i, 1]&.strip || "general"
          next if area && todo_area != area

          {
            file: File.basename(file),
            title: content[/^title:\s*(.+)$/i, 1]&.strip || "Untitled",
            area: todo_area,
            path: File.join(".ariadna_planning", "todos", "pending", File.basename(file))
          }
        end
      end

      def self.scan_phases(cwd)
        phases_dir = File.join(cwd, ".ariadna_planning", "phases")
        return [] unless File.directory?(phases_dir)

        Dir.children(phases_dir)
           .select { |d| File.directory?(File.join(phases_dir, d)) }
           .sort
           .map { |dir| build_phase_entry(phases_dir, dir) }
      end

      def self.build_phase_entry(phases_dir, dir) # rubocop:disable Metrics
        m = dir.match(/\A(\d+(?:\.\d+)?)-?(.*)/)
        phase_number = m ? m[1] : dir
        files = Dir.children(File.join(phases_dir, dir))
        plans = files.select { |f| f.end_with?("-PLAN.md") || f == "PLAN.md" }
        summaries = files.select { |f| f.end_with?("-SUMMARY.md") || f == "SUMMARY.md" }

        status = if summaries.length >= plans.length && plans.any?
                   "complete"
                 elsif plans.any?
                   "in_progress"
                 else
                   "pending"
                 end

        { number: phase_number, directory: File.join(".ariadna_planning", "phases", dir), status: status }
      end

      private_class_method :base_result, :find_phase, :parse_phase_dir,
                           :build_plan_metadata, :incomplete_plan_files,
                           :resolve_model, :milestone_version, :normalize_phase,
                           :generate_slug, :detect_brownfield, :next_quick_number,
                           :collect_todos, :scan_phases, :build_phase_entry
    end
  end
end
