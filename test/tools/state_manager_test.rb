require "test_helper"
require "ariadna/tools/state_manager"

class StateManagerTest < Minitest::Test # rubocop:disable Metrics/ClassLength
  def setup
    @dir = Dir.mktmpdir
    @planning_dir = File.join(@dir, ".ariadna_planning")
    @memory_dir = File.join(@planning_dir, "memory")
    @phases_dir = File.join(@planning_dir, "phases")
    FileUtils.mkdir_p(@memory_dir)
    FileUtils.mkdir_p(@phases_dir)
  end

  def teardown
    FileUtils.rm_rf(@dir)
  end

  # --- list ---

  def test_list_memory_directory
    File.write(File.join(@memory_dir, "decisions.md"), "# Decisions\n")
    File.write(File.join(@memory_dir, "blockers.md"), "# Blockers\n")

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::StateManager.dispatch(["list"]) }
      assert_equal 2, result[:files].length
      names = result[:files].map { |f| f[:name] }
      assert_includes names, "decisions.md"
      assert_includes names, "blockers.md"
    end
  end

  def test_list_empty_memory_directory
    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::StateManager.dispatch(["list"]) }
      assert_equal 0, result[:files].length
    end
  end

  # --- view ---

  def test_view_memory_file
    File.write(File.join(@memory_dir, "decisions.md"), "# Decisions\n\nLine two\nLine three\n")

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::StateManager.dispatch(["view", "decisions.md"]) }
      assert_equal "decisions.md", result[:file]
      assert_includes result[:content], "# Decisions"
      assert_includes result[:content], "Line two"
    end
  end

  def test_view_nonexistent_file_errors
    Dir.chdir(@dir) do
      err = capture_error { Ariadna::Tools::StateManager.dispatch(["view", "missing.md"]) }
      assert_includes err, "not found"
    end
  end

  # --- create ---

  def test_create_memory_file
    Dir.chdir(@dir) do
      result = capture_json do
        Ariadna::Tools::StateManager.dispatch(["create", "notes.md", "# Notes\n\nSome content"])
      end
      assert result[:created]
      assert_equal "notes.md", result[:file]
      assert File.exist?(File.join(@memory_dir, "notes.md"))
      assert_equal "# Notes\n\nSome content", File.read(File.join(@memory_dir, "notes.md"))
    end
  end

  def test_create_fails_if_exists
    File.write(File.join(@memory_dir, "existing.md"), "old content")

    Dir.chdir(@dir) do
      err = capture_error do
        Ariadna::Tools::StateManager.dispatch(["create", "existing.md", "new content"])
      end
      assert_includes err, "already exists"
    end
  end

  # --- update (str_replace) ---

  def test_update_replaces_text
    File.write(File.join(@memory_dir, "notes.md"), "Hello world\nFoo bar\nBaz qux\n")

    Dir.chdir(@dir) do
      result = capture_json do
        Ariadna::Tools::StateManager.dispatch(["update", "notes.md", "Foo bar", "Foo replaced"])
      end
      assert result[:updated]
      content = File.read(File.join(@memory_dir, "notes.md"))
      assert_includes content, "Foo replaced"
      refute_includes content, "Foo bar"
    end
  end

  def test_update_fails_if_text_not_found
    File.write(File.join(@memory_dir, "notes.md"), "Hello world\n")

    Dir.chdir(@dir) do
      err = capture_error do
        Ariadna::Tools::StateManager.dispatch(["update", "notes.md", "nonexistent text", "replacement"])
      end
      assert_includes err, "not found in"
    end
  end

  def test_update_fails_if_ambiguous
    File.write(File.join(@memory_dir, "notes.md"), "foo\nfoo\n")

    Dir.chdir(@dir) do
      err = capture_error { Ariadna::Tools::StateManager.dispatch(["update", "notes.md", "foo", "bar"]) }
      assert_includes err, "ambiguous"
    end
  end

  # --- insert ---

  def test_insert_text_at_line
    File.write(File.join(@memory_dir, "notes.md"), "Line 1\nLine 2\nLine 3\n")

    Dir.chdir(@dir) do
      result = capture_json do
        Ariadna::Tools::StateManager.dispatch(["insert", "notes.md", "2", "Inserted line"])
      end
      assert result[:inserted]
      content = File.read(File.join(@memory_dir, "notes.md"))
      lines = content.split("\n")
      assert_equal "Inserted line", lines[1]
      assert_equal "Line 2", lines[2]
    end
  end

  # --- delete ---

  def test_delete_memory_file
    File.write(File.join(@memory_dir, "temp.md"), "temp content")

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::StateManager.dispatch(["delete", "temp.md"]) }
      assert result[:deleted]
      refute File.exist?(File.join(@memory_dir, "temp.md"))
    end
  end

  def test_delete_nonexistent_file_errors
    Dir.chdir(@dir) do
      err = capture_error { Ariadna::Tools::StateManager.dispatch(["delete", "missing.md"]) }
      assert_includes err, "not found"
    end
  end

  # --- path traversal ---

  def test_path_traversal_blocked
    Dir.chdir(@dir) do
      err = capture_error { Ariadna::Tools::StateManager.dispatch(["view", "../etc/passwd"]) }
      assert_includes err, "outside memory directory"
    end
  end

  def test_path_traversal_blocked_on_create
    Dir.chdir(@dir) do
      err = capture_error do
        Ariadna::Tools::StateManager.dispatch(["create", "../../evil.md", "pwned"])
      end
      assert_includes err, "outside memory directory"
    end
  end

  # --- convenience: add-decision ---

  def test_add_decision
    File.write(File.join(@memory_dir, "decisions.md"), "# Decisions\n\n")

    Dir.chdir(@dir) do
      result = capture_json do
        Ariadna::Tools::StateManager.dispatch(
          ["add-decision", "--phase", "2", "--summary", "Use PostgreSQL",
           "--rationale", "Better JSON support"]
        )
      end
      assert result[:added]
      content = File.read(File.join(@memory_dir, "decisions.md"))
      assert_includes content, "Use PostgreSQL"
      assert_includes content, "Phase 2"
      assert_includes content, "Better JSON support"
    end
  end

  def test_add_decision_creates_file_if_missing
    Dir.chdir(@dir) do
      result = capture_json do
        Ariadna::Tools::StateManager.dispatch(["add-decision", "--phase", "1", "--summary", "Use Redis"])
      end
      assert result[:added]
      assert File.exist?(File.join(@memory_dir, "decisions.md"))
    end
  end

  # --- convenience: add-blocker ---

  def test_add_blocker
    File.write(File.join(@memory_dir, "blockers.md"), "# Blockers\n\n")

    Dir.chdir(@dir) do
      result = capture_json do
        Ariadna::Tools::StateManager.dispatch(["add-blocker", "--text", "API rate limit issue"])
      end
      assert result[:added]
      content = File.read(File.join(@memory_dir, "blockers.md"))
      assert_includes content, "API rate limit issue"
    end
  end

  def test_add_blocker_creates_file_if_missing
    Dir.chdir(@dir) do
      result = capture_json do
        Ariadna::Tools::StateManager.dispatch(["add-blocker", "--text", "Missing credentials"])
      end
      assert result[:added]
      assert File.exist?(File.join(@memory_dir, "blockers.md"))
    end
  end

  # --- convenience: resolve-blocker ---

  def test_resolve_blocker
    blockers = "# Blockers\n\n- API rate limit issue\n- Missing credentials\n"
    File.write(File.join(@memory_dir, "blockers.md"), blockers)

    Dir.chdir(@dir) do
      result = capture_json do
        Ariadna::Tools::StateManager.dispatch(["resolve-blocker", "--text", "API rate limit"])
      end
      assert result[:resolved]
      content = File.read(File.join(@memory_dir, "blockers.md"))
      refute_includes content, "API rate limit issue"
      assert_includes content, "Missing credentials"
    end
  end

  def test_resolve_blocker_errors_if_no_file
    Dir.chdir(@dir) do
      err = capture_error do
        Ariadna::Tools::StateManager.dispatch(["resolve-blocker", "--text", "anything"])
      end
      assert_includes err, "not found"
    end
  end

  # --- convenience: record-metric ---

  def test_record_metric
    File.write(File.join(@memory_dir, "metrics.md"), "# Metrics\n\n")

    Dir.chdir(@dir) do
      result = capture_json do
        Ariadna::Tools::StateManager.dispatch(
          ["record-metric", "--phase", "1", "--plan", "01",
           "--duration", "15m", "--tasks", "5", "--files", "3"]
        )
      end
      assert result[:recorded]
      content = File.read(File.join(@memory_dir, "metrics.md"))
      assert_includes content, "Phase 1"
      assert_includes content, "15m"
    end
  end

  def test_record_metric_creates_file_if_missing
    Dir.chdir(@dir) do
      result = capture_json do
        Ariadna::Tools::StateManager.dispatch(
          ["record-metric", "--phase", "2", "--plan", "03", "--duration", "20m"]
        )
      end
      assert result[:recorded]
      assert File.exist?(File.join(@memory_dir, "metrics.md"))
    end
  end

  # --- convenience: record-session ---

  def test_record_session
    Dir.chdir(@dir) do
      result = capture_json do
        Ariadna::Tools::StateManager.dispatch(
          ["record-session", "--stopped-at", "Phase 2 Plan 3",
           "--resume-file", "02-03-PLAN.md"]
        )
      end
      assert result[:recorded]
      assert File.exist?(File.join(@memory_dir, "session.md"))
      content = File.read(File.join(@memory_dir, "session.md"))
      assert_includes content, "Phase 2 Plan 3"
      assert_includes content, "02-03-PLAN.md"
    end
  end

  # --- history-digest ---

  def test_history_digest
    phase_dir = File.join(@phases_dir, "01-setup")
    FileUtils.mkdir_p(phase_dir)
    summary = <<~MD
      ---
      phase: 1
      plan: 01
      key-decisions:
        - Use PostgreSQL
      provides:
        - db-schema
      ---

      # Summary
    MD
    File.write(File.join(phase_dir, "01-01-SUMMARY.md"), summary)

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::StateManager.dispatch(["history-digest"]) }
      assert result[:created]
      assert File.exist?(File.join(@memory_dir, "history.md"))
      content = File.read(File.join(@memory_dir, "history.md"))
      assert_includes content, "setup"
    end
  end

  def test_history_digest_empty_phases
    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::StateManager.dispatch(["history-digest"]) }
      assert result[:created]
      content = File.read(File.join(@memory_dir, "history.md"))
      assert_includes content, "History"
    end
  end

  # --- unknown subcommand ---

  def test_unknown_subcommand_errors
    Dir.chdir(@dir) do
      err = capture_error { Ariadna::Tools::StateManager.dispatch(["bogus"]) }
      assert_includes err, "Unknown state subcommand"
    end
  end

  private

  def capture_json(&)
    output = capture_output(&)
    JSON.parse(output, symbolize_names: true)
  end

  def capture_output
    old_stdout = $stdout
    $stdout = StringIO.new
    yield
  rescue SystemExit
    # Output.json calls exit(0)
  ensure
    result = $stdout.string
    $stdout = old_stdout
    return result # rubocop:disable Lint/EnsureReturn
  end

  def capture_error
    old_stderr = $stderr
    old_stdout = $stdout
    $stderr = StringIO.new
    $stdout = StringIO.new
    yield
  rescue SystemExit
    # Output.error calls exit(1)
  ensure
    result = $stderr.string
    $stderr = old_stderr
    $stdout = old_stdout
    return result # rubocop:disable Lint/EnsureReturn
  end
end
