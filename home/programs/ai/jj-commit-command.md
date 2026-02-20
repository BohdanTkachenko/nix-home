# Task: Generate a Jujutsu commit based on diff and an optional user input.

## Context

Current commit message was extracted to: %!`{{JJ_COMMIT_MSG}} write {{TMP_DIR}}`!%

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

**IMPORTANT: NEVER ask user for confirmation. NEVER use `jj describe -m`. You MUST follow these exact steps:**

1. Generate the new commit message based on the diff, log and any additional user instructions.
2. **Read the temp file first** (path shown above, required before writing).
3. **Write the commit message** to the temp file (this overwrites the old message, allowing user to see the diff).
4. Apply the message and cleanup: `{{JJ_COMMIT_MSG}} apply <TEMP_FILE>`
5. Create a new commit: `jj new`

## Optional context provided by the user
