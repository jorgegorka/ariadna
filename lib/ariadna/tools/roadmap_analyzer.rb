# frozen_string_literal: true

require "json"
require_relative "output"

module Ariadna
  module Tools
    module RoadmapAnalyzer
      def self.dispatch(argv, raw: false)
        subcommand = argv.shift
        case subcommand
        when "get-phase"
          get_phase(argv.first, raw: raw)
        when "analyze"
          analyze(raw: raw)
        else
          Output.error("Unknown roadmap subcommand. Available: get-phase, analyze")
        end
      end

      def self.progress(argv, raw: false)
        format = argv.first || "json"
        render_progress(format, raw: raw)
      end

      def self.get_phase(phase_num, raw: false)
        Output.error("phase number required") unless phase_num

        cwd = Dir.pwd
        roadmap_path = File.join(cwd, ".planning", "ROADMAP.md")

        unless File.exist?(roadmap_path)
          Output.json({ found: false, error: "ROADMAP.md not found" }, raw: raw, raw_value: "")
          return
        end

        content = File.read(roadmap_path)
        escaped = Regexp.escape(phase_num)
        phase_pattern = /###\s*Phase\s+#{escaped}:\s*([^\n]+)/i
        header_match = content.match(phase_pattern)

        unless header_match
          Output.json({ found: false, phase_number: phase_num }, raw: raw, raw_value: "")
          return
        end

        phase_name = header_match[1].strip
        header_index = header_match.begin(0)

        rest = content[header_index..]
        next_header = rest.match(/\n###\s+Phase\s+\d/i)
        section_end = next_header ? header_index + next_header.begin(0) : content.length
        section = content[header_index...section_end].strip

        goal_match = section.match(/\*\*Goal:\*\*\s*([^\n]+)/i)
        goal = goal_match ? goal_match[1].strip : nil

        Output.json(
          { found: true, phase_number: phase_num, phase_name: phase_name, goal: goal, section: section },
          raw: raw, raw_value: section
        )
      rescue StandardError => e
        Output.error("Failed to read ROADMAP.md: #{e.message}")
      end

      def self.analyze(raw: false)
        cwd = Dir.pwd
        roadmap_path = File.join(cwd, ".planning", "ROADMAP.md")

        unless File.exist?(roadmap_path)
          Output.json({ error: "ROADMAP.md not found", milestones: [], phases: [], current_phase: nil }, raw: raw)
          return
        end

        content = File.read(roadmap_path)
        phases_dir = File.join(cwd, ".planning", "phases")

        phases = []
        phase_pattern = /###\s*Phase\s+(\d+(?:\.\d+)?)\s*:\s*([^\n]+)/i
        scan_offset = 0
        while (pm = content.match(phase_pattern, scan_offset))
          phase_num = pm[1]
          phase_name = pm[2].gsub(/\(INSERTED\)/i, "").strip
          section_start = pm.begin(0)
          scan_offset = pm.end(0)

          rest = content[section_start..]
          next_header = rest.match(/\n###\s+Phase\s+\d/i)
          section_end = next_header ? section_start + next_header.begin(0) : content.length
          section = content[section_start...section_end]

          goal_match = section.match(/\*\*Goal:\*\*\s*([^\n]+)/i)
          goal = goal_match ? goal_match[1].strip : nil

          depends_match = section.match(/\*\*Depends on:\*\*\s*([^\n]+)/i)
          depends_on = depends_match ? depends_match[1].strip : nil

          normalized = normalize_phase(phase_num)
          disk_status = "no_directory"
          plan_count = 0
          summary_count = 0
          has_context = false
          has_research = false

          if File.directory?(phases_dir)
            dirs = Dir.children(phases_dir).select { |d| File.directory?(File.join(phases_dir, d)) }
            dir_match = dirs.find { |d| d.start_with?("#{normalized}-") || d == normalized }

            if dir_match
              phase_files = Dir.children(File.join(phases_dir, dir_match))
              plan_count = phase_files.count { |f| f.end_with?("-PLAN.md") || f == "PLAN.md" }
              summary_count = phase_files.count { |f| f.end_with?("-SUMMARY.md") || f == "SUMMARY.md" }
              has_context = phase_files.any? { |f| f.end_with?("-CONTEXT.md") || f == "CONTEXT.md" }
              has_research = phase_files.any? { |f| f.end_with?("-RESEARCH.md") || f == "RESEARCH.md" }

              disk_status = if summary_count >= plan_count && plan_count > 0
                             "complete"
                           elsif summary_count > 0
                             "partial"
                           elsif plan_count > 0
                             "planned"
                           elsif has_research
                             "researched"
                           elsif has_context
                             "discussed"
                           else
                             "empty"
                           end
            end
          end

          escaped_num = Regexp.escape(phase_num)
          checkbox_match = content.match(/-\s*\[(x| )\]\s*.*Phase\s+#{escaped_num}/i)
          roadmap_complete = checkbox_match ? checkbox_match[1] == "x" : false

          phases << {
            number: phase_num, name: phase_name, goal: goal, depends_on: depends_on,
            plan_count: plan_count, summary_count: summary_count,
            has_context: has_context, has_research: has_research,
            disk_status: disk_status, roadmap_complete: roadmap_complete
          }
        end

        milestones = []
        milestone_pattern = /##\s*(.*v(\d+\.\d+)[^(\n]*)/
        ms_offset = 0
        while (mm = content.match(milestone_pattern, ms_offset))
          milestones << { heading: mm[1].strip, version: "v#{mm[2]}" }
          ms_offset = mm.end(0)
        end

        current_phase = phases.find { |p| p[:disk_status] == "planned" || p[:disk_status] == "partial" }
        next_phase = phases.find { |p| %w[empty no_directory discussed researched].include?(p[:disk_status]) }

        total_plans = phases.sum { |p| p[:plan_count] }
        total_summaries = phases.sum { |p| p[:summary_count] }
        completed_phases = phases.count { |p| p[:disk_status] == "complete" }

        result = {
          milestones: milestones, phases: phases,
          phase_count: phases.length, completed_phases: completed_phases,
          total_plans: total_plans, total_summaries: total_summaries,
          progress_percent: total_plans > 0 ? (total_summaries.to_f / total_plans * 100).round : 0,
          current_phase: current_phase ? current_phase[:number] : nil,
          next_phase: next_phase ? next_phase[:number] : nil
        }

        Output.json(result, raw: raw)
      end

      def self.render_progress(format, raw: false)
        cwd = Dir.pwd
        phases_dir = File.join(cwd, ".planning", "phases")
        milestone = get_milestone_info(cwd)

        phases = []
        total_plans = 0
        total_summaries = 0

        if File.directory?(phases_dir)
          dirs = Dir.children(phases_dir)
                    .select { |d| File.directory?(File.join(phases_dir, d)) }
                    .sort_by { |d| (m = d.match(/\A(\d+(?:\.\d+)?)/)) ? m[1].to_f : 0 }

          dirs.each do |dir|
            dm = dir.match(/\A(\d+(?:\.\d+)?)-?(.*)/)
            phase_num = dm ? dm[1] : dir
            phase_name = dm && !dm[2].empty? ? dm[2].tr("-", " ") : ""
            phase_files = Dir.children(File.join(phases_dir, dir))
            plans = phase_files.count { |f| f.end_with?("-PLAN.md") || f == "PLAN.md" }
            summaries = phase_files.count { |f| f.end_with?("-SUMMARY.md") || f == "SUMMARY.md" }

            total_plans += plans
            total_summaries += summaries

            status = if plans == 0 then "Pending"
                     elsif summaries >= plans then "Complete"
                     elsif summaries > 0 then "In Progress"
                     else "Planned"
                     end

            phases << { number: phase_num, name: phase_name, plans: plans, summaries: summaries, status: status }
          end
        end

        percent = total_plans > 0 ? (total_summaries.to_f / total_plans * 100).round : 0

        case format
        when "table"
          bar_width = 10
          filled = (percent.to_f / 100 * bar_width).round
          bar = "\u2588" * filled + "\u2591" * (bar_width - filled)
          out = "# #{milestone[:version]} #{milestone[:name]}\n\n"
          out += "**Progress:** [#{bar}] #{total_summaries}/#{total_plans} plans (#{percent}%)\n\n"
          out += "| Phase | Name | Plans | Status |\n"
          out += "|-------|------|-------|--------|\n"
          phases.each do |p|
            out += "| #{p[:number]} | #{p[:name]} | #{p[:summaries]}/#{p[:plans]} | #{p[:status]} |\n"
          end
          Output.json({ rendered: out }, raw: raw, raw_value: out)
        when "bar"
          bar_width = 20
          filled = (percent.to_f / 100 * bar_width).round
          bar = "\u2588" * filled + "\u2591" * (bar_width - filled)
          text = "[#{bar}] #{total_summaries}/#{total_plans} plans (#{percent}%)"
          Output.json({ bar: text, percent: percent, completed: total_summaries, total: total_plans }, raw: raw, raw_value: text)
        else
          Output.json({
            milestone_version: milestone[:version], milestone_name: milestone[:name],
            phases: phases, total_plans: total_plans, total_summaries: total_summaries, percent: percent
          }, raw: raw)
        end
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

      def self.normalize_phase(phase)
        match = phase.to_s.match(/\A(\d+(?:\.\d+)?)/)
        return phase.to_s unless match

        parts = match[1].split(".")
        padded = parts[0].rjust(2, "0")
        parts.length > 1 ? "#{padded}.#{parts[1]}" : padded
      end

      private_class_method :render_progress, :get_milestone_info, :normalize_phase
    end
  end
end
