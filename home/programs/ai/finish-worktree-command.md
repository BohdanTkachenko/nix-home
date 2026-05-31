# Task: Finish a Claude Code git worktree — fold its work into `main` and reset it so it exits cleanly.

## Background

Claude Code worktrees live under `.claude/worktrees/` and are plain **git**
worktrees that **jj does not track** (jj operates on the main repo). When you
remove such a worktree, Claude warns whenever
`git rev-list --count <birthCommit>..HEAD` is greater than zero — i.e. the
worktree's HEAD has commits beyond the commit it was created from. The base is
the **frozen birth commit**, not a remote ref, so pushing does not silence it.

This skill folds the worktree's work into the main repo's `main` bookmark (via
jj), then resets the worktree back to its birth commit, so `birthCommit..HEAD`
becomes 0 and removal is silent and lossless.

## Context

- jj root (main repo): !`jj root`
- git toplevel (this dir): !`git rev-parse --show-toplevel`
- pending git changes in this directory:

```
!`git status --porcelain`
```

## Behavior

**Pre-flight guard.** If `jj root` equals `git toplevel`, you are NOT in a
worktree — STOP immediately and tell the user `/finish-worktree` only runs inside
a Claude Code worktree. Do nothing else.

Otherwise let `ROOT` = jj root and `WT` = git toplevel (the values shown above).

1. **Find the worktree birth commit** — the commit it was created from, which is
   the base Claude Code's exit check counts against. It is the second field of
   the first line of the worktree's HEAD reflog:
   - `BIRTH=$(head -1 "$(git rev-parse --git-dir)/logs/HEAD" | cut -d' ' -f2)`
   - Review what will be integrated: `git log --oneline "$BIRTH"..HEAD` and
     `git status --short`.

2. **Capture all worktree work as a single diff vs `$BIRTH`:**
   - `git add -A` (stages tracked edits, untracked files, and deletions)
   - `git diff --cached "$BIRTH" > /tmp/finish-worktree.patch`
   - If the patch is empty (no net change vs `$BIRTH`), there is nothing to
     integrate — skip to step 5.

3. **Integrate into the main repo's working copy:**
   - `git -C "$ROOT" apply --3way /tmp/finish-worktree.patch`
   - If `git apply` fails or reports conflicts: **STOP**. Report the failure and
     tell the user the worktree is untouched and they must reconcile manually
     (likely `main` changed the same lines). Do **NOT** reset the worktree.

4. **Commit it on `main` with jj** (jj now sees the changes in the main repo
   working copy — all `jj` commands operate on `ROOT` regardless of cwd):
   - Build the message from this worktree's own commits:
     `git log "$BIRTH"..HEAD --format='%B'`. If there were no commits (only
     uncommitted work), write a concise Conventional-Commits message describing
     the diff. Incorporate any instructions the user passed to the command.
   - `jj describe-to-file /tmp/jj-commit-msg` prints a temp file path. **Read**
     that file, **Write** the message to it, then `jj describe-from-file <path>`.
   - `jj bookmark set main -r @` to advance `main` to the integrated commit, then
     `jj new` to start a fresh working copy on top.
   - **Verify** the work landed: `jj show -r main --stat` must list the worktree's
     files. If it does not, **STOP** and report — do **NOT** reset.

5. **Reset the worktree to its birth commit** (its content is now safe on `main`,
   so the local copy here is redundant):
   - `git -C "$WT" reset --hard "$BIRTH"`
   - Confirm clean: `git -C "$WT" status --porcelain` is empty, and
     `git -C "$WT" rev-list --count "$BIRTH"..HEAD` is `0`.

6. **Report** to the user:
   - what was integrated into `main` (the new commit), or that there was nothing
     to integrate;
   - that the worktree is now clean and `birth..HEAD` is 0, so exiting / removing
     it will be **silent** (no "commits will be lost" warning);
   - a reminder to `jj git push` when ready.

## Optional context provided by the user
