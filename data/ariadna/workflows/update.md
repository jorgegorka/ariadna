<purpose>
Check for Ariadna updates via RubyGems, display changelog for versions between installed and latest, obtain user confirmation, and execute clean installation with cache clearing.
</purpose>

<required_reading>
Read all files referenced by the invoking prompt's execution_context before starting.
</required_reading>

<process>

<step name="get_installed_version">
Detect whether Ariadna is installed locally or globally by checking both locations:

```bash
# Check local first (takes priority)
if [ -f "./.claude/ariadna/VERSION" ]; then
  cat "./.claude/ariadna/VERSION"
  echo "LOCAL"
elif [ -f ~/.claude/ariadna/VERSION ]; then
  cat ~/.claude/ariadna/VERSION
  echo "GLOBAL"
else
  echo "UNKNOWN"
fi
```

Parse output:
- If last line is "LOCAL": installed version is first line, use `--local` flag for update
- If last line is "GLOBAL": installed version is first line, use `--global` flag for update
- If "UNKNOWN": proceed to install step (treat as version 0.0.0)

**If VERSION file missing:**
```
## Ariadna Update

**Installed version:** Unknown

Your installation doesn't include version tracking.

Running fresh install...
```

Proceed to install step (treat as version 0.0.0 for comparison).
</step>

<step name="check_latest_version">
Check RubyGems for latest version:

```bash
gem list ariadna --remote 2>/dev/null | grep ariadna
```

**If gem check fails:**
```
Couldn't check for updates (offline or gem unavailable).

To update manually: `gem update ariadna && ariadna install --global`
```

Exit.
</step>

<step name="compare_versions">
Compare installed vs latest:

**If installed == latest:**
```
## Ariadna Update

**Installed:** X.Y.Z
**Latest:** X.Y.Z

You're already on the latest version.
```

Exit.

**If installed > latest:**
```
## Ariadna Update

**Installed:** X.Y.Z
**Latest:** A.B.C

You're ahead of the latest release (development version?).
```

Exit.
</step>

<step name="show_changes_and_confirm">
**If update available**, fetch and show what's new BEFORE updating:

1. Fetch changelog from GitHub raw URL
2. Extract entries between installed and latest versions
3. Display preview and ask for confirmation:

```
## Ariadna Update Available

**Installed:** 1.5.10
**Latest:** 1.5.15

### What's New
────────────────────────────────────────────────────────────

## [1.5.15] - 2026-01-20

### Added
- Feature X

## [1.5.14] - 2026-01-18

### Fixed
- Bug fix Y

────────────────────────────────────────────────────────────

⚠️  **Note:** The installer performs a clean install of Ariadna folders:
- `commands/ariadna/` will be wiped and replaced
- `ariadna/` will be wiped and replaced
- `agents/ariadna-*` files will be replaced

(Paths are relative to your install location: `~/.claude/` for global, `./.claude/` for local)

Your custom files in other locations are preserved:
- Custom commands not in `commands/ariadna/` ✓
- Custom agents not prefixed with `ariadna-` ✓
- Custom hooks ✓
- Your CLAUDE.md files ✓

If you've modified any Ariadna files directly, they'll be automatically backed up to `ariadna-local-patches/` and can be reapplied with `/ariadna:reapply-patches` after the update.
```

Use AskUserQuestion:
- Question: "Proceed with update?"
- Options:
  - "Yes, update now"
  - "No, cancel"

**If user cancels:** Exit.
</step>

<step name="run_update">
Run the update using the install type detected in step 1:

**If LOCAL install:**
```bash
ariadna install --local
```

**If GLOBAL install (or unknown):**
```bash
ariadna install --global
```

Capture output. If install fails, show error and exit.

Clear the update cache so statusline indicator disappears:

**If LOCAL install:**
```bash
rm -f ./.claude/cache/ariadna-update-check.json
```

**If GLOBAL install:**
```bash
rm -f ~/.claude/cache/ariadna-update-check.json
```
</step>

<step name="display_result">
Format completion message (changelog was already shown in confirmation step):

```
╔═══════════════════════════════════════════════════════════╗
║  Ariadna Updated: v1.5.10 → v1.5.15                           ║
╚═══════════════════════════════════════════════════════════╝

⚠️  Restart Claude Code to pick up the new commands.

[View full changelog](https://github.com/glittercowboy/ariadna/blob/main/CHANGELOG.md)
```
</step>


<step name="check_local_patches">
After update completes, check if the installer detected and backed up any locally modified files:

Check for ariadna-local-patches/backup-meta.json in the config directory.

**If patches found:**

```
Local patches were backed up before the update.
Run /ariadna:reapply-patches to merge your modifications into the new version.
```

**If no patches:** Continue normally.
</step>
</process>

<success_criteria>
- [ ] Installed version read correctly
- [ ] Latest version checked via RubyGems
- [ ] Update skipped if already current
- [ ] Changelog fetched and displayed BEFORE update
- [ ] Clean install warning shown
- [ ] User confirmation obtained
- [ ] Update executed successfully
- [ ] Restart reminder shown
</success_criteria>
