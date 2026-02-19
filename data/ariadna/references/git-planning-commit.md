# Git Planning Commit

Commit planning artifacts using the ariadna-tools CLI, which automatically checks `commit_docs` config and gitignore status.

## Commit via CLI

Always use `ariadna-tools commit` for `.ariadna_planning/` files — it handles `commit_docs` and gitignore checks automatically:

```bash
ariadna-tools commit "docs({scope}): {description}" --files .ariadna_planning/STATE.md .ariadna_planning/ROADMAP.md
```

The CLI will return `skipped` (with reason) if `commit_docs` is `false` or `.ariadna_planning/` is gitignored. No manual conditional checks needed.

## Amend previous commit

To fold `.ariadna_planning/` file changes into the previous commit:

```bash
ariadna-tools commit "" --files .ariadna_planning/codebase/*.md --amend
```

## Commit Message Patterns

| Command | Scope | Example |
|---------|-------|---------|
| plan-phase | phase | `docs(phase-03): create authentication plans` |
| execute-phase | phase | `docs(phase-03): complete authentication phase` |
| new-milestone | milestone | `docs: start milestone v1.1` |
| remove-phase | chore | `chore: remove phase 17 (dashboard)` |
| insert-phase | phase | `docs: insert phase 16.1 (critical fix)` |
| add-phase | phase | `docs: add phase 07 (settings page)` |

## When to Skip

- `commit_docs: false` in config
- `.ariadna_planning/` is gitignored
- No changes to commit (check with `git status --porcelain .ariadna_planning/`)
