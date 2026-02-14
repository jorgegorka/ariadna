# frozen_string_literal: true

require "test_helper"
require "ariadna/installer"
require "ariadna/uninstaller"
require "digest"

class InstallerTest < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir("ariadna-test-")
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  # --- Fresh install ---

  def test_fresh_install_creates_commands
    installer = Ariadna::Installer.new(target_dir: @tmpdir)
    installer.install

    cmd_dir = File.join(@tmpdir, "commands", "ariadna")
    assert File.directory?(cmd_dir), "commands/ariadna/ should exist"
    assert File.exist?(File.join(cmd_dir, "new-project.md")), "new-project.md should exist"
    assert File.exist?(File.join(cmd_dir, "execute-phase.md")), "execute-phase.md should exist"
  end

  def test_fresh_install_creates_agents
    installer = Ariadna::Installer.new(target_dir: @tmpdir)
    installer.install

    agents_dir = File.join(@tmpdir, "agents")
    assert File.directory?(agents_dir), "agents/ should exist"
    assert File.exist?(File.join(agents_dir, "ariadna-executor.md")), "ariadna-executor.md should exist"
    assert File.exist?(File.join(agents_dir, "ariadna-planner.md")), "ariadna-planner.md should exist"
  end

  def test_fresh_install_creates_content
    installer = Ariadna::Installer.new(target_dir: @tmpdir)
    installer.install

    assert File.directory?(File.join(@tmpdir, "ariadna", "workflows")), "workflows/ should exist"
    assert File.directory?(File.join(@tmpdir, "ariadna", "templates")), "templates/ should exist"
    assert File.directory?(File.join(@tmpdir, "ariadna", "references")), "references/ should exist"
  end

  def test_fresh_install_writes_version
    installer = Ariadna::Installer.new(target_dir: @tmpdir)
    installer.install

    version_path = File.join(@tmpdir, "ariadna", "VERSION")
    assert File.exist?(version_path)
    assert_equal Ariadna::VERSION, File.read(version_path)
  end

  def test_fresh_install_writes_manifest
    installer = Ariadna::Installer.new(target_dir: @tmpdir)
    installer.install

    manifest_path = File.join(@tmpdir, Ariadna::Installer::MANIFEST_NAME)
    assert File.exist?(manifest_path)

    manifest = JSON.parse(File.read(manifest_path))
    assert_equal Ariadna::VERSION, manifest["version"]
    assert manifest["timestamp"]
    assert manifest["files"].is_a?(Hash)
    refute_empty manifest["files"]

    # Every file entry should be a SHA256 hex digest
    manifest["files"].each do |rel_path, hash|
      assert_match(/\A[a-f0-9]{64}\z/, hash, "#{rel_path} should have valid SHA256")
      assert File.exist?(File.join(@tmpdir, rel_path)), "#{rel_path} should exist on disk"
    end
  end

  def test_manifest_hashes_match_actual_files
    installer = Ariadna::Installer.new(target_dir: @tmpdir)
    installer.install

    manifest = JSON.parse(File.read(File.join(@tmpdir, Ariadna::Installer::MANIFEST_NAME)))
    manifest["files"].each do |rel_path, expected_hash|
      actual = Digest::SHA256.file(File.join(@tmpdir, rel_path)).hexdigest
      assert_equal expected_hash, actual, "Hash mismatch for #{rel_path}"
    end
  end

  # --- Upgrade: local patch backup ---

  def test_upgrade_backs_up_modified_files
    # First install
    installer = Ariadna::Installer.new(target_dir: @tmpdir)
    installer.install

    # Modify a file
    cmd_file = File.join(@tmpdir, "commands", "ariadna", "help.md")
    assert File.exist?(cmd_file)
    File.write(cmd_file, "# My custom help\n\nI modified this file.")

    # Re-install (upgrade)
    installer2 = Ariadna::Installer.new(target_dir: @tmpdir)
    installer2.install

    # Check backup exists
    patches_dir = File.join(@tmpdir, Ariadna::Installer::PATCHES_DIR)
    assert File.directory?(patches_dir), "patches dir should exist"

    backup = File.join(patches_dir, "commands", "ariadna", "help.md")
    assert File.exist?(backup), "modified file should be backed up"
    assert_equal "# My custom help\n\nI modified this file.", File.read(backup)

    meta_path = File.join(patches_dir, "backup-meta.json")
    assert File.exist?(meta_path)
    meta = JSON.parse(File.read(meta_path))
    assert_includes meta["files"], "commands/ariadna/help.md"
    assert_equal Ariadna::VERSION, meta["from_version"]
  end

  def test_upgrade_does_not_back_up_unmodified_files
    # First install
    installer = Ariadna::Installer.new(target_dir: @tmpdir)
    installer.install

    # Re-install without modifications
    installer2 = Ariadna::Installer.new(target_dir: @tmpdir)
    installer2.install

    patches_dir = File.join(@tmpdir, Ariadna::Installer::PATCHES_DIR)
    refute File.directory?(patches_dir), "patches dir should not exist for clean upgrade"
  end

  # --- Orphan removal ---

  def test_upgrade_removes_orphaned_files
    # First install
    installer = Ariadna::Installer.new(target_dir: @tmpdir)
    installer.install

    # Simulate a file that was in old version but not new
    orphan_path = File.join(@tmpdir, "commands", "ariadna", "old-removed-command.md")
    File.write(orphan_path, "# Old command")

    # Add it to manifest as if it was installed before
    manifest_path = File.join(@tmpdir, Ariadna::Installer::MANIFEST_NAME)
    manifest = JSON.parse(File.read(manifest_path))
    manifest["files"]["commands/ariadna/old-removed-command.md"] = Digest::SHA256.hexdigest("# Old command")
    File.write(manifest_path, JSON.pretty_generate(manifest))

    # Re-install
    installer2 = Ariadna::Installer.new(target_dir: @tmpdir)
    installer2.install

    # Orphan should be removed
    refute File.exist?(orphan_path), "orphaned file should be removed"
  end

  # --- Uninstall ---

  def test_uninstall_removes_everything
    # Install first
    installer = Ariadna::Installer.new(target_dir: @tmpdir)
    installer.install

    # Verify files exist
    assert File.exist?(File.join(@tmpdir, Ariadna::Installer::MANIFEST_NAME))

    # Uninstall
    uninstaller = Ariadna::Uninstaller.new(target_dir: @tmpdir)
    uninstaller.uninstall

    refute File.directory?(File.join(@tmpdir, "commands", "ariadna")), "commands should be removed"
    refute File.exist?(File.join(@tmpdir, "ariadna", "workflows")), "ariadna content should be removed"
    refute File.exist?(File.join(@tmpdir, Ariadna::Installer::MANIFEST_NAME)), "manifest should be removed"
  end

  def test_uninstall_preserves_non_ariadna_agents
    installer = Ariadna::Installer.new(target_dir: @tmpdir)
    installer.install

    # Create a non-ariadna agent
    custom_agent = File.join(@tmpdir, "agents", "my-custom-agent.md")
    File.write(custom_agent, "# Custom agent")

    uninstaller = Ariadna::Uninstaller.new(target_dir: @tmpdir)
    uninstaller.uninstall

    assert File.exist?(custom_agent), "non-ariadna agents should be preserved"
    refute File.exist?(File.join(@tmpdir, "agents", "ariadna-executor.md")), "ariadna agents should be removed"
  end

  def test_uninstall_removes_patches_dir
    installer = Ariadna::Installer.new(target_dir: @tmpdir)
    installer.install

    # Modify a file and re-install to create patches
    cmd_file = File.join(@tmpdir, "commands", "ariadna", "help.md")
    File.write(cmd_file, "modified")
    installer2 = Ariadna::Installer.new(target_dir: @tmpdir)
    installer2.install

    assert File.directory?(File.join(@tmpdir, Ariadna::Installer::PATCHES_DIR))

    # Uninstall
    uninstaller = Ariadna::Uninstaller.new(target_dir: @tmpdir)
    uninstaller.uninstall

    refute File.directory?(File.join(@tmpdir, Ariadna::Installer::PATCHES_DIR)), "patches dir should be removed"
  end

  # --- Idempotency ---

  def test_install_is_idempotent
    installer = Ariadna::Installer.new(target_dir: @tmpdir)
    installer.install

    manifest1 = JSON.parse(File.read(File.join(@tmpdir, Ariadna::Installer::MANIFEST_NAME)))

    installer2 = Ariadna::Installer.new(target_dir: @tmpdir)
    installer2.install

    manifest2 = JSON.parse(File.read(File.join(@tmpdir, Ariadna::Installer::MANIFEST_NAME)))

    # File hashes should be identical
    assert_equal manifest1["files"], manifest2["files"]
  end

  # --- Local install ---

  def test_local_install_uses_pwd
    Dir.mktmpdir("ariadna-local-test-") do |project_dir|
      Dir.chdir(project_dir) do
        installer = Ariadna::Installer.new(local: true)
        assert installer.target_dir.end_with?(".claude"), "should end with .claude"
        assert installer.target_dir.include?(File.basename(project_dir)),
               "should include the tmpdir name"
      end
    end
  end
end
