# frozen_string_literal: true

require "json"
require_relative "output"

module Ariadna
  module Tools
    module Utilities
      def self.generate_slug(argv, raw: false)
        text = argv.first
        Output.error("text required for slug generation") unless text

        slug = text.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "")
        Output.json({ slug: slug }, raw: raw, raw_value: slug)
      end

      def self.current_timestamp(argv, raw: false)
        format = argv.first || "full"
        now = Time.now.utc

        result = case format
                 when "date"
                   now.strftime("%Y-%m-%d")
                 when "filename"
                   now.strftime("%Y-%m-%dT%H-%M-%S")
                 else
                   now.iso8601
                 end

        Output.json({ timestamp: result }, raw: raw, raw_value: result)
      end

      def self.list_todos(argv, raw: false)
        area = argv.first
        cwd = Dir.pwd
        pending_dir = File.join(cwd, ".planning", "todos", "pending")

        count = 0
        todos = []

        if File.directory?(pending_dir)
          Dir[File.join(pending_dir, "*.md")].each do |file|
            content = File.read(file)
            created = content[/^created:\s*(.+)$/i, 1]&.strip || "unknown"
            title = content[/^title:\s*(.+)$/i, 1]&.strip || "Untitled"
            todo_area = content[/^area:\s*(.+)$/i, 1]&.strip || "general"

            next if area && todo_area != area

            count += 1
            todos << {
              file: File.basename(file),
              created: created,
              title: title,
              area: todo_area,
              path: File.join(".planning", "todos", "pending", File.basename(file))
            }
          end
        end

        Output.json({ count: count, todos: todos }, raw: raw, raw_value: count.to_s)
      end

      def self.verify_path_exists(argv, raw: false)
        target_path = argv.first
        Output.error("path required for verification") unless target_path

        cwd = Dir.pwd
        full_path = File.absolute_path?(target_path) ? target_path : File.join(cwd, target_path)

        if File.exist?(full_path)
          type = File.directory?(full_path) ? "directory" : "file"
          Output.json({ exists: true, type: type }, raw: raw, raw_value: "true")
        else
          Output.json({ exists: false, type: nil }, raw: raw, raw_value: "false")
        end
      end

      def self.todo_dispatch(argv, raw: false)
        subcommand = argv.shift
        case subcommand
        when "complete"
          todo_complete(argv.first, raw: raw)
        else
          Output.error("Unknown todo subcommand. Available: complete")
        end
      end

      def self.todo_complete(filename, raw: false)
        Output.error("filename required") unless filename
        cwd = Dir.pwd
        pending = File.join(cwd, ".planning", "todos", "pending", filename)
        completed_dir = File.join(cwd, ".planning", "todos", "completed")

        unless File.exist?(pending)
          Output.json({ completed: false, reason: "not_found" }, raw: raw, raw_value: "false")
          return
        end

        FileUtils.mkdir_p(completed_dir)
        FileUtils.mv(pending, File.join(completed_dir, filename))
        Output.json({ completed: true, file: filename }, raw: raw, raw_value: "true")
      end
    end
  end
end
