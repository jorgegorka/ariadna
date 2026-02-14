require "json"
require_relative "output"
require_relative "config_manager"

module Ariadna
  module Tools
    module GitIntegration
      def self.commit(argv, raw: false)
        message = argv.shift
        amend = argv.delete("--amend")

        Output.error("commit message required") unless message || amend

        files_idx = argv.index("--files")
        files = files_idx ? argv[(files_idx + 1)..].reject { |a| a.start_with?("--") } : []

        cwd = Dir.pwd
        config = ConfigManager.load_config(cwd)

        unless config["commit_docs"]
          Output.json({ committed: false, hash: nil, reason: "skipped_commit_docs_false" }, raw: raw, raw_value: "skipped")
          return
        end

        if git_ignored?(cwd, ".planning")
          Output.json({ committed: false, hash: nil, reason: "skipped_gitignored" }, raw: raw, raw_value: "skipped")
          return
        end

        # Stage files
        if files.empty?
          exec_git(cwd, ["add", ".planning/"])
        else
          files.each { |f| exec_git(cwd, ["add", f]) }
        end

        # Check if there's anything to commit
        status = exec_git(cwd, ["diff", "--cached", "--quiet"])
        if status[:exit_code] == 0
          Output.json({ committed: false, hash: nil, reason: "nothing_to_commit" }, raw: raw, raw_value: "skipped")
          return
        end

        # Commit
        commit_args = if amend
                        ["commit", "--amend", "-m", message || ""]
                      else
                        ["commit", "-m", message]
                      end

        result = exec_git(cwd, commit_args)
        if result[:exit_code] != 0
          Output.json({ committed: false, hash: nil, reason: result[:stderr] }, raw: raw, raw_value: "failed")
          return
        end

        hash_result = exec_git(cwd, ["rev-parse", "--short", "HEAD"])
        hash = hash_result[:stdout].strip

        Output.json({ committed: true, hash: hash, message: message }, raw: raw, raw_value: hash)
      end

      def self.exec_git(cwd, args)
        cmd = "git #{args.map { |a| shell_escape(a) }.join(' ')}"
        stdout = `cd #{shell_escape(cwd)} && #{cmd} 2>&1`
        { exit_code: $?.exitstatus, stdout: stdout.strip, stderr: "" }
      rescue StandardError => e
        { exit_code: 1, stdout: "", stderr: e.message }
      end

      def self.git_ignored?(cwd, target_path)
        result = exec_git(cwd, ["check-ignore", "-q", "--", target_path])
        result[:exit_code] == 0
      end

      def self.shell_escape(str)
        return str if str.match?(/\A[a-zA-Z0-9._\-\/=:@]+\z/)

        "'#{str.gsub("'", "'\\''")}'"
      end

      private_class_method :exec_git, :git_ignored?, :shell_escape
    end
  end
end
