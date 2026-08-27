---
name: omniplugin
description: Playbook for building and maintaining omni-platform agent plugins (one repo, native installs on Claude Code, Codex, OpenCode, Hermes, Antigravity, Gemini CLI, and more). Use when creating a plugin meant for more than one platform, porting an existing plugin to a new agentic platform, reviewing a platform-port PR, releasing a multi-platform plugin, or answering how another platform's plugin/skill/hook format works.
---

# omniplugin — apply the playbook

You have the omni-platform plugin playbook staged alongside this skill. Your job: route to the right document, read it fully, and apply it — not from memory of this file, but from the docs themselves.

## 0 · Resolve the playbook root

```bash
OMNI="${ZCODE_PLUGIN_ROOT:-${CLAUDE_PLUGIN_ROOT:-${CODEX_PLUGIN_ROOT:-${OMNIPLUGIN_ROOT:-}}}}"
```

If unset (Antigravity, Hermes, and Pi set no root variable), resolve the landmark: the directory containing `.claude-plugin/plugin.json` two levels up from this skill file (`skills/omniplugin/SKILL.md` → repo root). Pi installs stage the whole repo at `~/.pi/agent/git/github.com/nagisanzenin/omniplugin`. Dev clones: `~/Documents/Github/omniplugin` or wherever the repo was cloned.

## 1 · Route by task

| Task at hand | Read (in order) |
|---|---|
| Create a NEW multi-platform plugin | `docs/01-anatomy.md` → `docs/02-portability-rules.md` → platform files for the launch targets |
| Port an existing plugin to a platform | `docs/03-adding-a-platform.md` (the phases + 12 intake questions) → `docs/platforms/<target>.md` if present, else `templates/platform-intake.md` |
| Review someone's platform-port PR | `docs/03-adding-a-platform.md` Phase 1 & 6 + `docs/05-pitfalls.md` #1–2 — re-research the target's loader from primary sources before judging the diff |
| Release / version-bump across platforms | `docs/04-maintenance.md` |
| Debug a broken platform integration | `docs/05-pitfalls.md` + the platform's crib sheet |
| "How does platform X's format work?" | `docs/platforms/<x>.md`, else `docs/platforms/landscape.md` |
| Write a per-platform install doc | `templates/INSTALL-PLATFORM.md` |
| Build an ambient/session hook | `templates/session-hook.sh` (the contract is in its header) |

## 2 · Non-negotiables while applying

1. Platform facts in these docs are **dated** — each carries "researched <date>, against <version>". Older than a month, or stakes are high → verify against the platform's current docs before relying on it, and update the crib sheet with what you find.
2. Research a target platform's actual loader from **primary sources** (schema, CLI changelog, flagship plugin) before writing or approving glue. Never port by analogy.
3. Check every new **root-level path** against every shipped platform's discovery conventions (namespace bleed).
4. Hooks: self-resolving, silent-unless-useful, degrade to silence, fail closed, `exit 0`.
5. Ship **honest status**: Verified (with platform version) vs Not-verified (with why it's harmless), per platform, in the install doc.
6. The shared core stays byte-identical across platforms — differences live in glue and install docs, never as forks of core files.

## 3 · When you learn something the playbook doesn't know

If you're working in a clone of the playbook repo: update the relevant `docs/platforms/*.md` (refresh its date/version line, keep the source URL) or add a `docs/05-pitfalls.md` entry (*what happened → the rule*, with the receipt). If you're in a plugin-cache copy, tell the user what should be upstreamed to github.com/nagisanzenin/omniplugin instead of editing the cache.
