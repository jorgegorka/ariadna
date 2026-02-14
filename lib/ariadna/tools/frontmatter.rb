require "json"
require_relative "output"

module Ariadna
  module Tools
    module Frontmatter
      SCHEMAS = {
        "plan" => %w[phase plan type],
        "summary" => %w[phase plan subsystem],
        "verification" => %w[phase]
      }.freeze

      def self.dispatch(argv, raw: false)
        subcommand = argv.shift
        file = argv.shift

        case subcommand
        when "get"
          field = extract_flag(argv, "--field")
          get(file, field: field, raw: raw)
        when "set"
          field = extract_flag(argv, "--field")
          value = extract_flag(argv, "--value")
          set(file, field: field, value: value, raw: raw)
        when "merge"
          data = extract_flag(argv, "--data")
          merge(file, data: data, raw: raw)
        when "validate"
          schema = extract_flag(argv, "--schema")
          validate(file, schema: schema, raw: raw)
        else
          Output.error("Unknown frontmatter subcommand. Available: get, set, merge, validate")
        end
      end

      def self.extract(content)
        return {} unless content.start_with?("---\n")

        end_index = content.index("---", 3)
        return {} unless end_index

        yaml_str = content[3...end_index].strip
        parse_yaml(yaml_str)
      end

      def self.reconstruct(obj)
        lines = []
        obj.each do |key, value|
          next if value.nil?

          if value.is_a?(Array)
            if value.empty?
              lines << "#{key}: []"
            elsif value.all?(String) && value.length <= 3 && value.join(", ").length < 60
              lines << "#{key}: [#{value.join(', ')}]"
            else
              lines << "#{key}:"
              value.each do |item|
                item_str = item.to_s
                lines << if item_str.include?(":") || item_str.include?("#")
                           "  - \"#{item_str}\""
                         else
                           "  - #{item_str}"
                         end
              end
            end
          elsif value.is_a?(Hash)
            lines << "#{key}:"
            value.each do |subkey, subval|
              next if subval.nil?

              if subval.is_a?(Array)
                if subval.empty?
                  lines << "  #{subkey}: []"
                else
                  lines << "  #{subkey}:"
                  subval.each { |item| lines << "    - #{item}" }
                end
              elsif subval.is_a?(Hash)
                lines << "  #{subkey}:"
                subval.each do |k, v|
                  next if v.nil?

                  lines << "    #{k}: #{v}"
                end
              else
                sv = subval.to_s
                lines << if sv.include?(":") || sv.include?("#")
                           "  #{subkey}: \"#{sv}\""
                         else
                           "  #{subkey}: #{sv}"
                         end
              end
            end
          else
            sv = value.to_s
            lines << if sv.include?(":") || sv.include?("#") || sv.start_with?("[") || sv.start_with?("{")
                       "#{key}: \"#{sv}\""
                     else
                       "#{key}: #{sv}"
                     end
          end
        end
        lines.join("\n")
      end

      def self.splice(content, new_obj)
        yaml_str = reconstruct(new_obj)
        if content.match?(/\A---\n[\s\S]+?\n---/)
          content.sub(/\A---\n[\s\S]+?\n---/, "---\n#{yaml_str}\n---")
        else
          "---\n#{yaml_str}\n---\n\n#{content}"
        end
      end

      def self.body(content)
        return content unless content.start_with?("---\n")

        end_index = content.index("---", 3)
        return content unless end_index

        content[(end_index + 3)..].lstrip
      end

      # --- CLI commands ---

      def self.get(file, field: nil, raw: false)
        cwd = Dir.pwd
        path = File.expand_path(file, cwd)
        content = File.read(path)
        fm = extract(content)

        if field
          value = fm[field]
          Output.json({ field => value }, raw: raw, raw_value: value.to_s)
        else
          Output.json(fm, raw: raw)
        end
      rescue Errno::ENOENT
        Output.error("File not found: #{file}")
      end

      def self.set(file, field:, value:, raw: false)
        Output.error("field and value required") unless field && value
        cwd = Dir.pwd
        path = File.expand_path(file, cwd)
        content = File.read(path)
        fm = extract(content)

        parsed_value = parse_value(value)
        fm[field] = parsed_value
        new_content = splice(content, fm)
        File.write(path, new_content)
        Output.json({ updated: true, field: field, value: parsed_value }, raw: raw, raw_value: "true")
      rescue Errno::ENOENT
        Output.error("File not found: #{file}")
      end

      def self.merge(file, data:, raw: false)
        Output.error("--data required") unless data
        cwd = Dir.pwd
        path = File.expand_path(file, cwd)
        content = File.read(path)
        fm = extract(content)

        merge_data = JSON.parse(data)
        fm.merge!(merge_data)
        new_content = splice(content, fm)
        File.write(path, new_content)
        Output.json({ merged: true, fields: merge_data.keys }, raw: raw, raw_value: "true")
      rescue Errno::ENOENT
        Output.error("File not found: #{file}")
      rescue JSON::ParserError
        Output.error("Invalid JSON in --data")
      end

      def self.validate(file, schema:, raw: false)
        Output.error("--schema required") unless schema
        required = SCHEMAS[schema]
        Output.error("Unknown schema: #{schema}. Available: #{SCHEMAS.keys.join(', ')}") unless required

        cwd = Dir.pwd
        path = File.expand_path(file, cwd)
        content = File.read(path)
        fm = extract(content)

        missing = required.reject { |f| fm.key?(f) }
        valid = missing.empty?
        Output.json({ valid: valid, missing: missing, schema: schema }, raw: raw, raw_value: valid.to_s)
      rescue Errno::ENOENT
        Output.error("File not found: #{file}")
      end

      # --- Private helpers ---

      def self.parse_yaml(yaml_str)
        result = {}
        stack = [{ obj: result, key: nil, indent: -1 }]

        yaml_str.each_line do |line|
          stripped = line.strip
          next if stripped.empty?

          indent = line[/\A(\s*)/, 1].length

          stack.pop while stack.length > 1 && indent <= stack.last[:indent]
          current = stack.last

          if (key_match = line.match(/\A(\s*)([a-zA-Z0-9_-]+):\s*(.*)/))
            key = key_match[2]
            value = key_match[3].strip

            if value.empty? || value == "["
              current[:obj][key] = value == "[" ? [] : {}
              stack.push({ obj: current[:obj][key], key: nil, indent: indent })
            elsif value.start_with?("[") && value.end_with?("]")
              current[:obj][key] = value[1..-2].split(",").map { |s| s.strip.gsub(/\A["']|["']\z/, "") }.reject(&:empty?)
            else
              current[:obj][key] = value.gsub(/\A["']|["']\z/, "")
            end
          elsif stripped.start_with?("- ")
            item_value = stripped[2..].gsub(/\A["']|["']\z/, "")

            if current[:obj].is_a?(Hash) && current[:obj].empty?
              parent = stack.length > 1 ? stack[-2] : nil
              if parent
                parent[:obj].each do |k, v|
                  if v.equal?(current[:obj])
                    parent[:obj][k] = [item_value]
                    current[:obj] = parent[:obj][k]
                    break
                  end
                end
              end
            elsif current[:obj].is_a?(Array)
              current[:obj] << item_value
            end
          end
        end

        result
      end

      def self.parse_value(str)
        case str
        when "true" then true
        when "false" then false
        when /\A\d+\z/ then str.to_i
        when /\A\d+\.\d+\z/ then str.to_f
        else str
        end
      end

      def self.extract_flag(argv, flag)
        idx = argv.index(flag)
        return nil unless idx

        argv[idx + 1]
      end

      private_class_method :parse_yaml, :parse_value, :extract_flag
    end
  end
end
