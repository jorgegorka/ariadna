# frozen_string_literal: true

require "json"
require "fileutils"
require_relative "output"
require_relative "frontmatter"

module Ariadna
  module Tools
    module TemplateFiller
      def self.dispatch(argv, raw: false)
        subcommand = argv.shift
        case subcommand
        when "fill"
          template_type = argv.shift
          options = parse_options(argv)
          fill(template_type, options, raw: raw)
        when "select"
          select(argv.first, raw: raw)
        else
          Output.error("Unknown template subcommand. Available: fill, select")
        end
      end

      def self.scaffold(argv, raw: false)
        type = argv.shift
        phase_idx = argv.index("--phase")
        name_idx = argv.index("--name")
        options = {
          phase: phase_idx ? argv[phase_idx + 1] : nil,
          name: name_idx ? argv[(name_idx + 1)..].join(" ") : nil
        }
        scaffold_type(type, options, raw: raw)
      end

      def self.select(plan_path, raw: false)
        Output.error("plan-path required") unless plan_path

        cwd = Dir.pwd
        full_path = File.join(cwd, plan_path)

        begin
          content = File.read(full_path)
          task_matches = content.scan(/###\s*Task\s*\d+/i)
          task_count = task_matches.length

          has_decisions = content.match?(/decision/i)

          file_mentions = []
          content.scan(/`([^`]+\.[a-zA-Z]+)`/) do
            f = ::Regexp.last_match(1)
            file_mentions << f if f.include?("/") && !f.start_with?("http") && !file_mentions.include?(f)
          end
          file_count = file_mentions.length

          template = "templates/summary-standard.md"
          type = "standard"

          if task_count <= 2 && file_count <= 3 && !has_decisions
            template = "templates/summary-minimal.md"
            type = "minimal"
          elsif has_decisions || file_count > 6 || task_count > 5
            template = "templates/summary-complex.md"
            type = "complex"
          end

          Output.json({ template: template, type: type, taskCount: task_count, fileCount: file_count, hasDecisions: has_decisions },
                      raw: raw, raw_value: template)
        rescue StandardError => e
          Output.json({ template: "templates/summary-standard.md", type: "standard", error: e.message },
                      raw: raw, raw_value: "templates/summary-standard.md")
        end
      end

      def self.fill(template_type, options, raw: false)
        Output.error("template type required: summary, plan, or verification") unless template_type
        Output.error("--phase required") unless options[:phase]

        cwd = Dir.pwd
        phase_info = find_phase_internal(cwd, options[:phase])

        unless phase_info
          Output.json({ error: "Phase not found", phase: options[:phase] }, raw: raw)
          return
        end

        padded = normalize_phase(options[:phase])
        today = Time.now.utc.strftime("%Y-%m-%d")
        phase_name = options[:name] || phase_info[:phase_name] || "Unnamed"
        phase_slug = phase_info[:phase_slug] || generate_slug(phase_name)
        phase_id = "#{padded}-#{phase_slug}"
        plan_num = (options[:plan] || "01").to_s.rjust(2, "0")
        fields = options[:fields] || {}

        frontmatter = nil
        body = nil
        file_name = nil

        case template_type
        when "summary"
          frontmatter = {
            "phase" => phase_id, "plan" => plan_num, "subsystem" => "[primary category]",
            "tags" => [], "provides" => [], "affects" => [],
            "tech-stack" => { "added" => [], "patterns" => [] },
            "key-files" => { "created" => [], "modified" => [] },
            "key-decisions" => [], "patterns-established" => [],
            "duration" => "[X]min", "completed" => today
          }.merge(fields)

          body = [
            "# Phase #{options[:phase]}: #{phase_name} Summary", "",
            "**[Substantive one-liner describing outcome]**", "",
            "## Performance",
            "- **Duration:** [time]", "- **Tasks:** [count completed]", "- **Files modified:** [count]", "",
            "## Accomplishments", "- [Key outcome 1]", "- [Key outcome 2]", "",
            "## Task Commits", "1. **Task 1: [task name]** - `hash`", "",
            "## Files Created/Modified", "- `path/to/file.ts` - What it does", "",
            "## Decisions & Deviations", "[Key decisions or \"None - followed plan as specified\"]", "",
            "## Next Phase Readiness", "[What's ready for next phase]"
          ].join("\n")
          file_name = "#{padded}-#{plan_num}-SUMMARY.md"

        when "plan"
          plan_type = options[:type] || "execute"
          wave = (options[:wave] || "1").to_i
          frontmatter = {
            "phase" => phase_id, "plan" => plan_num, "type" => plan_type, "wave" => wave,
            "depends_on" => [], "files_modified" => [], "autonomous" => true,
            "user_setup" => [],
            "must_haves" => { "truths" => [], "artifacts" => [], "key_links" => [] }
          }.merge(fields)

          body = [
            "# Phase #{options[:phase]} Plan #{plan_num}: [Title]", "",
            "## Objective",
            "- **What:** [What this plan builds]",
            "- **Why:** [Why it matters for the phase goal]",
            "- **Output:** [Concrete deliverable]", "",
            "## Context",
            "@.planning/PROJECT.md", "@.planning/ROADMAP.md", "@.planning/STATE.md", "",
            "## Tasks", "",
            "<task type=\"code\">",
            "  <name>[Task name]</name>",
            "  <files>[file paths]</files>",
            "  <action>[What to do]</action>",
            "  <verify>[How to verify]</verify>",
            "  <done>[Definition of done]</done>",
            "</task>", "",
            "## Verification", "[How to verify this plan achieved its objective]", "",
            "## Success Criteria", "- [ ] [Criterion 1]", "- [ ] [Criterion 2]"
          ].join("\n")
          file_name = "#{padded}-#{plan_num}-PLAN.md"

        when "verification"
          frontmatter = {
            "phase" => phase_id, "verified" => Time.now.utc.iso8601,
            "status" => "pending", "score" => "0/0 must-haves verified"
          }.merge(fields)

          body = [
            "# Phase #{options[:phase]}: #{phase_name} \u2014 Verification", "",
            "## Observable Truths",
            "| # | Truth | Status | Evidence |",
            "|---|-------|--------|----------|",
            "| 1 | [Truth] | pending | |", "",
            "## Required Artifacts",
            "| Artifact | Expected | Status | Details |",
            "|----------|----------|--------|---------|",
            "| [path] | [what] | pending | |", "",
            "## Key Link Verification",
            "| From | To | Via | Status | Details |",
            "|------|----|----|--------|---------|",
            "| [source] | [target] | [connection] | pending | |", "",
            "## Requirements Coverage",
            "| Requirement | Status | Blocking Issue |",
            "|-------------|--------|----------------|",
            "| [req] | pending | |", "",
            "## Result", "[Pending verification]"
          ].join("\n")
          file_name = "#{padded}-VERIFICATION.md"

        else
          Output.error("Unknown template type: #{template_type}. Available: summary, plan, verification")
        end

        yaml_str = Frontmatter.reconstruct(frontmatter)
        full_content = "---\n#{yaml_str}\n---\n\n#{body}\n"
        out_path = File.join(cwd, phase_info[:directory], file_name)

        if File.exist?(out_path)
          rel_path = out_path.sub("#{cwd}/", "")
          Output.json({ error: "File already exists", path: rel_path }, raw: raw)
          return
        end

        File.write(out_path, full_content)
        rel_path = out_path.sub("#{cwd}/", "")
        Output.json({ created: true, path: rel_path, template: template_type }, raw: raw, raw_value: rel_path)
      end

      def self.scaffold_type(type, options, raw: false)
        cwd = Dir.pwd
        phase = options[:phase]
        name = options[:name]
        padded = phase ? normalize_phase(phase) : "00"
        today = Time.now.utc.strftime("%Y-%m-%d")

        phase_info = phase ? find_phase_internal(cwd, phase) : nil
        phase_dir = phase_info ? File.join(cwd, phase_info[:directory]) : nil

        if phase && !phase_dir && type != "phase-dir"
          Output.error("Phase #{phase} directory not found")
        end

        case type
        when "context"
          phase_name = name || phase_info&.dig(:phase_name) || "Unnamed"
          file_path = File.join(phase_dir, "#{padded}-CONTEXT.md")
          content = "---\nphase: \"#{padded}\"\nname: \"#{phase_name}\"\ncreated: #{today}\n---\n\n# Phase #{phase}: #{phase_name} \u2014 Context\n\n## Decisions\n\n_Decisions will be captured during /ariadna:discuss-phase #{phase}_\n\n## Discretion Areas\n\n_Areas where the executor can use judgment_\n\n## Deferred Ideas\n\n_Ideas to consider later_\n"
        when "uat"
          phase_name = name || phase_info&.dig(:phase_name) || "Unnamed"
          file_path = File.join(phase_dir, "#{padded}-UAT.md")
          content = "---\nphase: \"#{padded}\"\nname: \"#{phase_name}\"\ncreated: #{today}\nstatus: pending\n---\n\n# Phase #{phase}: #{phase_name} \u2014 User Acceptance Testing\n\n## Test Results\n\n| # | Test | Status | Notes |\n|---|------|--------|-------|\n\n## Summary\n\n_Pending UAT_\n"
        when "verification"
          phase_name = name || phase_info&.dig(:phase_name) || "Unnamed"
          file_path = File.join(phase_dir, "#{padded}-VERIFICATION.md")
          content = "---\nphase: \"#{padded}\"\nname: \"#{phase_name}\"\ncreated: #{today}\nstatus: pending\n---\n\n# Phase #{phase}: #{phase_name} \u2014 Verification\n\n## Goal-Backward Verification\n\n**Phase Goal:** [From ROADMAP.md]\n\n## Checks\n\n| # | Requirement | Status | Evidence |\n|---|------------|--------|----------|\n\n## Result\n\n_Pending verification_\n"
        when "phase-dir"
          Output.error("phase and name required for phase-dir scaffold") unless phase && name
          slug = generate_slug(name)
          dir_name = "#{padded}-#{slug}"
          phases_parent = File.join(cwd, ".planning", "phases")
          FileUtils.mkdir_p(phases_parent)
          dir_path = File.join(phases_parent, dir_name)
          FileUtils.mkdir_p(dir_path)
          Output.json({ created: true, directory: ".planning/phases/#{dir_name}", path: dir_path }, raw: raw, raw_value: dir_path)
          return
        else
          Output.error("Unknown scaffold type: #{type}. Available: context, uat, verification, phase-dir")
        end

        if File.exist?(file_path)
          Output.json({ created: false, reason: "already_exists", path: file_path }, raw: raw, raw_value: "exists")
          return
        end

        File.write(file_path, content)
        rel_path = file_path.sub("#{cwd}/", "")
        Output.json({ created: true, path: rel_path }, raw: raw, raw_value: rel_path)
      end

      # --- Private helpers ---

      def self.find_phase_internal(cwd, phase)
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

        { directory: File.join(".planning", "phases", match), phase_number: phase_number, phase_name: phase_name, phase_slug: phase_slug }
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

      def self.generate_slug(text)
        return nil unless text

        text.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "")
      end

      def self.parse_options(argv)
        result = {}
        %w[phase plan name type wave].each do |key|
          idx = argv.index("--#{key}")
          result[key.to_sym] = argv[idx + 1] if idx
        end

        fields_idx = argv.index("--fields")
        result[:fields] = fields_idx ? JSON.parse(argv[fields_idx + 1]) : {}
        result
      rescue JSON::ParserError
        result[:fields] = {}
        result
      end

      private_class_method :find_phase_internal, :normalize_phase, :generate_slug, :parse_options, :scaffold_type
    end
  end
end
