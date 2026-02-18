require "json"
require "fileutils"
require_relative "output"
require_relative "config_manager"
require_relative "model_profiles"
require_relative "frontmatter"

module Ariadna
  module Tools
    module Init
      def self.dispatch(argv, raw: false)
        workflow = argv.shift
        includes = parse_include_flag(argv)

        case workflow
        when "execute-phase"
          execute_phase(argv.first, includes, raw: raw)
        when "plan-phase"
          plan_phase(argv.first, includes, raw: raw)
        when "new-project"
          new_project(raw: raw)
        when "new-milestone"
          new_milestone(raw: raw)
        when "quick"
          quick(argv.join(" "), raw: raw)
        when "resume"
          resume(raw: raw)
        when "verify-work"
          verify_work(argv.first, raw: raw)
        when "phase-op"
          phase_op(argv.first, raw: raw)
        when "todos"
          todos(argv.first, raw: raw)
        when "milestone-op"
          milestone_op(raw: raw)
        when "map-codebase"
          map_codebase(raw: raw)
        when "progress"
          init_progress(includes, raw: raw)
        else
          Output.error("Unknown init workflow: #{workflow}\nAvailable: execute-phase, plan-phase, new-project, new-milestone, quick, resume, verify-work, phase-op, todos, milestone-op, map-codebase, progress")
        end
      end

      def self.execute_phase(phase, includes, raw: false)
        Output.error("phase required for init execute-phase") unless phase

        cwd = Dir.pwd
        config = ConfigManager.load_config(cwd)
        phase_info = find_phase_internal(cwd, phase)
        milestone = get_milestone_info(cwd)

        branch_name = if config["branching_strategy"] == "phase" && phase_info
                        config["phase_branch_template"]
                          .gsub("{phase}", phase_info[:phase_number])
                          .gsub("{slug}", phase_info[:phase_slug] || "phase")
                      elsif config["branching_strategy"] == "milestone"
                        config["milestone_branch_template"]
                          .gsub("{milestone}", milestone[:version])
                          .gsub("{slug}", generate_slug(milestone[:name]) || "milestone")
                      end

        result = {
          executor_model: resolve_model(cwd, "ariadna-executor"),
          verifier_model: resolve_model(cwd, "ariadna-verifier"),
          commit_docs: config["commit_docs"],
          parallelization: config["parallelization"],
          branching_strategy: config["branching_strategy"],
          phase_branch_template: config["phase_branch_template"],
          milestone_branch_template: config["milestone_branch_template"],
          verifier_enabled: config["verifier"],
          phase_found: !phase_info.nil?,
          phase_dir: phase_info&.dig(:directory),
          phase_number: phase_info&.dig(:phase_number),
          phase_name: phase_info&.dig(:phase_name),
          phase_slug: phase_info&.dig(:phase_slug),
          plans: phase_info&.dig(:plans) || [],
          summaries: phase_info&.dig(:summaries) || [],
          incomplete_plans: phase_info&.dig(:incomplete_plans) || [],
          plan_count: phase_info&.dig(:plans)&.length || 0,
          incomplete_count: phase_info&.dig(:incomplete_plans)&.length || 0,
          branch_name: branch_name,
          milestone_version: milestone[:version],
          milestone_name: milestone[:name],
          milestone_slug: generate_slug(milestone[:name]),
          team_execution: config["team_execution"],
          execution_mode: config["execution_mode"],
          backend_executor_model: resolve_model(cwd, "ariadna-backend-executor"),
          frontend_executor_model: resolve_model(cwd, "ariadna-frontend-executor"),
          test_executor_model: resolve_model(cwd, "ariadna-test-executor"),
          state_exists: path_exists?(cwd, ".planning/STATE.md"),
          roadmap_exists: path_exists?(cwd, ".planning/ROADMAP.md"),
          config_exists: path_exists?(cwd, ".planning/config.json")
        }

        result[:state_content] = safe_read_file(File.join(cwd, ".planning", "STATE.md")) if includes.include?("state")
        result[:config_content] = safe_read_file(File.join(cwd, ".planning", "config.json")) if includes.include?("config")
        result[:roadmap_content] = safe_read_file(File.join(cwd, ".planning", "ROADMAP.md")) if includes.include?("roadmap")

        Output.json(result, raw: raw)
      end

      def self.plan_phase(phase, includes, raw: false)
        Output.error("phase required for init plan-phase") unless phase

        cwd = Dir.pwd
        config = ConfigManager.load_config(cwd)
        phase_info = find_phase_internal(cwd, phase)

        result = {
          researcher_model: resolve_model(cwd, "ariadna-phase-researcher"),
          planner_model: resolve_model(cwd, "ariadna-planner"),
          checker_model: resolve_model(cwd, "ariadna-plan-checker"),
          research_enabled: config["research"],
          plan_checker_enabled: config["plan_checker"],
          commit_docs: config["commit_docs"],
          phase_found: !phase_info.nil?,
          phase_dir: phase_info&.dig(:directory),
          phase_number: phase_info&.dig(:phase_number),
          phase_name: phase_info&.dig(:phase_name),
          phase_slug: phase_info&.dig(:phase_slug),
          padded_phase: phase_info&.dig(:phase_number)&.rjust(2, "0"),
          has_research: phase_info&.dig(:has_research) || false,
          has_context: phase_info&.dig(:has_context) || false,
          has_plans: (phase_info&.dig(:plans)&.length || 0) > 0,
          plan_count: phase_info&.dig(:plans)&.length || 0,
          planning_exists: path_exists?(cwd, ".planning"),
          roadmap_exists: path_exists?(cwd, ".planning/ROADMAP.md")
        }

        result[:state_content] = safe_read_file(File.join(cwd, ".planning", "STATE.md")) if includes.include?("state")
        result[:roadmap_content] = safe_read_file(File.join(cwd, ".planning", "ROADMAP.md")) if includes.include?("roadmap")
        result[:requirements_content] = safe_read_file(File.join(cwd, ".planning", "REQUIREMENTS.md")) if includes.include?("requirements")

        if includes.include?("context") && phase_info&.dig(:directory)
          phase_dir_full = File.join(cwd, phase_info[:directory])
          context_file = Dir.children(phase_dir_full).find { |f| f.end_with?("-CONTEXT.md") || f == "CONTEXT.md" } rescue nil
          result[:context_content] = safe_read_file(File.join(phase_dir_full, context_file)) if context_file
        end

        if includes.include?("research") && phase_info&.dig(:directory)
          phase_dir_full = File.join(cwd, phase_info[:directory])
          research_file = Dir.children(phase_dir_full).find { |f| f.end_with?("-RESEARCH.md") || f == "RESEARCH.md" } rescue nil
          result[:research_content] = safe_read_file(File.join(phase_dir_full, research_file)) if research_file
        end

        if includes.include?("verification") && phase_info&.dig(:directory)
          phase_dir_full = File.join(cwd, phase_info[:directory])
          verification_file = Dir.children(phase_dir_full).find { |f| f.end_with?("-VERIFICATION.md") || f == "VERIFICATION.md" } rescue nil
          result[:verification_content] = safe_read_file(File.join(phase_dir_full, verification_file)) if verification_file
        end

        if includes.include?("uat") && phase_info&.dig(:directory)
          phase_dir_full = File.join(cwd, phase_info[:directory])
          uat_file = Dir.children(phase_dir_full).find { |f| f.end_with?("-UAT.md") || f == "UAT.md" } rescue nil
          result[:uat_content] = safe_read_file(File.join(phase_dir_full, uat_file)) if uat_file
        end

        Output.json(result, raw: raw)
      end

      def self.new_project(raw: false)
        cwd = Dir.pwd
        config = ConfigManager.load_config(cwd)

        # Detect existing code
        has_code = false
        begin
          files = `find #{cwd} -maxdepth 3 \\( -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.go" -o -name "*.rs" -o -name "*.swift" -o -name "*.java" -o -name "*.rb" \\) 2>/dev/null | grep -v node_modules | grep -v .git | head -5`
          has_code = !files.strip.empty?
        rescue StandardError
          # ignore
        end

        has_package_file = %w[package.json requirements.txt Cargo.toml go.mod Package.swift Gemfile].any? do |f|
          File.exist?(File.join(cwd, f))
        end

        result = {
          researcher_model: resolve_model(cwd, "ariadna-project-researcher"),
          synthesizer_model: resolve_model(cwd, "ariadna-research-synthesizer"),
          roadmapper_model: resolve_model(cwd, "ariadna-roadmapper"),
          commit_docs: config["commit_docs"],
          project_exists: path_exists?(cwd, ".planning/PROJECT.md"),
          has_codebase_map: path_exists?(cwd, ".planning/codebase"),
          planning_exists: path_exists?(cwd, ".planning"),
          has_existing_code: has_code,
          has_package_file: has_package_file,
          is_brownfield: has_code || has_package_file,
          needs_codebase_map: (has_code || has_package_file) && !path_exists?(cwd, ".planning/codebase"),
          has_git: path_exists?(cwd, ".git")
        }

        Output.json(result, raw: raw)
      end

      def self.new_milestone(raw: false)
        cwd = Dir.pwd
        config = ConfigManager.load_config(cwd)
        milestone = get_milestone_info(cwd)

        result = {
          researcher_model: resolve_model(cwd, "ariadna-project-researcher"),
          synthesizer_model: resolve_model(cwd, "ariadna-research-synthesizer"),
          roadmapper_model: resolve_model(cwd, "ariadna-roadmapper"),
          commit_docs: config["commit_docs"],
          research_enabled: config["research"],
          current_milestone: milestone[:version],
          current_milestone_name: milestone[:name],
          project_exists: path_exists?(cwd, ".planning/PROJECT.md"),
          roadmap_exists: path_exists?(cwd, ".planning/ROADMAP.md"),
          state_exists: path_exists?(cwd, ".planning/STATE.md")
        }

        Output.json(result, raw: raw)
      end

      def self.quick(description, raw: false)
        cwd = Dir.pwd
        config = ConfigManager.load_config(cwd)
        now = Time.now.utc
        slug = description && !description.empty? ? generate_slug(description)&.slice(0, 40) : nil

        quick_dir = File.join(cwd, ".planning", "quick")
        next_num = 1
        if File.directory?(quick_dir)
          existing = Dir.children(quick_dir)
                        .filter_map { |f| m = f.match(/\A(\d+)-/); m ? m[1].to_i : nil }
          next_num = existing.max + 1 if existing.any?
        end

        result = {
          planner_model: resolve_model(cwd, "ariadna-planner"),
          executor_model: resolve_model(cwd, "ariadna-executor"),
          commit_docs: config["commit_docs"],
          next_num: next_num,
          slug: slug,
          description: description && !description.empty? ? description : nil,
          date: now.strftime("%Y-%m-%d"),
          timestamp: now.iso8601,
          quick_dir: ".planning/quick",
          task_dir: slug ? ".planning/quick/#{next_num}-#{slug}" : nil,
          roadmap_exists: path_exists?(cwd, ".planning/ROADMAP.md"),
          planning_exists: path_exists?(cwd, ".planning")
        }

        Output.json(result, raw: raw)
      end

      def self.resume(raw: false)
        cwd = Dir.pwd
        config = ConfigManager.load_config(cwd)

        interrupted_agent_id = nil
        agent_file = File.join(cwd, ".planning", "current-agent-id.txt")
        interrupted_agent_id = File.read(agent_file).strip if File.exist?(agent_file)

        result = {
          state_exists: path_exists?(cwd, ".planning/STATE.md"),
          roadmap_exists: path_exists?(cwd, ".planning/ROADMAP.md"),
          project_exists: path_exists?(cwd, ".planning/PROJECT.md"),
          planning_exists: path_exists?(cwd, ".planning"),
          has_interrupted_agent: !interrupted_agent_id.nil?,
          interrupted_agent_id: interrupted_agent_id,
          commit_docs: config["commit_docs"]
        }

        Output.json(result, raw: raw)
      end

      def self.verify_work(phase, raw: false)
        Output.error("phase required for init verify-work") unless phase

        cwd = Dir.pwd
        config = ConfigManager.load_config(cwd)
        phase_info = find_phase_internal(cwd, phase)

        result = {
          planner_model: resolve_model(cwd, "ariadna-planner"),
          checker_model: resolve_model(cwd, "ariadna-plan-checker"),
          commit_docs: config["commit_docs"],
          phase_found: !phase_info.nil?,
          phase_dir: phase_info&.dig(:directory),
          phase_number: phase_info&.dig(:phase_number),
          phase_name: phase_info&.dig(:phase_name),
          has_verification: phase_info&.dig(:has_verification) || false
        }

        Output.json(result, raw: raw)
      end

      def self.phase_op(phase, raw: false)
        cwd = Dir.pwd
        config = ConfigManager.load_config(cwd)
        phase_info = find_phase_internal(cwd, phase)

        result = {
          commit_docs: config["commit_docs"],
          phase_found: !phase_info.nil?,
          phase_dir: phase_info&.dig(:directory),
          phase_number: phase_info&.dig(:phase_number),
          phase_name: phase_info&.dig(:phase_name),
          phase_slug: phase_info&.dig(:phase_slug),
          padded_phase: phase_info&.dig(:phase_number)&.rjust(2, "0"),
          has_research: phase_info&.dig(:has_research) || false,
          has_context: phase_info&.dig(:has_context) || false,
          has_plans: (phase_info&.dig(:plans)&.length || 0) > 0,
          has_verification: phase_info&.dig(:has_verification) || false,
          plan_count: phase_info&.dig(:plans)&.length || 0,
          roadmap_exists: path_exists?(cwd, ".planning/ROADMAP.md"),
          planning_exists: path_exists?(cwd, ".planning")
        }

        Output.json(result, raw: raw)
      end

      def self.todos(area, raw: false)
        cwd = Dir.pwd
        config = ConfigManager.load_config(cwd)
        now = Time.now.utc

        pending_dir = File.join(cwd, ".planning", "todos", "pending")
        count = 0
        todo_list = []

        if File.directory?(pending_dir)
          Dir[File.join(pending_dir, "*.md")].each do |file|
            content = File.read(file)
            created = content[/^created:\s*(.+)$/i, 1]&.strip || "unknown"
            title = content[/^title:\s*(.+)$/i, 1]&.strip || "Untitled"
            todo_area = content[/^area:\s*(.+)$/i, 1]&.strip || "general"

            next if area && todo_area != area

            count += 1
            todo_list << {
              file: File.basename(file), created: created, title: title, area: todo_area,
              path: File.join(".planning", "todos", "pending", File.basename(file))
            }
          end
        end

        result = {
          commit_docs: config["commit_docs"],
          date: now.strftime("%Y-%m-%d"),
          timestamp: now.iso8601,
          todo_count: count,
          todos: todo_list,
          area_filter: area,
          pending_dir: ".planning/todos/pending",
          completed_dir: ".planning/todos/completed",
          planning_exists: path_exists?(cwd, ".planning"),
          todos_dir_exists: path_exists?(cwd, ".planning/todos"),
          pending_dir_exists: path_exists?(cwd, ".planning/todos/pending")
        }

        Output.json(result, raw: raw)
      end

      def self.milestone_op(raw: false)
        cwd = Dir.pwd
        config = ConfigManager.load_config(cwd)
        milestone = get_milestone_info(cwd)

        phases_dir = File.join(cwd, ".planning", "phases")
        phase_count = 0
        completed_phases = 0

        if File.directory?(phases_dir)
          dirs = Dir.children(phases_dir).select { |d| File.directory?(File.join(phases_dir, d)) }
          phase_count = dirs.length
          dirs.each do |dir|
            phase_files = Dir.children(File.join(phases_dir, dir))
            completed_phases += 1 if phase_files.any? { |f| f.end_with?("-SUMMARY.md") || f == "SUMMARY.md" }
          end
        end

        archive_dir = File.join(cwd, ".planning", "archive")
        archived_milestones = []
        if File.directory?(archive_dir)
          archived_milestones = Dir.children(archive_dir).select { |e| File.directory?(File.join(archive_dir, e)) }
        end

        result = {
          commit_docs: config["commit_docs"],
          milestone_version: milestone[:version],
          milestone_name: milestone[:name],
          milestone_slug: generate_slug(milestone[:name]),
          phase_count: phase_count,
          completed_phases: completed_phases,
          all_phases_complete: phase_count > 0 && phase_count == completed_phases,
          archived_milestones: archived_milestones,
          archive_count: archived_milestones.length,
          project_exists: path_exists?(cwd, ".planning/PROJECT.md"),
          roadmap_exists: path_exists?(cwd, ".planning/ROADMAP.md"),
          state_exists: path_exists?(cwd, ".planning/STATE.md"),
          archive_exists: path_exists?(cwd, ".planning/archive"),
          phases_dir_exists: path_exists?(cwd, ".planning/phases")
        }

        Output.json(result, raw: raw)
      end

      def self.map_codebase(raw: false)
        cwd = Dir.pwd
        config = ConfigManager.load_config(cwd)

        codebase_dir = File.join(cwd, ".planning", "codebase")
        existing_maps = []
        existing_maps = Dir.children(codebase_dir).select { |f| f.end_with?(".md") } if File.directory?(codebase_dir)

        result = {
          mapper_model: resolve_model(cwd, "ariadna-codebase-mapper"),
          commit_docs: config["commit_docs"],
          search_gitignored: config["search_gitignored"],
          parallelization: config["parallelization"],
          codebase_dir: ".planning/codebase",
          existing_maps: existing_maps,
          has_maps: existing_maps.any?,
          planning_exists: path_exists?(cwd, ".planning"),
          codebase_dir_exists: path_exists?(cwd, ".planning/codebase")
        }

        Output.json(result, raw: raw)
      end

      def self.init_progress(includes, raw: false)
        cwd = Dir.pwd
        config = ConfigManager.load_config(cwd)
        milestone = get_milestone_info(cwd)

        phases_dir = File.join(cwd, ".planning", "phases")
        phases = []
        current_phase = nil
        next_phase = nil

        if File.directory?(phases_dir)
          dirs = Dir.children(phases_dir)
                    .select { |d| File.directory?(File.join(phases_dir, d)) }
                    .sort

          dirs.each do |dir|
            m = dir.match(/\A(\d+(?:\.\d+)?)-?(.*)/)
            phase_number = m ? m[1] : dir
            phase_name = m && !m[2].empty? ? m[2] : nil

            phase_path = File.join(phases_dir, dir)
            phase_files = Dir.children(phase_path)

            plans = phase_files.select { |f| f.end_with?("-PLAN.md") || f == "PLAN.md" }
            summaries = phase_files.select { |f| f.end_with?("-SUMMARY.md") || f == "SUMMARY.md" }
            has_research = phase_files.any? { |f| f.end_with?("-RESEARCH.md") || f == "RESEARCH.md" }

            status = if summaries.length >= plans.length && plans.any?
                       "complete"
                     elsif plans.any?
                       "in_progress"
                     elsif has_research
                       "researched"
                     else
                       "pending"
                     end

            phase_entry = {
              number: phase_number, name: phase_name,
              directory: File.join(".planning", "phases", dir),
              status: status, plan_count: plans.length,
              summary_count: summaries.length, has_research: has_research
            }

            phases << phase_entry
            current_phase ||= phase_entry if status == "in_progress" || status == "researched"
            next_phase ||= phase_entry if status == "pending"
          end
        end

        paused_at = nil
        state_path = File.join(cwd, ".planning", "STATE.md")
        if File.exist?(state_path)
          state_content = File.read(state_path)
          pause_match = state_content.match(/\*\*Paused At:\*\*\s*(.+)/)
          paused_at = pause_match[1].strip if pause_match
        end

        result = {
          executor_model: resolve_model(cwd, "ariadna-executor"),
          planner_model: resolve_model(cwd, "ariadna-planner"),
          commit_docs: config["commit_docs"],
          milestone_version: milestone[:version],
          milestone_name: milestone[:name],
          phases: phases,
          phase_count: phases.length,
          completed_count: phases.count { |p| p[:status] == "complete" },
          in_progress_count: phases.count { |p| p[:status] == "in_progress" },
          current_phase: current_phase,
          next_phase: next_phase,
          paused_at: paused_at,
          has_work_in_progress: !current_phase.nil?,
          project_exists: path_exists?(cwd, ".planning/PROJECT.md"),
          roadmap_exists: path_exists?(cwd, ".planning/ROADMAP.md"),
          state_exists: path_exists?(cwd, ".planning/STATE.md")
        }

        result[:state_content] = safe_read_file(File.join(cwd, ".planning", "STATE.md")) if includes.include?("state")
        result[:roadmap_content] = safe_read_file(File.join(cwd, ".planning", "ROADMAP.md")) if includes.include?("roadmap")
        result[:project_content] = safe_read_file(File.join(cwd, ".planning", "PROJECT.md")) if includes.include?("project")
        result[:config_content] = safe_read_file(File.join(cwd, ".planning", "config.json")) if includes.include?("config")

        Output.json(result, raw: raw)
      end

      # --- Private helpers ---

      def self.find_phase_internal(cwd, phase)
        return nil unless phase

        phases_dir = File.join(cwd, ".planning", "phases")
        normalized = normalize_phase(phase)

        return nil unless File.directory?(phases_dir)

        dirs = Dir.children(phases_dir).select { |d| File.directory?(File.join(phases_dir, d)) }.sort
        match = dirs.find { |d| d.start_with?(normalized) }
        return nil unless match

        dir_match = match.match(/\A(\d+(?:\.\d+)?)-?(.*)/)
        phase_number = dir_match ? dir_match[1] : normalized
        phase_name = dir_match && !dir_match[2].empty? ? dir_match[2] : nil
        phase_slug = phase_name ? phase_name.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "") : nil

        phase_dir = File.join(phases_dir, match)
        phase_files = Dir.children(phase_dir)

        plans = phase_files.select { |f| f.end_with?("-PLAN.md") || f == "PLAN.md" }.sort
        summaries = phase_files.select { |f| f.end_with?("-SUMMARY.md") || f == "SUMMARY.md" }.sort
        has_research = phase_files.any? { |f| f.end_with?("-RESEARCH.md") || f == "RESEARCH.md" }
        has_context = phase_files.any? { |f| f.end_with?("-CONTEXT.md") || f == "CONTEXT.md" }
        has_verification = phase_files.any? { |f| f.end_with?("-VERIFICATION.md") || f == "VERIFICATION.md" }

        completed_plan_ids = summaries.map { |s| s.sub(/-SUMMARY\.md$/, "").sub(/\ASUMMARY\.md$/, "") }
        incomplete_plans = plans.reject do |p|
          plan_id = p.sub(/-PLAN\.md$/, "").sub(/\APLAN\.md$/, "")
          completed_plan_ids.include?(plan_id)
        end

        {
          directory: File.join(".planning", "phases", match),
          phase_number: phase_number,
          phase_name: phase_name,
          phase_slug: phase_slug,
          plans: plans,
          summaries: summaries,
          incomplete_plans: incomplete_plans,
          has_research: has_research,
          has_context: has_context,
          has_verification: has_verification
        }
      rescue StandardError
        nil
      end

      def self.get_milestone_info(cwd)
        roadmap = File.read(File.join(cwd, ".planning", "ROADMAP.md"))
        version_match = roadmap.match(/v(\d+\.\d+)/)
        name_match = roadmap.match(/## .*v\d+\.\d+[:\s]+([^\n(]+)/)
        {
          version: version_match ? version_match[0] : "v1.0",
          name: name_match ? name_match[1].strip : "milestone"
        }
      rescue Errno::ENOENT
        { version: "v1.0", name: "milestone" }
      end

      def self.resolve_model(cwd, agent_type)
        config = ConfigManager.load_config(cwd)
        profile = config["model_profile"] || "balanced"
        ModelProfiles.resolve_model(agent_type, profile)
      end

      def self.path_exists?(cwd, relative_path)
        File.exist?(File.join(cwd, relative_path))
      end

      def self.safe_read_file(path)
        File.read(path)
      rescue StandardError
        nil
      end

      def self.generate_slug(text)
        return nil unless text

        text.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "")
      end

      def self.normalize_phase(phase)
        match = phase.to_s.match(/\A(\d+(?:\.\d+)?)/)
        return phase.to_s unless match

        parts = match[1].split(".")
        padded = parts[0].rjust(2, "0")
        parts.length > 1 ? "#{padded}.#{parts[1]}" : padded
      end

      def self.parse_include_flag(argv)
        idx = argv.index("--include")
        return [] unless idx

        value = argv[idx + 1]
        return [] unless value

        value.split(",").map(&:strip)
      end

      private_class_method :find_phase_internal, :get_milestone_info, :resolve_model,
                           :path_exists?, :safe_read_file, :generate_slug,
                           :normalize_phase, :parse_include_flag
    end
  end
end
