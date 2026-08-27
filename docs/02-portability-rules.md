# 02 · Portability rules

The engineering rules that let one repo run natively everywhere. Each rule carries its receipt — the real event in [engram](https://github.com/nagisanzenin/engram)'s history that made it a rule. None of them is theoretical.

---

## R1 · Resolve your root by waterfall, then by landmark

Skills need to find the engine. Every platform stages the repo somewhere different, and only some set an env var telling you where. The pattern (verbatim from engram's skills):

```bash
# Resolve the engine: plugin root on OpenCode / Claude Code / Codex, else a dev clone.
ENGINE="${OPENCODE_PLUGIN_ROOT:-${CLAUDE_PLUGIN_ROOT:-${CODEX_PLUGIN_ROOT:-$PLUGIN_ROOT_OVERRIDE}}}/scripts/engine.py"
```

…and when **no** variable is set (Antigravity and Hermes set none), fall back to a **landmark file**: walk to the directory containing `.claude-plugin/plugin.json` and use that as root. The landmark works because platforms that stage the *entire repo* (Antigravity: *"copy the entire plugin directory"*) carry your other platforms' manifests along for free.

Give users a manual override (`ENGRAM_ROOT`-style env var) as the last resort and the dev-clone path.

Two refinements the seventh platform earned:

- **If the platform runs your code in-process, export the root var yourself.** Pi loads extensions into its own process, and both its exec API and its bash tool spawn children from `process.env` — so engram's pi extension sets `process.env.ENGRAM_ROOT` at load, and every shell the skills run inherits it. Zero skill changes; the OpenCode `shell.env` trick, generalized.
- **Static install paths are pure fallbacks — order them LAST.** The waterfall also probes hardcoded install locations (`~/.openclaw/extensions/…`, `~/.pi/agent/git/…`) for sessions where no variable survived. A live pi session never needs its static entry (the env export wins earlier), but a user who installed on pi *and* uses Antigravity would have had the pi clone's engine silently shadow the Antigravity install when the pi path sat mid-list. Reviewers moved it to the end: a fallback that can never shadow another platform's resolution costs nothing; one that can is version skew waiting silently.

**Receipt:** the Antigravity port (PR #8) survives *only* because of the landmark fallback — AG sets no root variable at all. The Hermes install exports `ENGRAM_ROOT` via `~/.hermes/.env` because Hermes loads that file into its process and terminal subprocesses inherit it. The pi ordering hazard was caught in engram v1.11.0's pre-release review (shipped reordered).
**And the ninth port sharpened it:** ZCode exports its root var under TWO names at once (`ZCODE_PLUGIN_ROOT` and the legacy `CLAUDE_PLUGIN_ROOT`, same value). Platforms that self-identify through env-sniffing must test their OWN variable first and treat presence — never uniqueness — as the signal; and a new platform's variable leads its waterfall so no clone route or sibling install can outrank the running host. (engram v1.15: order pinned by test.)


## R2 · Hooks self-resolve and degrade to silence

An ambient hook must never break a session — on any platform, under any failure. The contract, from `hooks/session-start.sh`:

```bash
set -u
command -v python3 >/dev/null 2>&1 || exit 0        # missing runtime → silence
ROOT="${CLAUDE_PLUGIN_ROOT:-${CODEX_PLUGIN_ROOT:-}}"
if [ -z "$ROOT" ] || [ ! -f "$ROOT/scripts/engine.py" ]; then
  ROOT="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")/.." 2>/dev/null && pwd)"
fi                                                   # env unset → resolve from own location
[ -f "$ROOT/scripts/engine.py" ] || exit 0           # still lost → silence
python3 "$ROOT/scripts/engine.py" session-start 2>/dev/null || true
exit 0                                               # never a nonzero exit
```

Three properties: **self-resolving** (works from any staging path), **silent when nothing to say** (prints nothing unless there's a nudge), **degrades to silence on every failure** (never to an error, never to repetition).

And where the platform calls the hook *per LLM call* instead of per session (Hermes `pre_llm_call`), dedupe **fail-closed**: if you can't determine the session, nudge at most once per *process* — never once per call.

**Receipt:** engram's brand-new Hermes hook reached pre-release review failing open two independent ways — an empty `session_id` bypassed the once-per-session guard, and a misplaced `2>/dev/null` made an unwritable TMPDIR re-nudge on *every* LLM call. The hook whose contract is "ambient, never nagging" shipped to review as a per-call nagger. Fixed fail-closed, plus a 9-case failure battery. Write the battery *with* the hook.

## R3 · The engine is a zero-dependency CLI

Everything deterministic (state, dates, math, receipts) lives in one script with **no dependencies** and **no network code**, invoked as `python3 engine.py <cmd>`. Reasons, in order:

1. **The shell is the only universal ABI.** No platform shares a plugin API; all of them can run a subprocess.
2. **No install step means no per-platform install failures.** Eight of engram's nine platforms need zero `pip`/`npm` for the engine.
3. **The trust story travels.** "Stdlib-only, zero network code, AST-verified by the selftest" is checkable on every platform identically — `python3 scripts/engine.py selftest` is the same 214 checks everywhere, and doubles as the universal install-verification command.

Corollary: **never put user free-text on the command line.** Cross-platform means cross-shell; productions/goals reach the engine via file or stdin (`--file`, `--json -`), or a stray `'` or `$(…)` in user text becomes an injection hole on someone's machine.

## R4 · One state home, engine-owned, env-overridable

All platforms read and write the same state directory, and only the engine touches it. Document where that is per *execution host*: on Hermes, state lives on whatever host runs the terminal backend (local/Docker/SSH/Modal), which changes what "shared schedule" means. On Codex, a state dir outside the workspace-write sandbox triggers approval prompts — say so and offer the env override.

**Receipt:** engram's cross-tool continuity ("learn in one tool, review in another, same schedule") is its quietest killer feature, and it costs exactly one rule: no platform adapter ever caches or mirrors state.

## R5 · Generic names collide somewhere — plan the escape hatch

If your commands have good names (`/learn`, `/review`, `/sync`…), some platform already uses one. Handle it as product design, not as a bug:

- Detect what the platform does on collision (Hermes detects and skips auto-registration, printing an alternative).
- Ship the escape hatch (`/skill learn` works; an optional `/study` bundle aliases it).
- **Rewrite your own output**: any nudge or prose that says `/learn` must be rewritten per platform (`sed 's|/learn|/skill learn|g'` in the Hermes hook) — otherwise your plugin instructs users to invoke the *platform's* feature.
- Put the per-platform spelling in the README matrix (`/learn` vs `$learn` vs `/skill learn`).

**Receipt:** `/learn` is Hermes' own built-in (it authors new skills). The collision was found in research, handled in the install doc, and the hook rewrites its own nudge text. A v1.0.5 review still caught the cron path delivering the un-rewritten `/learn` — the rewrite must live in *every* output path.

## R6 · Preserve invariants, not mechanisms

Your plugin's guarantees must survive porting; the mechanism that enforces them will not. Name each invariant, then map it per platform. Engram's core invariant — *the grader never sees the lesson* — rides four different mechanisms:

| Platform | Mechanism | Trigger |
|---|---|---|
| Claude Code | `agents/engram-assessor.md`, fresh context | auto-delegated ("MUST BE USED") |
| Codex | TOML agent port | **explicit**: `$engram-assessor, grade these: …` |
| OpenCode | agent transformed at extract (`mode: subagent`) | platform routing |
| Hermes | `delegate_task` — child starts with zero parent history | explicit, prompt file passed as `context` |
| OpenClaw | `sessions_spawn` with `context: "isolated"` — clean child transcript | explicit, task text points at the agent file |
| Pi | **a fresh `pi -p` process** (`--no-session --no-skills --no-context-files`, own-extension inert via env guard + `ctx.hasUI`) | explicit, bash tool spawns the child; receipt returns by file |
| ZCode | generic Agent tool child starts fresh by construction → instructed to Read the agent definition file; graded items pass by file path. Declared plugin agents register diagnostic-only on 3.9.2, so nothing branches on named types |

The blindness is identical everywhere; only the trigger varies. When a platform can't host the mechanism at all, **degrade and say so** (Antigravity: assessor spawnability unverified → the README callout must carry the caveat, because the blind grading is load-bearing).

**Receipt:** the Codex port keeps separation-of-powers with a manual trigger, and INSTALL-CODEX.md explains exactly what changed and what didn't. Nobody has to guess whether the port weakened the guarantee.

## R7 · The ambient surface is the port that matters

A plugin should improve the session **by being installed** — the slash command is the precision path, not the primary one. That means the ambient nudge (session-start context injection) is the feature to fight for on every platform, and it's always the least standardized surface:

| Platform | Ambient mechanism |
|---|---|
| Claude Code / Codex | `hooks.json` → SessionStart (matcher `startup\|resume\|clear`) |
| OpenCode | `experimental.chat.system.transform` (+ `session.idle` toast for updates) |
| Hermes | `pre_llm_call` hook, JSON-in/JSON-out, `{"context": "…"}` — or a **no-agent cron** delivering plain stdout to Telegram/Discord at zero LLM cost |
| Antigravity | no session-start equivalent found (as of 2026-07-18) → shipped without, README says so |
| OpenClaw | internal hook pack on `command:new`/`command:reset` — behind a **global enable flag** (`hooks.internal.enabled`), which belongs in the install steps (pitfall #15) |
| Pi | extension: `session_start` fires a **fire-and-forget** probe (the host awaits these handlers — pitfall #19); `before_agent_start` injects the text as a user-role message with the first prompt; inert when `ctx.hasUI` is false or the child env guard is set |
| DeepSeek Harness | Claude-hook bridge consumes JSON only — a wrapper emits `hookSpecificOutput.additionalContext` (plain stdout unread) |
| ZCode | same shared hooks.json, but the runner parses **only JSON** and logs non-conforming stdout as failed → one shared script switches format on `$ZCODE_PLUGIN_ROOT` (or forced `ENGRAM_HOOK_FORMAT=json`); matcher carries `compact` |

Two disciplines: the nudge is **silent unless useful** (prints nothing when nothing is due — "ambient, never nagging"), and its absence on a platform is a *documented caveat*, not a silent gap.

## R8 · Ship prose contracts as files the skills Read — and know your installer's copy semantics

Shared behavior prose (`skills/_shared/dialogue-grammar.md`-style contracts) is read by skills at runtime, so it ports for free **only if the platform's installer actually copies it**. Installers differ in what they stage:

- Full-repo staging (Claude Code, Antigravity, OpenCode-from-git): everything arrives.
- **Referenced-files-only** staging (Hermes' hub installer: *"unreferenced repository files are not copied"*): shared dirs and the engine get severed.

**Receipt:** engram's Hermes doc mandates clone + `skills.external_dirs` and explicitly warns against `hermes skills install` — hub-installed copies would be skills with no engine. Research the staging model *before* writing the install doc ([03 · Adding a platform](03-adding-a-platform.md), question 7).

## R9 · Check every root path against every platform's conventions

Platforms discover by scanning conventional paths at the repo root — and their namespaces overlap. A file added *for* platform N can change behavior *on* platform M.

**Receipt (the sharpest one in this playbook):** the Antigravity PR added a `commands/` directory for AG. AG has **no `commands/` concept** — nothing there would read it. But **Claude Code auto-discovers a root `commands/` dir with no manifest declaration** — so the PR, as written, would have shipped a stray `/engram:review-loop` to every existing Claude Code user on their next update, while its `learn`/`coach` stubs were silently shadowed by the same-named skills (skill takes precedence over command). One directory, zero effect on the target platform, regression on a shipped one.

Before adding any root-level file or directory, ask: *which other platforms scan this name, and what will they do with it?*

## R10 · The lowest rung must always work

Design so L0 — clone the repo, point anything at `skills/`, shell to the engine — carries the complete core loop with zero plugin machinery. This is your fallback when a platform's plugin system is undocumented, unverified, or broken, and it's what makes "unverified against a live binary" shippable at all.

**Receipt:** INSTALL-CODEX.md ships Route A (plugin) *and* Route B (skills only), with the honest note that Route A was built without a live Codex binary and Route B "is the robust fallback — the skills are the portable core and carry the whole learning loop."
