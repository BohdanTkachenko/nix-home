# Task: Unify agent instruction files under AGENTS.md

Goal: the project must end up with `AGENTS.md` as a regular file containing the unified instructions, and `CLAUDE.md` as a symlink pointing to `AGENTS.md`.

Run all commands from the project root (the current working directory, unless the user specifies otherwise).

## Step 1 — Inspect current state

Use `ls -la AGENTS.md CLAUDE.md` (via Bash) to determine, for each of the two files:

- Does it exist?
- Is it a regular file or a symlink?
- If a symlink, what does it point to?

Then classify the situation into one of these cases:

- **Case A — nothing exists.** Create a minimal `AGENTS.md` stub and symlink `CLAUDE.md` to it. Skip to Step 4.
- **Case B — already correct.** `AGENTS.md` is a regular file and `CLAUDE.md` is a symlink resolving to it. Report this and stop — no changes needed.
- **Case C — partially correct or needs unification.** One or both files exist with real content (possibly symlinked between each other, e.g. `CLAUDE.md -> AGENTS.md` already, or `AGENTS.md -> CLAUDE.md`). Continue to Step 2.

## Step 2 — Collect unique content sources

Determine the set of *distinct* real files among `AGENTS.md` and `CLAUDE.md`. Resolve symlinks so you don't double-count (e.g. if `CLAUDE.md -> AGENTS.md`, there is only one real file to read). Read each distinct file with the Read tool.

If only one distinct real file exists, its content becomes the base for the unified `AGENTS.md` (you may still need minor edits — see Step 3).

If both are distinct real files, proceed to Step 3 to merge them.

## Step 3 — Produce unified content

Create unified content that:

1. **Preserves every instruction** from all source files. Do not drop guidance just because it only appeared in one file.
2. **Deduplicates** sections that say the same thing in different words — keep the clearest phrasing.
3. **Reconciles contradictions.** If the files disagree on something substantive (e.g. different commit conventions, different tool preferences), do not silently pick one. Stop and ask the user which to keep, then continue.
4. **Removes assistant-specific framing** where possible. The file will be read by Claude and any other AGENTS.md-aware tool, so prefer neutral language ("the assistant", "agents") over "Claude" unless the instruction is genuinely specific to one tool. Keep tool-specific sections clearly labeled if they must remain.
5. **Keeps structure readable** — use the existing heading structure as a starting point and merge new sections in logically rather than appending blindly.

## Step 4 — Write files and create symlinks

Execute in this order:

1. **Remove any existing `CLAUDE.md`** (whether a regular file or a symlink) using `rm`. Do this *before* writing `AGENTS.md`, in case it is a symlink chain that would be affected.
2. **Write `AGENTS.md`** with the unified content using the Write tool. In Case A, this is a minimal stub such as:

   ```markdown
   # Agent Instructions

   Instructions for AI coding assistants working in this repository.
   ```

3. **Create the symlink** with a relative target so it survives the repo being moved or cloned elsewhere:

   ```bash
   ln -s AGENTS.md CLAUDE.md
   ```

4. **Verify** with `ls -la AGENTS.md CLAUDE.md` and confirm the symlink points to `AGENTS.md` and `AGENTS.md` is a regular file.

## Step 5 — Version control

If the project is a git or jj repo, do **not** commit automatically. Just tell the user what changed (which files were removed, which were created, which became symlinks) so they can review and commit themselves. If CLAUDE.md was previously a tracked regular file, remind the user that the commit will show a file→symlink transition.

## Notes and edge cases

- **Never follow a symlink loop.** If you see `CLAUDE.md -> AGENTS.md -> CLAUDE.md` or similar, stop and report it — something is already broken and needs human attention.
- **Never overwrite unsaved work.** If either file has uncommitted changes (check with `git status` / `jj status`), warn the user before removing it.
- **`.gitignore` / `.jjignore`** — these files should be *tracked*, not ignored. Do not add them to ignore files.
- **Other agent files** — if you see related files like `.cursorrules`, `.github/copilot-instructions.md`, `GEMINI.md`, or `AGENT.md` (singular), mention them to the user but do not touch them unless asked. This skill is scoped to the AGENTS.md / CLAUDE.md pair.
