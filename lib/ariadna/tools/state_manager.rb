require "json"
require_relative "output"
require_relative "frontmatter"

module Ariadna
  module Tools
    # Memory-directory-based state management using Memory Tool verbs.
    module StateManager # rubocop:disable Metrics/ModuleLength
      MEMORY_DIR = ".ariadna_planning/memory".freeze

      def self.dispatch(args, raw: false) # rubocop:disable Metrics/CyclomaticComplexity
        subcommand = args.shift
        case subcommand
        when "list" then list_memory(args, raw: raw)
        when "view" then view(args, raw: raw)
        when "create" then create(args, raw: raw)
        when "update" then update(args, raw: raw)
        when "insert" then insert(args, raw: raw)
        when "delete" then delete_file(args, raw: raw)
        when "add-decision" then add_decision(args, raw: raw)
        when "add-blocker" then add_blocker(args, raw: raw)
        when "resolve-blocker" then resolve_blocker(args, raw: raw)
        when "record-metric" then record_metric(args, raw: raw)
        when "record-session" then record_session(args, raw: raw)
        when "history-digest" then history_digest(args, raw: raw)
        else Output.error("Unknown state subcommand: #{subcommand}")
        end
      end

      def self.list_memory(_args, raw: false)
        dir = memory_path
        FileUtils.mkdir_p(dir)
        files = Dir.children(dir).sort.map do |name|
          { name: name, size: File.stat(File.join(dir, name)).size }
        end
        Output.json({ files: files }, raw: raw)
      end

      def self.view(args, raw: false)
        filename = args.shift
        Output.error("filename required") unless filename
        path = safe_path!(filename)
        Output.error("File not found: #{filename}") unless File.exist?(path)
        content = File.read(path)
        Output.json({ file: filename, content: content, lines: content.lines.count }, raw: raw)
      end

      def self.create(args, raw: false)
        filename = args.shift
        content = args.shift || ""
        Output.error("filename required") unless filename
        path = safe_path!(filename)
        Output.error("File already exists: #{filename}") if File.exist?(path)
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, content)
        Output.json({ created: true, file: filename }, raw: raw)
      end

      def self.update(args, raw: false)
        filename, old_str, new_str = args.shift(3)
        Output.error("filename, old_str, and new_str required") unless filename && old_str && new_str
        path = safe_path!(filename)
        Output.error("File not found: #{filename}") unless File.exist?(path)
        content = File.read(path)
        count = content.scan(old_str).length
        Output.error("old_str not found in #{filename}") if count.zero?
        Output.error("old_str is ambiguous (#{count} occurrences) in #{filename}") if count > 1
        File.write(path, content.sub(old_str, new_str))
        Output.json({ updated: true, file: filename }, raw: raw)
      end

      def self.insert(args, raw: false)
        filename = args.shift
        line_num = args.shift&.to_i
        text = args.shift
        Output.error("filename, line_number, and text required") unless filename && line_num && text
        path = safe_path!(filename)
        Output.error("File not found: #{filename}") unless File.exist?(path)
        lines = File.readlines(path)
        lines.insert([line_num - 1, 0].max, "#{text}\n")
        File.write(path, lines.join)
        Output.json({ inserted: true, file: filename, at_line: line_num }, raw: raw)
      end

      def self.delete_file(args, raw: false)
        filename = args.shift
        Output.error("filename required") unless filename
        path = safe_path!(filename)
        Output.error("File not found: #{filename}") unless File.exist?(path)
        File.delete(path)
        Output.json({ deleted: true, file: filename }, raw: raw)
      end

      def self.add_decision(args, raw: false)
        opts = parse_named_args(args, %w[phase summary rationale])
        summary = opts["summary"]
        Output.error("--summary required") unless summary
        phase = opts["phase"] || "?"
        suffix = opts["rationale"] ? " -- #{opts['rationale']}" : ""
        entry = "- [Phase #{phase}]: #{summary}#{suffix}"
        append_to_memory_file("decisions.md", "# Decisions", entry)
        Output.json({ added: true, decision: entry }, raw: raw)
      end

      def self.add_blocker(args, raw: false)
        text = extract_flag(args, "--text") || args.first
        Output.error("--text required") unless text
        append_to_memory_file("blockers.md", "# Blockers", "- #{text}")
        Output.json({ added: true, blocker: text }, raw: raw)
      end

      def self.resolve_blocker(args, raw: false)
        text = extract_flag(args, "--text") || args.first
        Output.error("--text required") unless text
        path = File.join(memory_path, "blockers.md")
        Output.error("blockers.md not found") unless File.exist?(path)
        lines = File.read(path).split("\n")
        filtered = lines.reject { |l| l.start_with?("- ") && l.downcase.include?(text.downcase) }
        File.write(path, "#{filtered.join("\n")}\n")
        Output.json({ resolved: true, blocker: text }, raw: raw)
      end

      def self.record_metric(args, raw: false)
        opts = parse_named_args(args, %w[phase plan duration tasks files])
        phase, plan, duration = opts.values_at("phase", "plan", "duration")
        Output.error("--phase, --plan, and --duration required") unless phase && plan && duration
        tasks = opts["tasks"] || "-"
        files = opts["files"] || "-"
        entry = "| Phase #{phase} P#{plan} | #{duration} | #{tasks} tasks | #{files} files |"
        append_to_memory_file("metrics.md", "# Metrics", entry)
        Output.json({ recorded: true, phase: phase, plan: plan, duration: duration }, raw: raw)
      end

      def self.record_session(args, raw: false)
        opts = parse_named_args(args, %w[stopped-at resume-file])
        now = Time.now.utc.iso8601
        lines = ["# Session", "", "**Last session:** #{now}"]
        lines << "**Stopped at:** #{opts['stopped-at']}" if opts["stopped-at"]
        lines << "**Resume file:** #{opts['resume-file']}" if opts["resume-file"]
        path = File.join(memory_path, "session.md")
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, "#{lines.join("\n")}\n")
        Output.json({ recorded: true, timestamp: now }, raw: raw)
      end

      def self.history_digest(_args, raw: false)
        phases_dir = File.join(Dir.pwd, ".ariadna_planning", "phases")
        lines = ["# History Digest", ""]
        collect_phase_summaries(phases_dir, lines) if File.directory?(phases_dir)
        path = File.join(memory_path, "history.md")
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, "#{lines.join("\n")}\n")
        Output.json({ created: true, file: "history.md" }, raw: raw)
      end

      # --- Private helpers ---

      def self.collect_phase_summaries(phases_dir, lines) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
        Dir.children(phases_dir).sort.each do |dir|
          dir_path = File.join(phases_dir, dir)
          next unless File.directory?(dir_path)

          lines << "## #{dir}"
          Dir.children(dir_path).select { |f| f.end_with?("SUMMARY.md") }.sort.each do |s|
            fm = Frontmatter.extract(File.read(File.join(dir_path, s)))
            lines << "- **#{s}**: #{(fm['provides'] || []).join(', ')}"
            (fm["key-decisions"] || []).each { |d| lines << "  - Decision: #{d}" }
          rescue StandardError
            next
          end
          lines << ""
        end
      end

      def self.memory_path
        File.join(Dir.pwd, MEMORY_DIR)
      end

      def self.safe_path!(filename)
        dir = memory_path
        resolved = File.expand_path(filename, dir)
        Output.error("Path outside memory directory: #{filename}") unless resolved.start_with?(File.expand_path(dir))
        resolved
      end

      def self.append_to_memory_file(filename, header, entry)
        dir = memory_path
        FileUtils.mkdir_p(dir)
        path = File.join(dir, filename)
        if File.exist?(path)
          File.write(path, "#{File.read(path).rstrip}\n#{entry}\n")
        else
          File.write(path, "#{header}\n\n#{entry}\n")
        end
      end

      def self.extract_flag(argv, flag)
        idx = argv.index(flag)
        return nil unless idx

        argv[idx + 1]
      end

      def self.parse_named_args(argv, known_keys)
        result = {}
        known_keys.each do |key|
          idx = argv.index("--#{key}")
          result[key] = argv[idx + 1] if idx
        end
        result
      end

      private_class_method :memory_path, :safe_path!, :append_to_memory_file,
                           :extract_flag, :parse_named_args, :collect_phase_summaries
    end
  end
end
