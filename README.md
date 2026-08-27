# omniplugin

**The playbook for omni-platform agent plugins — one repo, one core, native installs on every agentic platform.**

Agentic platforms are multiplying — Claude Code, OpenAI Codex, OpenCode, Hermes, Antigravity, Gemini CLI, ZCode, and next quarter's three new ones — and each has its own plugin format, discovery model, hook events, and marketplace. The naive answer is a port per platform, which turns every bug fix into N pull requests. The answer that works is the **omni-repo**: one repository whose portable core (Agent-Skills-standard `skills/` + a zero-dependency CLI engine + one state home) is shared verbatim, wrapped in the thinnest possible per-platform glue.

This playbook is that pattern, extracted from a plugin that actually shipped it: [**engram**](https://github.com/nagisanzenin/engram) runs natively on **Claude Code, OpenAI Codex, OpenCode, Hermes Agent, Google Antigravity, OpenClaw, Pi, DeepSeek Harness, and ZCode** — same skills, same engine, same user state, on all nine. The sixth is a chat gateway rather than a coding tool, which proved the pattern generalises past the terminal; the seventh reads the Agent Skills standard natively, which proved how cheap a port becomes when a platform meets the core where it already lives; the eighth shipped with zero adapter code on nothing but stock surfaces; and the ninth speaks the Claude dialect with sharp exceptions its runner code gave up after an hour of reading — each find flowing straight back into this playbook. Every rule in here carries a receipt: the real bug, review round, or user report that taught it. No rules without receipts.

## The doctrine, in ten lines

1. **One portable core, thin glue.** Skills + a deterministic CLI engine, shared byte-identical; platforms get manifests and adapters, never forks.
2. **The shell is the only universal ABI.** The engine is a stdlib-only CLI — every platform can shell out; almost none share a plugin API.
3. **Skills are the portable unit.** Agent Skills `SKILL.md` is the closest thing to a cross-platform standard; write behavior there, once.
4. **One state home.** Learn/work in one tool, continue in another — that's what makes it *omni* rather than N parallel installs.
5. **Resolve roots by waterfall, then landmark.** Env vars where platforms set them; the directory containing your manifest where they don't.
6. **Hooks degrade to silence,** self-resolve, fail closed, and always `exit 0`. An ambient feature must never break a session.
7. **Preserve invariants, not mechanisms.** Your guarantees survive porting; the mechanism enforcing them won't. Map one to the other per platform.
8. **Research loaders, never port by analogy.** Schema, CLI changelog, flagship plugin — before one line of glue.
9. **Check every root path against every platform.** Namespaces overlap; a file added for platform N can change behavior on platform M.
10. **Verified-live or say so.** Every platform doc carries Verified / Not-verified, item by item, forever.

## The map

| Read | For |
|---|---|
| [docs/01-anatomy.md](docs/01-anatomy.md) | The omni-repo shape: core vs glue, the nine-platform comparison table, the L0–L4 integration ladder |
| [docs/02-portability-rules.md](docs/02-portability-rules.md) | The ten engineering rules that make one repo run everywhere — each with code and its receipt |
| [docs/03-adding-a-platform.md](docs/03-adding-a-platform.md) | **The checklist** — the recurring operation, phase by phase, with the 17 intake questions |
| [docs/04-maintenance.md](docs/04-maintenance.md) | Operating the matrix: the release protocol pattern, version-grep, honest status, community as your test fleet |
| [docs/05-pitfalls.md](docs/05-pitfalls.md) | Field notes: twenty-three real failures → twenty-three rules |
| [docs/platforms/](docs/platforms/) | Crib sheets: [Claude Code](docs/platforms/claude-code.md) · [Codex](docs/platforms/codex.md) · [OpenCode](docs/platforms/opencode.md) · [Hermes](docs/platforms/hermes.md) · [Antigravity](docs/platforms/antigravity.md) · [OpenClaw](docs/platforms/openclaw.md) · [Pi](docs/platforms/pi.md) · [DSH](docs/platforms/dsh.md) · [ZCode](docs/platforms/zcode.md) · [the wider landscape](docs/platforms/landscape.md) |
| [templates/](templates/) | [platform-intake.md](templates/platform-intake.md) (the 17 questions) · [INSTALL-PLATFORM.md](templates/INSTALL-PLATFORM.md) (install-doc skeleton) · [session-hook.sh](templates/session-hook.sh) (the reference ambient hook) |

Working with an agent? Point it at [CLAUDE.md](CLAUDE.md) — it routes by task.

## Install it — yes, as a plugin

A playbook about omni-platform plugins had better be one. The repo ships [`skills/omniplugin/SKILL.md`](skills/omniplugin/SKILL.md): install it and your agent consults the playbook on its own whenever multi-platform plugin work comes up (creating, porting, reviewing a port PR, releasing).

| Platform | Install |
|---|---|
| **Claude Code** | `claude plugin marketplace add nagisanzenin/omniplugin` then `claude plugin install omniplugin@omniplugin` |
| **OpenAI Codex** | `codex plugin marketplace add nagisanzenin/omniplugin` then `codex plugin add omniplugin@omniplugin` |
| **Antigravity** | `agy plugin install https://github.com/nagisanzenin/omniplugin` |
| **Hermes Agent** | `git clone https://github.com/nagisanzenin/omniplugin ~/omniplugin`, then add `~/omniplugin/skills` to `skills.external_dirs` in `~/.hermes/config.yaml` — **clone, not the hub installer** (the skill Reads `docs/`, which referenced-files-only staging would sever — [rule R8](docs/02-portability-rules.md)) |
| **Pi** | `pi install git:github.com/nagisanzenin/omniplugin` — no package.json here, so pi's conventional-dir scan picks up `skills/` from the clone, and the whole repo (with `docs/`) comes along |
| **ZCode** | Settings → Plugin Management → Discover → `+` add `github.com/nagisanzenin/omniplugin` — installs straight from this repo's Claude catalog |
| **Anything else that reads `SKILL.md`** | clone the repo and point the platform at `skills/` — the whole repo must come along, because the skill routes into `docs/` |

Honest status, per the playbook's own rule: **the Pi route is verified live** (pi 0.83.0 discovered the skill from a plain clone of this repo, with the description intact in the system prompt — payload-captured, 2026-08-04). **The other routes are not verified live in this repo yet.** The Claude Code layout is the pattern engram ships and runs daily; the Codex manifests mirror engram's (which shipped without a live-binary check and degrade harmlessly); the Antigravity manifest is exactly the format its own schema and the engram PR #8 review established. The skill is plain markdown routing to plain markdown — the worst failure mode is a skill that doesn't register. Install it and tell me what you see; the doc upgrades when you do. The ZCode route rides the same Claude-layout compatibility this repo already ships — no functional files were added for it; see [docs/platforms/zcode.md](docs/platforms/zcode.md) for what was verified against the runtime loader itself. Dogfooding receipts: the namespace-bleed check for the new root paths (`skills/`, `plugin.json`, `.agents/`) is [rule R9](docs/02-portability-rules.md) applied to this very repo, and version `0.1.0` moves in lockstep across both manifests per [04 · Maintenance](docs/04-maintenance.md).

## The case study in one table

engram v1.0.8 → v1.15.1 (2026-07-19 → 2026-08-27) — what "one core, nine platforms" concretely costs and buys:

| Platform | Glue that was needed | Rung |
|---|---|---|
| Claude Code | 2 JSON manifests (the conventions the core is written in) | L4 |
| OpenAI Codex | mirrored manifest + 3 TOML agent ports + install script | L2 (unverified against live binary; honest-status'd) |
| OpenCode | the one real adapter: TS self-extract + config bridge + deterministic updater (88 tests) | L4 |
| Hermes Agent | zero repo changes for skills (config entries) + one dual-mode hook variant | L3 (verified live, wire-level) |
| Antigravity | a 3-line manifest — discovery does the rest | L1, in review |
| OpenClaw | **zero new manifests** — it reads the Codex and Claude ones already there; one hook pack + one shared-doc page | L3 (skills, hook, and isolated-subagent grading verified live on 2026.7.1-2) |
| Pi | one `pi` key in package.json + one extension file (env export + nudge) + three prompt templates | L4 (v1.11.1, 2026-08-04 — transport verified 20/20 by a committed payload-capture harness, on two pi version lines) |
| DeepSeek Harness | zero adapter code — clone into `~/.agents`, three symlinks, a JSON-emitting hook wrapper for its Claude-hook bridge | thinnest-port class (v1.13.0, 2026-08-16; nudge chain keyless-verified live) |
| **ZCode** | one manifest + a format switch inside the EXISTING shared hook script (its runner discards plain stdout and logs non-conforming runs failed) + waterfall candidate nine | L2-by-construction (v1.15.0/v1.15.1, 2026-08-27 — verified against the shipped runtime loader; live tutoring session owed) |

Shared byte-identical across all nine: `skills/`, `agents/*.md` (as prompt source), `scripts/engram.py` (315 selftest checks at v1.15, same count everywhere), one state dir.

## Scope, honestly

This is distilled from **one plugin shipping nine platforms** (plus a researched survey of the rest of the landscape). It is a playbook, not a spec: platform loaders drift monthly, so every platform fact here is dated and versioned, and [CLAUDE.md](CLAUDE.md) tells future maintainers how to keep it true. When this playbook and a platform's current docs disagree, the platform docs win — then fix the playbook.

## More from the same workshop

- **[engram](https://github.com/nagisanzenin/engram)** — the reference omni-plugin: evidence-based learning with blind-graded recall and FSRS scheduling, on nine platforms.
- **[effortmining](https://github.com/nagisanzenin/effortmining)** · **[idiolect](https://github.com/nagisanzenin/idiolect)** · **[production-grade](https://github.com/nagisanzenin/production-grade)** · **[less](https://github.com/nagisanzenin/less)** — Claude Code plugins sharing the same habit: deterministic cores, receipts, and honest numbers.

---

<sub>MIT · Built by extracting what shipping actually taught, so the next plugin starts from rules instead of re-earning them.</sub>
