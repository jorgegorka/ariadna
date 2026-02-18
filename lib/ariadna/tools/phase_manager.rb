require "json"
require "fileutils"
require_relative "output"
require_relative "frontmatter"

module Ariadna
  module Tools
    module PhaseManager
      def self.dispatch(argv, raw: false)
        subcommand = argv.shift
        case subcommand
        when "next-decimal"
          next_decimal(argv.first, raw: raw)
        when "add"
          add(argv.join(" "), raw: raw)
        when "insert"
          after = argv.shift
          insert(after, argv.join(" "), raw: raw)
        when "remove"
          force = argv.delete("--force")
          remove(argv.first, force: !!force, raw: raw)
        when "complete"
          complete(argv.first, raw: raw)
        else
          Output.error("Unknown phase subcommand. Available: next-decimal, add, insert, remove, complete")
        end
      end

      def self.phases_dispatch(argv, raw: false)
        subcommand = argv.shift
        case subcommand
        when "list"
          type_idx = argv.index("--type")
          phase_idx = argv.index("--phase")
          options = {
            type: type_idx ? argv[type_idx + 1] : nil,
            phase: phase_idx ? argv[phase_idx + 1] : nil
          }
          list(options, raw: raw)
        else
          Output.error("Unknown phases subcommand. Available: list")
        end
      end

      def self.milestone_dispatch(argv, raw: false)
        subcommand = argv.shift
        case subcommand
        when "complete"
          version = argv.shift
          name_idx = argv.index("--name")
          name = name_idx ? argv[(name_idx + 1)..].join(" ") : nil
          milestone_complete(version, name: name, raw: raw)
        else
          Output.error("Unknown milestone subcommand. Available: complete")
        end
      end

      def self.find(argv, raw: false)
        phase = argv.first
        Output.error("phase identifier required") unless phase

        cwd = Dir.pwd
        phases_dir = File.join(cwd, ".planning", "phases")
        normalized = normalize_phase_name(phase)
        not_found = { found: false, directory: nil, phase_number: nil, phase_name: nil, plans: [], summaries: [] }

        unless File.directory?(phases_dir)
          Output.json(not_found, raw: raw, raw_value: "")
          return
        end

        dirs = Dir.children(phases_dir).select { |d| File.directory?(File.join(phases_dir, d)) }.sort
        match = dirs.find { |d| d.start_with?(normalized) }

        unless match
          Output.json(not_found, raw: raw, raw_value: "")
          return
        end

        dir_match = match.match(/\A(\d+(?:\.\d+)?)-?(.*)/)
        phase_number = dir_match ? dir_match[1] : normalized
        phase_name = dir_match && !dir_match[2].empty? ? dir_match[2] : nil

        phase_dir = File.join(phases_dir, match)
        phase_files = Dir.children(phase_dir).sort
        plans = phase_files.select { |f| f.end_with?("-PLAN.md") || f == "PLAN.md" }
        summaries = phase_files.select { |f| f.end_with?("-SUMMARY.md") || f == "SUMMARY.md" }

        result = {
          found: true,
          directory: File.join(".planning", "phases", match),
          phase_number: phase_number,
          phase_name: phase_name,
          plans: plans,
          summaries: summaries
        }
        Output.json(result, raw: raw, raw_value: result[:directory])
      rescue StandardError
        Output.json(not_found, raw: raw, raw_value: "")
      end

      def self.plan_index(argv, raw: false)
        phase = argv.first
        Output.error("phase required") unless phase

        cwd = Dir.pwd
        phases_dir = File.join(cwd, ".planning", "phases")
        normalized = normalize_phase_name(phase)

        unless File.directory?(phases_dir)
          Output.json({ plans: [], count: 0 }, raw: raw, raw_value: "")
          return
        end

        dirs = Dir.children(phases_dir).select { |d| File.directory?(File.join(phases_dir, d)) }.sort
        match = dirs.find { |d| d.start_with?(normalized) }

        unless match
          Output.json({ plans: [], count: 0 }, raw: raw, raw_value: "")
          return
        end

        dir_path = File.join(phases_dir, match)
        plan_files = Dir.children(dir_path).select { |f| f.match?(/-PLAN\.md$/i) }.sort

        plans = plan_files.map do |f|
          content = File.read(File.join(dir_path, f))
          fm = Frontmatter.extract(content)
          summary_name = f.sub(/-PLAN\.md$/i, "-SUMMARY.md")
          has_summary = File.exist?(File.join(dir_path, summary_name))
          {
            file: f, phase: fm["phase"], plan: fm["plan"], wave: fm["wave"],
            type: fm["type"], completed: has_summary,
            domain: fm["domain"] || "general",
            depends_on: fm["depends_on"] || [],
            files_modified: fm["files_modified"] || [],
            autonomous: fm.key?("autonomous") ? fm["autonomous"] : true,
            objective: fm["objective"],
            task_count: content.scan(/<task\b/).count
          }
        end

        domains = plans.map { |p| p[:domain] }.uniq
        non_general = domains.reject { |d| d == "general" }

        Output.json({
                      plans: plans, count: plans.size,
                      domains: domains,
                      domain_count: non_general.size,
                      multi_domain: non_general.size >= 2,
                      recommend_team: plans.size >= 3 && non_general.size >= 2
                    }, raw: raw)
      end

      def self.list(options, raw: false)
        cwd = Dir.pwd
        phases_dir = File.join(cwd, ".planning", "phases")

        unless File.directory?(phases_dir)
          key = options[:type] ? :files : :directories
          Output.json({ key => [], count: 0 }, raw: raw, raw_value: "")
          return
        end

        dirs = Dir.children(phases_dir)
                  .select { |d| File.directory?(File.join(phases_dir, d)) }
                  .sort_by { |d| d.match(/\A(\d+(?:\.\d+)?)/)&.[](1)&.to_f || 0 }

        if options[:phase]
          normalized = normalize_phase_name(options[:phase])
          match = dirs.find { |d| d.start_with?(normalized) }
          dirs = match ? [match] : []
        end

        if options[:type]
          files = []
          dirs.each do |dir|
            dir_files = Dir.children(File.join(phases_dir, dir))
            filtered = case options[:type]
                       when "plans" then dir_files.select { |f| f.end_with?("-PLAN.md") || f == "PLAN.md" }
                       when "summaries" then dir_files.select { |f| f.end_with?("-SUMMARY.md") || f == "SUMMARY.md" }
                       else dir_files
                       end
            files.concat(filtered.sort)
          end
          Output.json({ files: files, count: files.size }, raw: raw, raw_value: files.join("\n"))
        else
          Output.json({ directories: dirs, count: dirs.size }, raw: raw, raw_value: dirs.join("\n"))
        end
      end

      def self.next_decimal(base_phase, raw: false)
        Output.error("base phase required") unless base_phase
        cwd = Dir.pwd
        phases_dir = File.join(cwd, ".planning", "phases")
        normalized = normalize_phase_name(base_phase)

        unless File.directory?(phases_dir)
          Output.json({ found: false, base_phase: normalized, next: "#{normalized}.1", existing: [] },
                      raw: raw, raw_value: "#{normalized}.1")
          return
        end

        dirs = Dir.children(phases_dir).select { |d| File.directory?(File.join(phases_dir, d)) }
        base_exists = dirs.any? { |d| d.start_with?("#{normalized}-") || d == normalized }

        decimal_pattern = /\A#{Regexp.escape(normalized)}\.(\d+)/
        existing = dirs.filter_map { |d| m = d.match(decimal_pattern); "#{normalized}.#{m[1]}" if m }
                       .sort_by { |d| d.to_f }

        next_val = if existing.empty?
                     "#{normalized}.1"
                   else
                     last_num = existing.last.split(".")[1].to_i
                     "#{normalized}.#{last_num + 1}"
                   end

        Output.json({ found: base_exists, base_phase: normalized, next: next_val, existing: existing },
                    raw: raw, raw_value: next_val)
      end

      def self.add(description, raw: false)
        Output.error("description required") unless description && !description.empty?
        cwd = Dir.pwd
        phases_dir = File.join(cwd, ".planning", "phases")
        roadmap_path = File.join(cwd, ".planning", "ROADMAP.md")

        existing = if File.directory?(phases_dir)
                     Dir.children(phases_dir)
                        .select { |d| File.directory?(File.join(phases_dir, d)) }
                        .filter_map { |d| d.match(/\A(\d+)/); ::Regexp.last_match(1)&.to_i }
                        .max || 0
                   else
                     0
                   end

        new_num = format("%02d", existing + 1)
        slug = description.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "")
        dir_name = "#{new_num}-#{slug}"
        FileUtils.mkdir_p(File.join(phases_dir, dir_name))

        # Append to ROADMAP.md if it exists
        if File.exist?(roadmap_path)
          roadmap = File.read(roadmap_path)
          roadmap += "\n### Phase #{new_num.to_i}: #{description}\n\n**Goal:** TBD\n"
          File.write(roadmap_path, roadmap)
        end

        Output.json({ added: true, phase: new_num, directory: dir_name }, raw: raw, raw_value: new_num)
      end

      def self.insert(after, description, raw: false)
        Output.error("after phase and description required") unless after && description && !description.empty?
        cwd = Dir.pwd
        phases_dir = File.join(cwd, ".planning", "phases")
        normalized = normalize_phase_name(after)

        # Calculate next decimal
        unless File.directory?(phases_dir)
          Output.json({ inserted: false, reason: "phases directory not found" }, raw: raw, raw_value: "false")
          return
        end

        dirs = Dir.children(phases_dir).select { |d| File.directory?(File.join(phases_dir, d)) }
        decimal_pattern = /\A#{Regexp.escape(normalized)}\.(\d+)/
        existing = dirs.filter_map { |d| m = d.match(decimal_pattern); m[1].to_i if m }
        next_num = existing.empty? ? 1 : existing.max + 1
        new_phase = "#{normalized}.#{next_num}"

        slug = description.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "")
        dir_name = "#{new_phase}-#{slug}"
        FileUtils.mkdir_p(File.join(phases_dir, dir_name))

        Output.json({ inserted: true, phase: new_phase, directory: dir_name }, raw: raw, raw_value: new_phase)
      end

      def self.remove(phase, force: false, raw: false)
        Output.error("phase required") unless phase
        cwd = Dir.pwd
        phases_dir = File.join(cwd, ".planning", "phases")
        normalized = normalize_phase_name(phase)

        unless File.directory?(phases_dir)
          Output.json({ removed: false, reason: "phases directory not found" }, raw: raw, raw_value: "false")
          return
        end

        dirs = Dir.children(phases_dir).select { |d| File.directory?(File.join(phases_dir, d)) }.sort
        match = dirs.find { |d| d.start_with?(normalized) }

        unless match
          Output.json({ removed: false, reason: "phase not found" }, raw: raw, raw_value: "false")
          return
        end

        dir_path = File.join(phases_dir, match)
        has_content = Dir.children(dir_path).any? { |f| f.end_with?(".md") }

        if has_content && !force
          Output.json({ removed: false, reason: "phase has content, use --force" }, raw: raw, raw_value: "false")
          return
        end

        FileUtils.rm_rf(dir_path)
        Output.json({ removed: true, phase: normalized, directory: match }, raw: raw, raw_value: "true")
      end

      def self.complete(phase, raw: false)
        Output.error("phase required") unless phase
        cwd = Dir.pwd
        roadmap_path = File.join(cwd, ".planning", "ROADMAP.md")
        normalized = normalize_phase_name(phase)

        # Mark in ROADMAP.md
        if File.exist?(roadmap_path)
          content = File.read(roadmap_path)
          escaped = Regexp.escape(normalized.to_i.to_s)
          content = content.sub(/(###\s*Phase\s+#{escaped}:)/, "\\1 ✅")
          File.write(roadmap_path, content)
        end

        Output.json({ completed: true, phase: normalized }, raw: raw, raw_value: "true")
      end

      def self.milestone_complete(version, name: nil, raw: false)
        Output.error("version required") unless version
        cwd = Dir.pwd

        # Create milestone archive
        archive_dir = File.join(cwd, ".planning", "milestones")
        FileUtils.mkdir_p(archive_dir)

        milestone_name = name || "v#{version}"
        archive_path = File.join(archive_dir, "#{milestone_name}.md")

        content = "# Milestone: #{milestone_name}\n\nCompleted: #{Time.now.utc.strftime('%Y-%m-%d')}\nVersion: #{version}\n"
        File.write(archive_path, content)

        Output.json({ archived: true, version: version, name: milestone_name, path: archive_path }, raw: raw, raw_value: "true")
      end

      def self.normalize_phase_name(phase)
        match = phase.match(/\A(\d+(?:\.\d+)?)/)
        return phase unless match

        num = match[1]
        parts = num.split(".")
        padded = parts[0].rjust(2, "0")
        parts.length > 1 ? "#{padded}.#{parts[1]}" : padded
      end

      private_class_method :normalize_phase_name
    end
  end
end
