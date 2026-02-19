require "fileutils"
require "json"

module Ariadna
  class Uninstaller
    def initialize(target_dir: nil, local: false)
      @local = local
      @target_dir = target_dir || default_target_dir
    end

    def uninstall
      puts "Ariadna — Uninstalling from #{@target_dir}\n\n"

      remove_commands
      remove_agents
      remove_content
      remove_statusline
      remove_patches
      remove_manifest

      puts "\nDone! Ariadna has been uninstalled."
    end

    private

    def default_target_dir
      if @local
        File.join(Dir.pwd, ".claude")
      else
        ENV.fetch("CLAUDE_CONFIG_DIR", File.join(Dir.home, ".claude"))
      end
    end

    def remove_commands
      dir = File.join(@target_dir, "commands", "ariadna")
      if File.directory?(dir)
        FileUtils.rm_rf(dir)
        puts "  \u2713 Removed commands/ariadna/"
      end
    end

    def remove_agents
      dir = File.join(@target_dir, "agents")
      return unless File.directory?(dir)

      removed = 0
      Dir[File.join(dir, "ariadna-*.md")].each do |file|
        File.delete(file)
        removed += 1
      end
      puts "  \u2713 Removed #{removed} agents" if removed > 0
    end

    def remove_content
      dir = File.join(@target_dir, "ariadna")
      if File.directory?(dir)
        FileUtils.rm_rf(dir)
        puts "  \u2713 Removed ariadna/"
      end
    end

    def remove_statusline
      script_path = File.join(@target_dir, "ariadna-statusline.sh")
      FileUtils.rm_f(script_path)

      settings_path = File.join(@target_dir, "settings.json")
      if File.exist?(settings_path)
        settings = JSON.parse(File.read(settings_path))
        if settings.dig("statusLine", "command")&.include?("ariadna-statusline.sh")
          settings.delete("statusLine")
          File.write(settings_path, JSON.pretty_generate(settings))
        end
      end

      puts "  \u2713 Removed statusline"
    end

    def remove_patches
      dir = File.join(@target_dir, Installer::PATCHES_DIR)
      if File.directory?(dir)
        FileUtils.rm_rf(dir)
        puts "  \u2713 Removed #{Installer::PATCHES_DIR}/"
      end
    end

    def remove_manifest
      path = File.join(@target_dir, Installer::MANIFEST_NAME)
      if File.exist?(path)
        File.delete(path)
        puts "  \u2713 Removed manifest"
      end
    end
  end
end
