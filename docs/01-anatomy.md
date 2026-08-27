# 01 · Anatomy of an omni-platform plugin

An omni-platform plugin is **one repository** that installs as a native-feeling plugin on many agentic platforms at once. Not a monorepo of ports — one core, shared verbatim, plus the thinnest possible glue per platform.

The reference implementation is [engram](https://github.com/nagisanzenin/engram) (v1.15): one codebase running on nine clients — Claude Code, OpenAI Codex, OpenCode (v1 + v2 beta), Hermes Agent, Google Antigravity, OpenClaw, Pi, DeepSeek Harness, and ZCode. Everything in this playbook was extracted from shipping it.

## The shape

```
your-plugin/
│
│  ── THE PORTABLE CORE (shared verbatim by every platform) ──
├── skills/                    # Agent Skills standard SKILL.md — the behavior
│   └── _shared/               # prose contracts the skills Read at runtime
├── agents/                    # subagent prompts as markdown (Claude format = source of truth)
├── scripts/engine.py          # deterministic core: state, math, receipts — stdlib-only CLI
├── hooks/session-start.sh     # ambient nudge — self-resolving, degrades to silence
│
│  ── PER-PLATFORM GLUE (each platform reads only its own) ──
├── .claude-plugin/            # Claude Code: plugin.json + marketplace.json
├── .codex-plugin/             # Codex: plugin.json (manifest maps skills/hooks)
├── .agents/plugins/           # Codex marketplace catalog
├── codex/agents/*.toml        # Codex: TOML ports of the subagents
├── .opencode/*.ts             # OpenCode: TS adapter (self-extract + config bridge)
├── package.json               # OpenCode: the npm face of the same repo
├── plugin.json                # Antigravity: {name, description} — discovery is by convention
├── hooks/session-start-<x>.sh # hook adapters where the event/protocol differs
│
│  ── PER-PLATFORM DOCS ──
├── INSTALL-<PLATFORM>.md      # glue + honest status, one per non-native platform
└── README.md                  # the support matrix is the front door
```

**The layering rule:** glue may read the core; the core never knows the glue exists. `engine.py` contains zero platform-specific code. The skills reference platform env vars only inside one resolution waterfall (see [02 · Portability rules](02-portability-rules.md), R1).

## The three components of the core

1. **Prose contracts** — `skills/*/SKILL.md` plus `skills/_shared/`. The Agent Skills `SKILL.md` format is the closest thing to a cross-platform standard: Claude Code, Codex, OpenCode, Hermes, and Antigravity all either read it natively or can be pointed at a directory of them. Behavior lives here, once.
2. **A deterministic engine as a CLI** — everything the model must never improvise (dates, math, state mutation, receipts) lives in one dependency-free script invoked via shell. Every agentic platform can run `python3 script.py args`; almost none share a plugin API. *The shell is the only universal ABI.* Engram's engine is stdlib-only Python with zero network code (AST-verified by its own selftest) — which also means the trust story ("nothing leaves your machine") travels to every platform unchanged.
3. **One state home** — a single directory (`~/.claude/learning`, overridable via `ENGRAM_HOME`) written by the engine only. This is what makes it *omni* rather than five parallel installs: start work in Claude Code, continue in OpenCode, get the nudge in Hermes — same schedule, same receipts.

## The glue, platform by platform (v1.15 refresh of the v1.0.8 original; researched 2026-07-19 → 2026-08-27)

| | Claude Code | Codex | OpenCode | Hermes Agent | Antigravity | OpenClaw | Pi | DeepSeek Harness | ZCode |
|---|---|---|---|---|---|---|---|---|---|
| **Manifest** | `.claude-plugin/plugin.json` + `marketplace.json` | `.codex-plugin/plugin.json` (+ `.agents/plugins/marketplace.json`) | `package.json` + TS entry point | none — entries in user's `config.yaml` | root `plugin.json`: `{name, description}` only, `additionalProperties: false` | none of its own — reads the **Codex** manifest as a "bundle" (see pitfall 12) | `pi` key in `package.json` (`{extensions, skills, prompts, themes}`); conventional dirs when absent | none — native discovery from `~/.agents/skills` (+ optional bridge-patch block) | `.zcode-plugin/plugin.json` — priority over the compat names it also accepts |
| **Skill discovery** | `skills/` auto-discovered | manifest `"skills"` field | self-extract to config dir + `cfg.skills.paths` bridge | `skills.external_dirs` in config.yaml | `skills/` by directory convention | bundle skill roots load as native skills; symlinked into `plugin-skills/` | Agent Skills standard, recursive `SKILL.md` scan; listed as `<available_skills>` XML | `SKILL.md` bundles live-watched in `~/.agents/skills` | convention dirs + user scopes (`~/.zcode/skills` → legacy `~/.agents/skills`); first same-named wins |
| **Command spelling** | `/learn` | `$learn` (skills invoked by `$name`) | `/learn` (generated `command/` files) | `/review` `/coach`; `/skill learn` (collision with built-in) | `/learn` (auto-derived from skills) | `/learn` — on every chat surface (Discord, Telegram, WhatsApp, …) | `/learn` (prompt template) + `/skill:learn` native | `/skill learn` (or `/study`) · `/review` · `/coach` | `/learn` (namespaced `/engram:learn` on some builds) |
| **Subagents** | `agents/*.md`, auto-delegated | `codex/agents/*.toml`, **explicit invocation only** | `agents/*.md` transformed at extract (`mode: subagent`) | `delegate_task` with prompt file passed as context | `agents/` convention; frontmatter keys differ (unverified) | **`agents/` not mapped by any bundle format** → `sessions_spawn` with `context:"isolated"`, child reads the agent file | **none by design** → fresh `pi -p` process, env-guarded, receipt via file (R6) | `subagent` tool, fresh context only — **never `subagent_fork`** for a grader | generic Agent child, fresh by construction → reads the agent file; declared plugin agents diagnostic-only on 3.9.2 |
| **Ambient hook** | `hooks/hooks.json` → SessionStart | same hooks.json (unverified against live binary) | `shell.env` + `experimental.chat.system.transform` + `session.idle` toast | `pre_llm_call` in config.yaml (JSON protocol) | root `hooks.json`, own schema; no session-start equivalent found | hook pack `hooks/<name>/HOOK.md` + `handler.js` on `command:new`/`command:reset`; **needs `hooks.internal.enabled`** (pitfall 15) | extension: `session_start` (**awaited** — fire-and-forget only, pitfall 19) + `before_agent_start` message injection | Claude-hook bridge — consumes JSON `additionalContext` only; wrapper script emits that shape | shared hooks.json consumed but **stdout parsed as JSON-only** — non-conforming runs logged failed → format-switch inside ONE script (+ `compact` matcher; pitfalls 22–23) |
| **Root env var** | `CLAUDE_PLUGIN_ROOT` | `CODEX_PLUGIN_ROOT` | `OPENCODE_PLUGIN_ROOT` (the adapter sets it itself) | none → `ENGRAM_ROOT` in `~/.hermes/.env` | none → landmark-file fallback | none → `${OPENCLAW_STATE_DIR:-~/.openclaw}/extensions/<name>` | none → the extension **sets it itself** in `process.env`; bash tool inherits | none → clone at `~/.agents/engram` (waterfall's LAST candidate) | **both** `ZCODE_PLUGIN_ROOT` and legacy `CLAUDE_PLUGIN_ROOT` — same value, so its own var leads waterfalls |
| **Install** | `plugin marketplace add` + `plugin install` | `codex plugin marketplace add` + `plugin add` | npm name or `git+https://…` in `opencode.json` | `git clone` + config entries (never the hub installer) | `agy plugin install <git-url>` (stages entire repo) | `openclaw plugins install <name> --marketplace <gh-source>` — reads the **Claude** marketplace.json | `pi install git:github.com/<o>/<r>` (also `npm:`, local paths, `-e` ephemeral) | `git clone <repo> ~/.agents/<name>` + 3 symlinks into `~/.agents/skills` | Settings → Plugin Management → Discover → add `<github-repo>` — **reads the Claude marketplace.json directly** |
| **Update** | `plugin marketplace update` + `plugin update` | ditto | version-bump-triggered `/engram-update` deterministic tool | `git pull` | reinstall | `openclaw plugins update` (npm installs) or reinstall `--force` | `pi update` (tracks default branch; pinned refs skipped) | `git pull` | marketplace refresh + reinstall (clone route: `git pull`) |
| **Staging model** | plugin cache, full repo | plugin cache (assumed) | **npm cache — NOT a config dir** (hence the self-extract) | your clone, in place | `~/.gemini/antigravity-cli/plugins/<name>/`, full repo | `$OPENCLAW_STATE_DIR/extensions/<name>/`, full repo | `~/.pi/agent/git/<host>/<path>`, full clone (+ `npm install` if package.json exists) | your clone, in place | plugin cache, full repo |

Every column difference in that table is a lesson someone paid for. The per-platform crib sheets in [docs/platforms/](platforms/) carry the details and the sources.

## The integration-depth ladder

Not every platform gets every feature on day one. Think in rungs, ship the lowest rung first, climb as verified:

- **L0 — skills + engine, manual.** Clone the repo, point the platform at `skills/`, shell out to the engine. This rung works on *anything* that can read a directory of SKILL.md files — it is the universal fallback, and it must always work (engram's "Route B").
- **L1 — commands registered.** The platform surfaces `/yourcommand` natively (marketplace install, auto-derived, or generated).
- **L2 — ambient.** A hook injects your nudge/policy at session start with zero user action. This is the rung that makes a plugin feel alive, and it is the hardest to port (see R7).
- **L3 — subagents.** Platform-native isolated contexts preserving your separation-of-powers invariants.
- **L4 — native update flow.** The platform's own update mechanism delivers new versions without clobbering user edits.

Engram's rungs today: Claude Code L4 · OpenCode L4 · Pi L4 · ZCode L2-by-construction (ambient verified by an execution matrix over the real runner; update flow unverified) · OpenClaw L3 · Hermes L3 (L2 wire-level) · DSH L0-as-doctrine (stock surfaces only, thinnest port class) · Codex L2-with-caveats · Antigravity L1 pending review. Publishing your rung per platform *is* the honest-status discipline ([04 · Maintenance](04-maintenance.md)).

## What makes this worth it

One release protocol, one engine test suite, one set of skills to improve — and every platform inherits each improvement on its next update. The alternative (per-platform forks) turns every bug fix into N pull requests and every behavioral drift into a support ticket. The omni-repo costs you: manifest sprawl at the repo root, a version-bump checklist that grows per platform, and namespace-bleed risk (a file added for platform N can change behavior on platform M — the sharpest recurring trap in this playbook, see [05 · Pitfalls](05-pitfalls.md) #2).
