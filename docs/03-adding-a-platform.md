# 03 · Adding a platform — the checklist

The recurring operation. Engram ran this loop five times (Codex, OpenCode, Hermes, Antigravity, OpenClaw); each run below is annotated with what that pass taught. Work the phases in order — every shortcut here has already failed once.

---

## Phase 0 · Demand check

Port on **pull, not push**. Every engram platform after Claude Code arrived as a user request (OpenCode: issue #5, Hermes: #9, Antigravity: PR #8). A requester is also your live test environment on a platform you may not be able to run — and the person you close the loop with when it ships.

If nobody asked yet: the port still might be worth it for reach, but downgrade the verification claims accordingly (Phase 4).

## Phase 1 · Research the platform's ACTUAL loader

**Never trust analogy.** "It's modeled on Claude Code" is how a contributor ships a manifest full of fields the target ignores (see [05 · Pitfalls](05-pitfalls.md) #1). Establish, from primary sources:

1. **Official manifest schema** — fetch the actual JSON schema if one exists. (Antigravity's allows exactly `name` + `description` with `additionalProperties: false`; everything else in the contributed manifest was Codex idiom the target would ignore.)
2. **The CLI/app changelog** — loader behavior often lives only there (AG's *"skill-derived slash commands"*, *"copy the entire plugin directory"* were changelog lines, not docs).
3. **A flagship plugin as reference implementation** — find the most serious existing plugin for the platform and read its layout. What it *doesn't* ship is as informative as what it does (the flagship AG plugin ships no `commands/` — because nothing reads one).

### The intake questions (answer all 15 in writing — [template](../templates/platform-intake.md))

1. **Manifest**: required file, schema, which fields are real vs tolerated?
2. **Discovery model**: manifest-mapped, or directory convention? Which root paths are scanned?
3. **Skills**: does it read `SKILL.md` natively? Do skills auto-derive commands? Frontmatter dialect differences?
4. **Agents/subagents**: format (md/toml/yaml), frontmatter keys, and — critically — **trigger semantics**: auto-delegated or explicit-only?
5. **Hooks**: which lifecycle events exist? Protocol (exit code / stdout / JSON-in-JSON-out)? Where are they registered — plugin manifest, separate hooks file, or user config?
6. **Env vars**: does the platform set a plugin-root variable? What reaches subprocess shells?
7. **Staging model**: does install copy the *whole repo*, or only referenced files? Where on disk? ← the question that decides whether your shared core survives (Hermes hub severs it; clone + external_dirs is the route).
8. **Update flow**: how do users get new versions? Does anything cache stale manifests?
9. **Sandbox/permissions**: can hooks and skills write outside the workspace? Will your state dir trigger prompts (Codex `workspace-write` does)?
10. **Namespace collisions**: do any of your command/skill names collide with platform built-ins? What does the platform do on collision? (`/learn` is Hermes' flagship built-in.)
11. **Headless vs interactive**: do slash commands work in non-interactive mode? (Hermes `chat -q` passes them through as literal text — document how *not* to test.)
12. **Version field**: does the platform manifest want a version? If yes, it becomes a new location in your release-grep ([04 · Maintenance](04-maintenance.md)) — or, if the schema doesn't require it, deliberately omit it to avoid a drift location.
13. **Does it read another platform's manifest?** ⚠ NEW. Some loaders accept foreign formats as "bundles" — OpenClaw reads Codex, Claude, and Cursor layouts. If yes: **which one wins when you ship several**, and does the answer come from the docs or from the code? (OpenClaw's docs say a native manifest wins; its code checks the Codex marker first. Pitfall 12.) Then re-read every key in that borrowed manifest for a *different meaning on this platform* — `hooks` is a file path to Codex and a directory list to OpenClaw, which silently loaded nothing (pitfall 13).
14. **Is the capability globally gated?** ⚠ NEW. Ask, per capability you contribute, whether the host requires a separate opt-in before it runs anything. OpenClaw skips internal hook discovery entirely until `hooks.internal.enabled` is set — and until then the hook lists as `✓ ready` and never fires. Find the gate during research, and it becomes an install *step*; find it later, and it was a week of "why is nothing happening" (pitfall 15).
15. **What does the diagnostic actually prove?** ⚠ NEW. Identify, before you trust it, whether the platform's `list`/`inspect`/`status` output reflects the **running system** or merely your manifest. OpenClaw reported `hooks` as a live capability the entire time it was loading zero of them. Find the log line that proves registration, and make that your check (pitfall 14).

Save what you learn — dated, with URLs — into a per-platform crib sheet ([docs/platforms/](platforms/)).

## Phase 2 · Map invariants → mechanisms

List your plugin's invariants (the guarantees, not the features). For each, find the platform mechanism that preserves it; where none exists, choose degradation **and write the caveat now** — it goes in the README callout and the install doc, not in a drawer.

Engram's mapping exercise, Antigravity pass: skills auto-derive commands ✓; engine ships via full-repo staging ✓; root resolution via landmark fallback (AG sets no env var) ✓; ambient nudge — **no session-start event found** → ship without, one honesty line in the README; assessor spawnability — **unknown** (agent frontmatter dialect differs) → caveat line, evidence requested from the contributor.

## Phase 3 · Write the thinnest glue that works

Prefer, in order:

1. **Zero adapter code** — the platform reads your existing conventions (Antigravity: the "port" is a 3-line manifest; discovery does the rest).
2. **Config entries in the user's config** — no new files in the repo beyond a hook variant (Hermes: `external_dirs` + `.env` + optional hook block).
3. **Manifest + format ports** — new manifests, agent-format translations, same behavior (Codex: TOML agents, mirrored plugin.json).
4. **Real adapter code** — only when the platform's loading model forces it (OpenCode: npm cache is not a config dir → self-extract + first-run config bridge). If you're here, the adapter gets its own test suite and CI like any product code (engram's: 88 vitest tests + `tsc --noEmit` + engine selftest on every push).

Two disciplines while writing glue:

- **Namespace-bleed check** (R9): every new root path gets checked against every *shipped* platform's discovery conventions before it lands.
- **Never clobber the user**: if the adapter copies files (self-extract), copy-missing-only, and route updates through an explicit, deterministic flow (engram's `/engram-update`: byte-compare diffs, allowlisted deletes, path-traversal guards, zero bash in templates).

## Phase 4 · Verify live — or label honestly

The gold standard is **verified live**: run the real platform binary and exercise every claim in the install doc. Engram's Hermes doc opens with "verified against a live Hermes Agent v0.18.2" and means it — discovery, slash registration, full SKILL.md injection sizes, and the nudge landing in the composed message **at the wire level** (request dump inspected).

When you *can't* run the platform (no binary, no license, wrong OS):

- Ship the port anyway **if and only if** every unverified path degrades harmlessly (self-resolving hooks, Route-B fallback).
- Split the install doc's status section into **Verified** / **Not verified**, item by item. Engram's Codex doc names exactly what was never run against a live binary and why each mismatch would be harmless.
- Ask the requester for the specific evidence you need (the AG PR asks for: `agy --version`, validate output, a transcript proving the engine actually runs, subagent spawnability) — *before* merging.

**Never let a green validator stand in for a live run.** `agy plugin validate .` passing while reporting counts that don't match the platform's documented behavior ("3 commands" on a platform with no commands concept) is a red flag, not a pass.

## Phase 5 · Ship it as a release

A platform addition is a release like any other — it runs the full [release protocol](04-maintenance.md), plus:

- [ ] `INSTALL-<PLATFORM>.md` at repo root ([template](../templates/INSTALL-PLATFORM.md)) — glue explanation, install routes, invariant mapping, **honest status**
- [ ] README support-matrix row: install column, command-spelling column, status
- [ ] README consistency pass: every existing "on all N platforms" claim re-checked (v1.0.5's review found five stale cross-platform claims)
- [ ] New version locations added to the release-grep (a new manifest with a version field = a new drift location)
- [ ] New release steps appended to the protocol if the platform has its own registry (OpenCode added §6.5 `npm publish` — skipping it strands npm installers on the old version *and* silently mutes their update notifications)
- [ ] CHANGELOG entry that includes **known limits** ("headless `-q` doesn't expand slash-skills; delegate_task flow recipe-documented, not yet driven")
- [ ] Close the requesting issue with a real reply: thank the requester, what shipped, how to get it, what's still unverified and how they can help

## Phase 6 · Keep it alive

- Watch the platform's changelog; loaders change fast (pin what version your research was done against — every crib sheet here carries its date).
- External contributors will send ports. Welcome them — two of the first seven platforms were contributed (nine exist today), and two more began as user issues — but **re-run Phase 1 yourself before merging**. The review that matters is against the platform's actual loader, not against the diff's internal quality. Requesting changes that *remove* work is normal (the AG PR shrank to ~7 lines under review).
- When a port's unverified paths get exercised by real users, upgrade the honest-status section — or fix what they found and reply.
