require "json"

module Ariadna
  module Tools
    module Output
      def self.json(result, raw: false, raw_value: nil)
        if raw && !raw_value.nil?
          $stdout.write(raw_value.to_s)
        else
          $stdout.write(JSON.pretty_generate(result))
        end
        exit 0
      end

      def self.error(message)
        $stderr.write("Error: #{message}\n")
        exit 1
      end
    end
  end
end
