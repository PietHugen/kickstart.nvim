<!-- init-repo:principles -->

## Principles

- docs/principles.md holds this project's standing rules (architecture, conventions,
  non-negotiables). Read it before exploring, proposing, designing or debugging.
- MUST rules are absolute. SHOULD rules are strong defaults; say so when you deviate.
- If work needs to break or change a principle, STOP and flag it to me before writing
  code. Explain the conflict, the options, and a proposed wording change.
- Never edit docs/principles.md without my explicit approval.
- If you notice a recurring pattern or decision that isn't covered, suggest adding it
  as a principle. Don't add it yourself.
- Code review checks against docs/principles.md as well as the task.

## Bugs

- Debug to root cause first (systematic-debugging), then fix with a failing test first.
- If the root cause conflicts with a principle, or shows a principle is wrong, flag it
  to me (see Principles).

## Issues

- Reference the GitLab/GitHub issue in the MR/PR description (e.g. "Closes #123").
- Claim an issue before you start on it (in OpenSpec repos: before /opsx:explore or
  /opsx:propose on it), so no other agent or colleague picks it up in parallel. A local
  branch or change directory is not a claim: others only see the issue tracker.
  - Check first (`glab issue view N --comments` / `gh issue view N --comments`). If it
    is assigned, labelled `in-progress` or has a claim comment, stop and ask me.
  - Claim it: assign the person you work for, add the `in-progress` label, and comment
    with the branch (and OpenSpec change), repo, and where the work runs (laptop or
    which sandbox). GitLab: `glab issue update N --assignee +<user> --label in-progress`,
    `glab issue note N --message "..."`. GitHub: `gh issue edit N --add-assignee <user>
    --add-label in-progress`, `gh issue comment N --body "..."`.
  - If the `in-progress` label doesn't exist yet, ask me before creating it.
  - No write access to the tracker (e.g. in a sandbox): ask me to claim it.
  - The MR/PR's "Closes #N" releases it on merge. If the work is abandoned, remove the
    label and the assignee, and comment why.

<!-- /init-repo:principles -->
