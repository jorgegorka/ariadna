# frozen_string_literal: true

require "fileutils"
require "json"
require "digest"

module Ariadna
  class Installer
    MANIFEST_NAME = "ariadna-manifest.json"
    PATCHES_DIR = "ariadna-local-patches"

    def initialize(target_dir: nil, local: false)
      @local = local
      @target_dir = target_dir || default_target_dir
    end

    def install
      puts "Ariadna v#{VERSION} — Installing to #{@target_dir}\n\n"

      save_local_patches
      remove_orphans

      copy_commands
      copy_agents
      copy_content
      write_version
      write_manifest

      report_local_patches

      puts "\nDone! Launch Claude Code and run /ariadna:help."
    end

    attr_reader :target_dir

    private

    def default_target_dir
      if @local
        File.join(Dir.pwd, ".claude")
      else
        ENV.fetch("CLAUDE_CONFIG_DIR", File.join(Dir.home, ".claude"))
      end
    end

    def source_dir
      Ariadna.data_dir
    end

    # --- Upgrade: local patch backup ---

    def save_local_patches
      manifest_path = File.join(@target_dir, MANIFEST_NAME)
      return unless File.exist?(manifest_path)

      manifest = JSON.parse(File.read(manifest_path))
      patches_dir = File.join(@target_dir, PATCHES_DIR)
      modified = []

      (manifest["files"] || {}).each do |rel_path, original_hash|
        full_path = File.join(@target_dir, rel_path)
        next unless File.exist?(full_path)

        current_hash = Digest::SHA256.file(full_path).hexdigest
        next if current_hash == original_hash

        backup_path = File.join(patches_dir, rel_path)
        FileUtils.mkdir_p(File.dirname(backup_path))
        FileUtils.cp(full_path, backup_path)
        modified << rel_path
      end

      return if modified.empty?

      meta = {
        backed_up_at: Time.now.utc.iso8601,
        from_version: manifest["version"],
        files: modified
      }
      File.write(File.join(patches_dir, "backup-meta.json"), JSON.pretty_generate(meta))
      puts "  i  Found #{modified.length} locally modified file(s) \u2014 backed up to #{PATCHES_DIR}/"
      modified.each { |f| puts "     #{f}" }
    end

    def report_local_patches
      meta_path = File.join(@target_dir, PATCHES_DIR, "backup-meta.json")
      return unless File.exist?(meta_path)

      meta = JSON.parse(File.read(meta_path))
      files = meta["files"] || []
      return if files.empty?

      puts ""
      puts "  Local patches detected (from v#{meta["from_version"]}):"
      files.each { |f| puts "     #{f}" }
      puts ""
      puts "  Your modifications are saved in #{PATCHES_DIR}/"
      puts "  Run /ariadna:reapply-patches to merge them into the new version."
      puts ""
    end

    # --- Orphan removal ---

    def remove_orphans
      manifest_path = File.join(@target_dir, MANIFEST_NAME)
      return unless File.exist?(manifest_path)

      manifest = JSON.parse(File.read(manifest_path))
      old_files = (manifest["files"] || {}).keys
      new_files = source_manifest_keys
      orphans = old_files - new_files

      orphans.each do |rel_path|
        full_path = File.join(@target_dir, rel_path)
        next unless File.exist?(full_path)

        File.delete(full_path)
        puts "  \u2713 Removed orphaned #{rel_path}"
      end

      # Clean empty directories left behind
      cleanup_empty_dirs
    end

    def source_manifest_keys
      keys = []
      %w[commands/ariadna agents ariadna].each do |subdir|
        src_base = subdir == "agents" ? source_dir : source_dir
        dir = File.join(src_base, subdir)
        next unless File.directory?(dir)

        Dir[File.join(dir, "**", "*")].each do |file|
          next if File.directory?(file)

          rel = file.sub("#{source_dir}/", "")
          keys << rel
        end
      end
      keys
    end

    def cleanup_empty_dirs
      %w[commands/ariadna agents ariadna].each do |subdir|
        dir = File.join(@target_dir, subdir)
        next unless File.directory?(dir)

        # Bottom-up removal of empty dirs
        Dir[File.join(dir, "**", "*")].sort.reverse.each do |path|
          next unless File.directory?(path)

          FileUtils.rmdir(path) if Dir.empty?(path)
        rescue Errno::ENOTEMPTY
          # not empty, skip
        end
      end
    end

    # --- Copy operations ---

    def copy_commands
      src = File.join(source_dir, "commands", "ariadna")
      dest = File.join(@target_dir, "commands", "ariadna")
      copy_tree(src, dest)
      count = Dir[File.join(dest, "*.md")].size
      puts "  \u2713 Installed #{count} commands"
    end

    def copy_agents
      src = File.join(source_dir, "agents")
      dest = File.join(@target_dir, "agents")
      FileUtils.mkdir_p(dest)

      Dir[File.join(src, "ariadna-*.md")].each do |file|
        FileUtils.cp(file, File.join(dest, File.basename(file)))
      end
      count = Dir[File.join(dest, "ariadna-*.md")].size
      puts "  \u2713 Installed #{count} agents"
    end

    def copy_content
      src = File.join(source_dir, "ariadna")
      dest = File.join(@target_dir, "ariadna")
      copy_tree(src, dest)
      puts "  \u2713 Installed ariadna/ (workflows, templates, references)"
    end

    def write_version
      dest = File.join(@target_dir, "ariadna", "VERSION")
      FileUtils.mkdir_p(File.dirname(dest))
      File.write(dest, VERSION)
      puts "  \u2713 Wrote VERSION (#{VERSION})"
    end

    def write_manifest
      manifest = {
        version: VERSION,
        timestamp: Time.now.utc.iso8601,
        files: generate_manifest_entries
      }
      path = File.join(@target_dir, MANIFEST_NAME)
      File.write(path, JSON.pretty_generate(manifest))
      puts "  \u2713 Wrote manifest (#{MANIFEST_NAME})"
    end

    def generate_manifest_entries
      entries = {}
      %w[commands/ariadna agents ariadna].each do |subdir|
        dir = File.join(@target_dir, subdir)
        next unless File.directory?(dir)

        Dir[File.join(dir, "**", "*")].each do |file|
          next if File.directory?(file)

          rel = file.sub("#{@target_dir}/", "")
          entries[rel] = Digest::SHA256.file(file).hexdigest
        end
      end
      entries
    end

    def copy_tree(src, dest)
      FileUtils.rm_rf(dest) if File.directory?(dest)
      FileUtils.mkdir_p(dest)
      FileUtils.cp_r(File.join(src, "."), dest) if File.directory?(src)
    end
  end
end
