require "json"
require_relative "output"
require_relative "frontmatter"

module Ariadna
  module Tools
    module Verification
      def self.dispatch(argv, raw: false)
        subcommand = argv.shift
        case subcommand
        when "commits"
          verify_commits(argv, raw: raw)
        when "phase-completeness"
          verify_phase_completeness(argv.first, raw: raw)
        when "artifacts"
          verify_artifacts(argv.first, raw: raw)
        else
          Output.error("Unknown verify subcommand. Available: commits, phase-completeness, artifacts")
        end
      end

      def self.verify_commits(argv, raw: false)
        Output.error("At least one commit hash required") if argv.empty?

        cwd = Dir.pwd
        valid = []
        invalid = []

        argv.each do |hash|
          result = exec_git(cwd, ["cat-file", "-t", hash])
          if result[:exit_code] == 0 && result[:stdout].strip == "commit"
            valid << hash
          else
            invalid << hash
          end
        end

        Output.json({
          all_valid: invalid.empty?, valid: valid, invalid: invalid, total: argv.length
        }, raw: raw, raw_value: invalid.empty? ? "valid" : "invalid")
      end

      def self.verify_phase_completeness(phase, raw: false)
        Output.error("phase required") unless phase

        cwd = Dir.pwd
        phase_info = find_phase_internal(cwd, phase)

        unless phase_info
          Output.json({ error: "Phase not found", phase: phase }, raw: raw)
          return
        end

        phase_dir = File.join(cwd, phase_info[:directory])
        files = Dir.children(phase_dir)
        plans = files.select { |f| f.match?(/-PLAN\.md$/i) }
        summaries = files.select { |f| f.match?(/-SUMMARY\.md$/i) }

        plan_ids = plans.map { |p| p.sub(/-PLAN\.md$/i, "") }
        summary_ids = summaries.map { |s| s.sub(/-SUMMARY\.md$/i, "") }

        incomplete_plans = plan_ids.reject { |id| summary_ids.include?(id) }
        orphan_summaries = summary_ids.reject { |id| plan_ids.include?(id) }

        errors = []
        warnings = []
        errors << "Plans without summaries: #{incomplete_plans.join(', ')}" if incomplete_plans.any?
        warnings << "Summaries without plans: #{orphan_summaries.join(', ')}" if orphan_summaries.any?

        Output.json({
          complete: errors.empty?, phase: phase_info[:phase_number],
          plan_count: plans.length, summary_count: summaries.length,
          incomplete_plans: incomplete_plans, orphan_summaries: orphan_summaries,
          errors: errors, warnings: warnings
        }, raw: raw, raw_value: errors.empty? ? "complete" : "incomplete")
      end

      def self.verify_artifacts(plan_file_path, raw: false)
        Output.error("plan file path required") unless plan_file_path

        cwd = Dir.pwd
        full_path = File.absolute_path?(plan_file_path) ? plan_file_path : File.join(cwd, plan_file_path)

        unless File.exist?(full_path)
          Output.json({ error: "File not found", path: plan_file_path }, raw: raw)
          return
        end

        content = File.read(full_path)
        artifacts = parse_must_haves_block(content, "artifacts")

        if artifacts.empty?
          Output.json({ error: "No must_haves.artifacts found in frontmatter", path: plan_file_path }, raw: raw)
          return
        end

        results = []
        artifacts.each do |artifact|
          next unless artifact.is_a?(Hash)

          art_path = artifact["path"]
          next unless art_path

          art_full_path = File.join(cwd, art_path)
          exists = File.exist?(art_full_path)
          check = { path: art_path, exists: exists, issues: [], passed: false }

          if exists
            file_content = safe_read_file(art_full_path) || ""
            line_count = file_content.split("\n").length

            if artifact["min_lines"] && line_count < artifact["min_lines"].to_i
              check[:issues] << "Only #{line_count} lines, need #{artifact['min_lines']}"
            end
            if artifact["contains"] && !file_content.include?(artifact["contains"])
              check[:issues] << "Missing pattern: #{artifact['contains']}"
            end
            check[:passed] = check[:issues].empty?
          else
            check[:issues] << "File not found"
          end

          results << check
        end

        passed = results.count { |r| r[:passed] }
        Output.json({
          all_passed: passed == results.length, passed: passed, total: results.length, artifacts: results
        }, raw: raw, raw_value: passed == results.length ? "valid" : "invalid")
      end

      # --- Private helpers ---

      def self.find_phase_internal(cwd, phase)
        phases_dir = File.join(cwd, ".ariadna_planning", "phases")
        normalized = normalize_phase(phase)

        return nil unless File.directory?(phases_dir)

        dirs = Dir.children(phases_dir).select { |d| File.directory?(File.join(phases_dir, d)) }.sort
        match = dirs.find { |d| d.start_with?(normalized) }
        return nil unless match

        dir_match = match.match(/\A(\d+(?:\.\d+)?)-?(.*)/)
        phase_number = dir_match ? dir_match[1] : normalized
        phase_name = dir_match && !dir_match[2].empty? ? dir_match[2] : nil

        { directory: File.join(".ariadna_planning", "phases", match), phase_number: phase_number, phase_name: phase_name }
      rescue StandardError
        nil
      end

      def self.normalize_phase(phase)
        match = phase.to_s.match(/\A(\d+(?:\.\d+)?)/)
        return phase.to_s unless match

        parts = match[1].split(".")
        padded = parts[0].rjust(2, "0")
        parts.length > 1 ? "#{padded}.#{parts[1]}" : padded
      end

      def self.exec_git(cwd, args)
        cmd = "git #{args.map { |a| shell_escape(a) }.join(' ')}"
        stdout = `cd #{shell_escape(cwd)} && #{cmd} 2>&1`
        { exit_code: $?.exitstatus, stdout: stdout.strip, stderr: "" }
      rescue StandardError => e
        { exit_code: 1, stdout: "", stderr: e.message }
      end

      def self.shell_escape(str)
        return str if str.match?(/\A[a-zA-Z0-9._\-\/=:@]+\z/)

        "'#{str.gsub("'", "'\\''")}'"
      end

      def self.safe_read_file(path)
        File.read(path)
      rescue StandardError
        nil
      end

      def self.parse_must_haves_block(content, block_name)
        fm_match = content.match(/\A---\n([\s\S]+?)\n---/)
        return [] unless fm_match

        yaml = fm_match[1]
        block_pattern = /^\s{4}#{Regexp.escape(block_name)}:\s*$/m
        block_start = yaml.index(block_pattern)
        return [] unless block_start

        after_block = yaml[block_start..]
        lines = after_block.split("\n")[1..] # skip header line

        items = []
        current = nil

        lines.each do |line|
          next if line.strip.empty?

          indent = line[/\A(\s*)/, 1].length
          break if indent <= 4 && !line.strip.empty?

          if line.match?(/\A\s{6}-\s+/)
            items << current if current
            kv_match = line.match(/\A\s{6}-\s+(\w+):\s*"?([^"]*)"?\s*\z/)
            current = if kv_match
                        { kv_match[1] => kv_match[2] }
                      else
                        {}
                      end
          elsif current.is_a?(Hash)
            kv_match = line.match(/\A\s{8,}(\w+):\s*"?([^"]*)"?\s*\z/)
            if kv_match
              val = kv_match[2]
              current[kv_match[1]] = val.match?(/\A\d+\z/) ? val.to_i : val
            end
          end
        end

        items << current if current
        items
      end

      private_class_method :find_phase_internal, :normalize_phase, :exec_git, :shell_escape,
                           :safe_read_file, :parse_must_haves_block
    end
  end
end
