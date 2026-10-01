---
description: Code review of the current uncommitted changes (git diff)
argument-hint: "[path or focus, optional]"
allowed-tools: Bash(git diff:*), Bash(git status:*), Bash(git log:*), Read, Grep, Glob
---

Review the uncommitted changes in this repository.

## Current state

- Branch and changed files: !`git status --short --branch`
- Size of the change: !`git diff HEAD --stat`
- Recent commits, for the repo's conventions: !`git log --oneline -8`

Extra instructions from me (a path to limit the review to, or what to focus on): $ARGUMENTS

## What to review

1. Get the change with `git diff HEAD` (staged and unstaged together). If I
   gave a path above, limit the diff to it. Untracked files (`??` in the status)
   are part of the change too: read them in full.
2. Do not review the diff in isolation. For every changed function, open the
   file and read the code around it, and look up its callers and the things it
   calls when the change could affect them.
3. If there is nothing to review (clean tree), say so and stop.

## What to look for

In this order of importance:

1. **Bugs**: wrong logic, unhandled `None`/empty/error cases, off-by-one,
   wrong variable, broken edge cases, race conditions, resources not released,
   a caller that was not updated after a signature or behaviour change.
2. **Security and data**: secrets or credentials in the diff, injection,
   missing authorisation or tenant checks, sensitive data written to logs,
   destructive migrations.
3. **Consistency with the rest of the repo**: code that solves something
   differently from how the surrounding code already does it, duplicated logic
   that exists elsewhere, files put in the wrong place for this project's
   structure.
4. **Leftovers**: debug prints, commented-out code, TODOs, unused imports or
   variables, files that look accidentally included.
5. **Tests**: changed behaviour with no test changed or added. Name the case
   that is not covered.

Do not report formatting or style preferences that a linter handles, and do
not pad the review with praise or with remarks that need no action.

## Rules

- This is a review only. Do not edit, create or delete files, and do not run
  anything that changes the repository.
- Report only what you checked in the code. If something looks wrong but you
  could not confirm it, put it under "To check" and say what is uncertain.
- Every finding points to `path:line`, says what is wrong, what happens because
  of it (concrete input or situation), and how to fix it in one or two
  sentences.

## Output

Answer in the language I use in this conversation.

1. One or two sentences: what the change does and whether it is safe to commit
   as is.
2. Findings grouped as **Must fix**, **Should fix**, **To check**, most
   serious first. Leave out a group that is empty.
3. If there are no findings, say that plainly, and list what you checked.
