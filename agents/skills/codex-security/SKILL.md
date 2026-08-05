---
name: codex-security
description: Use OpenAI's Codex Security CLI to scan repositories, review working-tree or branch diffs, validate findings, compare scans, export reports, or propose and apply vulnerability fixes. Trigger for security audits, vulnerability assessment, secure code review, pre-commit security checks, SARIF export, threat-informed deep scans, or requests to validate or patch a reported security issue.
---

# Codex Security

Use `npx @openai/codex-security` as the security engine. Keep scans read-only by default, preserve the CLI's coverage caveats, and require explicit user authorization before applying a generated patch.

## Preflight

1. Resolve the repository root and requested scope.
2. Read the repository's `SECURITY.md` and relevant agent instructions when present.
3. Check `git status --short`; preserve unrelated changes.
4. Require a supported Node.js release and Python 3.10 or later. See [CLI reference](references/cli.md).
5. Check authentication with `npx @openai/codex-security login status`. If authentication is missing, ask the user to sign in; never print, persist, or request an API key in chat.
6. Put scan output outside the scanned repository unless the user provides a safe output directory. Treat findings and source excerpts as potentially sensitive.

## Choose The Scan

- Entire repository or scoped directories: use `scan <repo>` with one or more `--path` values when needed.
- Staged and unstaged changes: use `scan <repo> --working-tree`.
- Branch or commit comparison: use `scan <repo> --diff <base>`.
- Deep, multi-pass discovery: add `--mode deep` only when the user asks for a deep audit or the risk and repository size justify its additional time and cost.
- CI policy: add `--fail-on-severity <level>` and structured output when the user is configuring automation.

Start with the narrowest scan that answers the request. Use `--dry-run` when command resolution, scope, model access, or output placement is uncertain.

## Review Results

1. Report the scan ID, mode, reviewed scope, report path, severity counts, and exclusions.
2. Never claim complete coverage when the CLI reports an incomplete or interrupted scan.
3. Validate high-impact or ambiguous findings before recommending remediation.
4. Distinguish exploitable findings from defense-in-depth improvements and false positives.
5. Do not paste secrets, raw credentials, private source excerpts, or full sensitive reports into chat.

## Remediation

- Treat `validate` as read-only analysis.
- Before `patch`, confirm the exact finding, check for unrelated working-tree changes, and get explicit user authorization to modify code.
- After patching, inspect the diff, run focused tests and security checks, and explain any residual risk.
- Never automatically publish findings, create advisories, install hooks, or modify CI unless the user asks.

## Commands

Read [CLI reference](references/cli.md) for current command shapes covering authentication, standard/deep/diff scans, history, comparison, validation, patching, export, and CI usage. Prefer `npx @openai/codex-security <command> --help` whenever installed behavior differs from the reference.
