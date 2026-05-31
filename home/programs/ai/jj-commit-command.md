# Task: Generate a Jujutsu commit based on diff and an optional user input.

## Context

Current commit message was extracted to: %!`jj describe-to-file {{TMP_DIR}}`!%

### Worktree integrity check

- jj root: %!`jj root`!%
- git toplevel: %!`git rev-parse --show-toplevel`!%

### Current commit description and changes in current revision:

```
%!`jj show --ignore-all-space --no-pager`!%
```

### Recent commits

```
%!`jj log --no-graph --limit 5 --no-pager`!%
```

## Task

Based on the changes above create a single atomic Jujutsu commit with a descriptive message.

The user may provide additional instructions or context for the commit message. If it is not empty, you MUST incorporate its content into the generated commit message to reflect the user's specific requests. The user's raw command is appended below your instructions.

This is intended as a low effort way for the user to commit so avoid asking user questions unless further clarification is required.

## Behavior

**IMPORTANT: NEVER ask user for confirmation. NEVER use `jj describe -m`.**

First, compare **jj root** and **git toplevel** from the integrity check above:

- If they are the **same path** (a normal checkout), follow **Case A**.
- If they **differ**, you are inside a git worktree that jj does not track (e.g. a
  Claude Code worktree under `.claude/worktrees/`). `jj show` above describes the
  **main repo**, not the files in this directory, so committing with jj would
  silently omit your edits. Follow **Case B** instead.

### Case A — jj commit (jj root and git toplevel match)

You MUST follow these exact steps:

1. Generate the new commit message based on the diff, log and any additional user instructions.
2. **Read the temp file first** (path shown above, required before writing).
3. **Write the commit message** to the temp file (this overwrites the old message, allowing user to see the diff).
4. Apply the message and cleanup: `jj describe-from-file <TEMP_FILE>`
5. After the commit message was set, create a new commit: `jj new`. Do not combine this command with the previous command.

### Case B — git commit (paths differ: untracked worktree)

jj cannot see this directory's files, so commit them with git instead:

1. Run `git diff HEAD` to see the actual changes in this directory, then generate
   the commit message from that diff (NOT `jj show`, which describes the main
   repo) plus any user instructions.
2. **Read the temp file first** (path shown above, required before writing).
3. **Write the commit message** to the temp file.
4. Stage and commit with git: `git add -A` then `git commit -F <TEMP_FILE>`. Do
   **not** run `jj new`.
5. The commit now lives on the worktree branch. When you are done with the
   worktree, run `/finish-worktree` to fold this work into `main` and exit cleanly.

## Optional context provided by the user
