---
name: git-conventions
description: Personal Git conventions. Use when creating branches, preparing commits, splitting work across worktrees, reviewing git status, or deciding what belongs in a commit/PR.
---

# Git Conventions

Use this skill when working with branches, worktrees, commits, PR preparation, or repository hygiene.

## Working Tree Hygiene

- Start by checking `git status --short` and the current branch.
- Keep unrelated user changes out of your commits. Do not stage broad paths unless you created or intentionally modified every file included.
- Treat untracked local tool folders (`.pi/`, `.pi-subagents/`, `output/`, ad hoc artifacts) as unrelated unless the task explicitly asks for them.
- If a task needs isolation, create a dedicated worktree and branch before editing.

## Branches And Worktrees

- Use short, descriptive branches with a conventional prefix:
    - `feature/<slug>` for new behavior.
    - `fix/<slug>` for bug fixes.
    - `refactor/<slug>` for behavior-preserving structure changes.
    - `chore/<slug>` for dependency, tooling, or repository maintenance.
    - `docs/<slug>` for documentation-only changes.
- Prefer worktrees for parallel or risky work so the main checkout stays clean:

```bash
git worktree add .worktrees/<slug> -b <prefix>/<slug> HEAD
```

## Commit Scope

- Make commits cohesive: one feature, fix, or refactor per commit when practical.
- Separate generated files from source changes only when that makes review easier; keep required lockfile/migration updates with the source change that requires them.
- Include `bun.lock` when package metadata or dependencies changed.
- Include Drizzle migrations when schema changes require them.
- Do not include secrets, local env files, raw customer data, screenshots with PII, or temporary output artifacts.

## Commit Messages

Use concise Conventional Commit-style messages:

```text
feat(agents): add lead sourcer review app
fix(workflows): handle missing webhook snapshot
refactor(skills): standardize project skill loading
docs(git): add repository conventions
chore(deps): refresh lockfile
```

# Pull Request

When creating/managing a pull request:

- The title should always use conventional commit format. If the PR is for an issue, include its ID, for example `fix(ISSUE-10): handle missing webhook snapshot`.
- First section is a "Problem" of the fix/feat/refactor/chore that the PR addresses.
- Second section is the "Solution" that directly addresses how the changes are implemented to address the summary.
- Third section is the "Context" around the problem and solution. Such as domains, technologies, Linear issues, or business context.
- Fourth section the "Proof" that the changes have been implemented correctly. This could be any of the following or a combination of them: direct test cases, a screenshot, or a code review.
- Fifth section (only when relevent) the "Architecture" diagram or explanation.

Guidelines:

- Use an imperative subject under ~72 characters.
- Prefer package or app scopes such as `web`, `api`, `workflows`, `agents`, `db`, `shared`, `skills`, or `docs`.
- Mention tests in the PR/body when behavior changed or validation was manual.

## Before Handoff

1. Re-run `git status --short` and confirm only intended files are changed.
2. Run the narrowest relevant checks first.
3. If code or package metadata changed, run `rm -r bun.lock node_modules/ && bun install && bun fmt && bun check` unless the user explicitly asks not to.
4. Summarize changed files, checks run, and any uncommitted unrelated files left untouched.
