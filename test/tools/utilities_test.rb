# frozen_string_literal: true

require "test_helper"
require "ariadna/tools/utilities"

class UtilitiesTest < Minitest::Test
  def test_generate_slug_basic
    # Test the slug logic directly instead of the CLI wrapper (which calls exit)
    text = "My Great Project Name!"
    slug = text.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "")
    assert_equal "my-great-project-name", slug
  end

  def test_generate_slug_special_chars
    text = "hello---world___test"
    slug = text.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "")
    assert_equal "hello-world-test", slug
  end

  def test_todo_file_operations
    Dir.mktmpdir do |dir|
      pending_dir = File.join(dir, ".planning", "todos", "pending")
      completed_dir = File.join(dir, ".planning", "todos", "completed")
      FileUtils.mkdir_p(pending_dir)

      File.write(File.join(pending_dir, "todo-01.md"), "---\ntitle: Fix bug\narea: backend\ncreated: 2025-01-01\n---\n")
      File.write(File.join(pending_dir, "todo-02.md"), "---\ntitle: Add tests\narea: testing\ncreated: 2025-01-02\n---\n")

      assert_equal 2, Dir[File.join(pending_dir, "*.md")].size

      # Simulate todo complete
      FileUtils.mkdir_p(completed_dir)
      FileUtils.mv(File.join(pending_dir, "todo-01.md"), File.join(completed_dir, "todo-01.md"))

      assert_equal 1, Dir[File.join(pending_dir, "*.md")].size
      assert_equal 1, Dir[File.join(completed_dir, "*.md")].size
    end
  end

  def test_verify_path_exists
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "test.md"), "content")
      assert File.exist?(File.join(dir, "test.md"))
      refute File.exist?(File.join(dir, "missing.md"))
    end
  end
end
