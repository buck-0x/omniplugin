# ZCode

> Status in engram: **L2-by-construction — ninth platform, shipped v1.15.0 + same-hour §7.5 patch v1.15.1 (2026-08-27).** Thinnest port alongside dsh: one manifest, a **format switch inside the existing shared hook script**, one waterfall variable, documentation — zero adapter code. Ambient verified by an execution matrix over the real runtime bundle plus ten runtime contexts; the blind grader rides a construction pattern, not registered types. A live model-driven tutoring session is the honest gap (maintainer-waived §5.6 for the glue release; caveats live in INSTALL-ZCODE.md).
>
> Researched 2026-08-27, against **ZCode 3.9.2** (desktop, macOS arm64) — statically, by reading the shipped runtime bundle's own plugin/skill/hook loading code (`zcode.cjs`) and executing the shipped hook against every env permutation. Where a fact came from ZCode's bundled official docs rather than observed behavior, it says so.

ZCode's extension model is **Claude Code-compatible by construction** — and ZCode *says so, then proves it in the loader*: manifest discovery falls through `.zcode-plugin/plugin.json` → `.claude-plugin/plugin.json` → `.codex-plugin/plugin.json`; marketplace installs consume `.claude-plugin/marketplace.json` directly; the legacy `CLAUDE_PLUGIN_ROOT` env var is exported **alongside** its own. That makes ZCode the reference case for a different cheap-port mechanism than pi's: not "embraces your standard," but **"already speaks your dialect, with sharp exceptions you must find in the runner code."**

## Loader model

- Install: **Settings → Plugin Management → Discover tab → `+`** with source `https://github.com/<owner>/<repo>` (Git URL, local dir, or file also accepted). Enable/disable state lives under `plugins` in `~/.zcode/cli/config.json`. On install the whole repo stages into the plugin cache — docs/ and everything travels (R8-safe).
- Manifest priority: `.zcode-plugin/plugin.json` **first**, then the compatibility names. Name regex `[a-z0-9][a-z0-9._-]{0,127}`; version defaults to `"0.0.0"` when absent.
- **Components discover by convention**: if `<root>/skills/`, `commands/`, `agents/`, or `hooks/hooks.json` exist, they load with **no manifest declaration at all** (an explicit field adds paths; declaring them as *diagnostic-only* categories — `agents`, `channels`, `lspServers`, `outputStyles`, `settings` — emits a warning instead). Consequence: an engram-style repo needs a manifest only for identity, and a repo that already ships Claude/Codex glue often needs **zero new functional files**.
- Marketplaces come from a GitHub repo **read as `.claude-plugin/marketplace.json`** — a repo sharing with Claude Code needs no second catalog file.
- Skills: Agent Skills standard. Discovery order — explicit roots → user `~/.zcode/skills/` → user `~/.agents/skills/` (cross-tool root shared with dsh) → workspace `.zcode/skills/` → workspace `.agents/skills/` → enabled plugin roots; within a level `.zcode` beats `.agents`; deeper cwd beats shallower; **first same-named wins** and shadows the rest.
- Slash spelling: plugin skills invoke as `/name`, falling back to namespaced `/plugin:name` on some builds — try bare first (engram v1.15 documents both).

## The surfaces that matter

| Need | Mechanism |
|---|---|
| Session-start ambient (the nudge) | plugin `hooks/hooks.json`, event `SessionStart`, matcher values `startup\|resume\|clear\|compact`. ⚠ Runner **parses stdout only if it starts with `{`** and validates against its hook-output schema; plain text = **effect silently discarded AND the run logged as failed** |
| Put text in front of the model | emit `{"hookSpecificOutput": {"hookEventName": "<event>", "additionalContext": …}}` — or flat top-level `{"additionalContext": …}`; snake_case aliases accepted. Valid silence (empty exit-0 stdout) is legal everywhere |
| Block/feedback semantics | PreToolUse JSON may carry `permissionDecision: allow\|ask\|deny`; **exit code 2 = block with stderr text as reason** (never use for "nothing to say") |
| Hook invocation shape | `type:"command"` (shell) or `type:"process"` (`args[]` array — no shell), `timeout`/`timeoutMs` in **seconds**, `async`, `maxOutputBytes`; unknown keys tolerated, unknown *events* warned and skipped |
| Root env vars | plugin context exports **BOTH** `ZCODE_PLUGIN_ROOT` and legacy `CLAUDE_PLUGIN_ROOT` (same rootPath) + `_DATA/_PROJECT_DIR/_SESSION_ID` variants; `${VAR}` interpolation works inside plugin-declared hook/MCP/command strings. **Config-file routes get none of these** |
| User instructions | `~/.zcode/AGENTS.md` (user) → workspace `AGENTS.md` (searched upward) — inside the AGENTS.md family, so lever #1 covers it |
| Headless children | generic **Agent tool** spawns fresh-context children (see below); CLI supports headless runs for the dsh-style process trick |

## The hook contract, precisely (the reason the port took a design turn)

Engram's shared `hooks/hooks.json` feeds Claude Code, Codex/OpenClaw-as-bundle, **and** ZCode. Three consumers, three contracts:

1. Claude Code injects **plain stdout** as context; Codex ditto.
2. ZCode **discards plain stdout**, treats structured-JSON as the only channel — *and writes the run to its hook log as **failed*** when stdout is non-empty and non-conforming. So "prints useful text nobody reads" isn't merely a lost feature on ZCode; it is permanent red noise in the user's diagnostics.

First draft shipped the wrapper as a **second** SessionStart entry guarded by env-var sniffing. Own-review killed it twice: the stock entry would have logged failed on every due-session forever, and the guard was provable only against a variable nothing sets. The shipped answer is a **format switch inside ONE script**:

```bash
ROOT="${ZCODE_PLUGIN_ROOT:-${CLAUDE_PLUGIN_ROOT:-${CODEX_PLUGIN_ROOT:-}}}"
# … engine resolution, compute NUDGE (empty → exit 0, valid silence everywhere) …
case "${ENGRAM_HOOK_FORMAT:-}" in json) emit_json "$NUDGE"; exit 0 ;; esac
if [ -n "${ZCODE_PLUGIN_ROOT:-}" ]; then emit_json "$NUDGE"; exit 0; fi
printf '%s\n' "$NUDGE"   # plain-stdout consumers
exit 0
```

One registration cannot deliver twice on any host by construction. Rule-of-thumb: **when one hook file feeds runners with different output contracts, branch inside the script on an observable property; never duplicate the registration to fork the contract.**

## No named subagent types in practice — build the child yourself

ZCode ships a generic **Agent tool whose children start fresh** (they see only the prompt — process boundary = blindness boundary, R6). Declared plugin `agents/` register as catalog/diagnostic entries, **not executable named types**, on 3.9.2. Engram's shared skills therefore say: *if your spawn mechanism takes no `engram-*` type, read the construction file* — spawn `general-purpose`, prompt the child to `Read <ENGRAM_ROOT>/agents/<role>.md and follow it exactly`, pass graded items **by file path**, collect the receipt from a file. Fork/inherit modes are forbidden for the grader (a child that saw the lesson writes valid-looking, worthless receipts). Received wisdom from testing the shared files on clean personas: capability-branching survives; platform-name branching and any "spawn X by name" assumption do not.

## Gotchas

- **Plain-text hook output is worse than ignored** — see above; it logs failures. (Receipt: engram v1.15.0 dev; caught by its own adversarial review round.)
- **Quoting fuses tokens**: writing a config-file hook as `"\"ENV=val /path/script\""` merges assignment and path into one argv word → `command not found`, silent because mis-shaped output just degrades. Env assignments sit **outside** the quoted path. (Receipt: engram v1.15.1 post-release finding F1, fixed and execution-proven in sh and zsh.)
- **Both roots export at once** — any "which platform am I?" var-sniffing must test **its own** var first and treat presence-not-uniqueness as the signal. Waterfalls resolve identically either way because both point at the same rootPath; *ordering* between them exists only so a clone-route or shadow install can't out-rank the running platform. (Receipt: engram v1.15 waterfall pins `$ZCODE_PLUGIN_ROOT` before `$CLAUDE_PLUGIN_ROOT`; vitest order-case added.)
- **Matcher vocabulary includes `compact`** — `startup|resume|clear` alone leaves post-compaction sessions unnudged. Adding it is harmless on Claude-side readers. (Shared-file change; cross-read before shipping.)
- **`~/.agents/skills` is ZCode's legacy user root too** — the same three symlinks light dsh *and* ZCode. Convenience with a price: one directory now serves two independently-updated hosts, i.e., pitfall #16's cache skew without caches. Symlink the *repo* once and upgrade the repo; never let two tools hold divergent copies.
- Config-file hooks are **disabled until `hooks.enabled: true`** in `config.json`; plugin-contributed hooks auto-enable the runner. A manual-wiring doc that buries the flag produces "installed, listed, dead."
- Agent-type registration surfaces differ across builds ("Settings → Subagents" may list yours) — **do not branch on the listing**; treat declared agents as inert unless executing proves otherwise (pitfall #14's listing-vs-behavior rule again).

## Verification status, itemized

**Verified:** manifest priority + convention-component discovery; marketplace-via-Claude-catalog; dual-root export; 7-event hook set + matcher vocab + output schema acceptance (flat and nested shapes) + failure logging of non-conforming stdout; timeout semantics; skills discovery order incl. `~/.agents` cross-root; config-file `enabled` gate; format-switch hook behaves correctly across 10 env contexts (both/legacy/codex-only/none/forced/bogus-root/missing-engine/empty-state — always `exit 0`, exactly-once delivery).

**Not verified live (stated, not hidden):** a model-driven tutoring loop end-to-end; marketplace update-in-place flow; `process`-typed hooks and async mode. None degrades harmlessly-blocking — each failure surface here terminates in silence or a documented missing feature, never a broken session.

## Sources

- engram's port: [INSTALL-ZCODE.md](https://github.com/nagisanzenin/engram/blob/main/INSTALL-ZCODE.md) · [`hooks/session-start.sh`](https://github.com/nagisanzenin/engram/blob/main/hooks/session-start.sh) (the format-switch reference) · [`hooks/hooks.json`](https://github.com/nagisanzenin/engram/blob/main/hooks/hooks.json) · CHANGELOG v1.15.0 + v1.15.1 (gates ledger incl. what review killed)
- primary sources: the platform's shipped runtime bundle (loader/schema constants) + its bundled self-diagnosis docs, as packaged with ZCode 3.9.2
