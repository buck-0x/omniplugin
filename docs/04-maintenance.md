# 04 · Maintaining the matrix

Creating an omni-platform plugin is one afternoon per platform. *Maintaining* one is where the design either pays off or collapses. The operating doctrine, from a year of engram releases (v0.4 → v1.15, nine platforms):

---

## 1 · One release protocol, and it grows a step per platform

Keep a binding `RELEASE_PROTOCOL.md` — the repeatable checklist every release walks, in order. Engram's ([read it in full](https://github.com/nagisanzenin/engram/blob/main/RELEASE_PROTOCOL.md); it is the single most valuable file in that repo) exists because **every gate in it caught a real bug the gate before it couldn't see**. The omni-platform-specific parts:

### The version grep

There is no central version constant across five manifest dialects — so the bump is a *grep, not a memory exercise*:

```bash
grep -rnE '"version"|version-[0-9]|selftest-[0-9]' \
  .claude-plugin .codex-plugin package.json README.md INSTALL-*.md
```

Engram's current locations: `.claude-plugin/plugin.json`, `.codex-plugin/plugin.json` (lockstep), `package.json` (what npm publishes — stale = npm ships old code under a new tag), `ENGRAM_VERSION` in the engine (**pinned to plugin.json by a selftest**, which caught a missed bump in v1.0.1), README badges, install-doc counts. Re-run the grep after editing — zero stale hits, or a badge lies.

Two rules that keep the list from growing unbounded:

- **A selftest pins the engine version to the primary manifest.** The one place drift is caught mechanically.
- **Refuse optional version fields.** If a platform's manifest schema doesn't require `version`, omit it (the AG review stripped one for exactly this reason — a fourth location outside the grep guarantees drift).

### Per-platform release steps

Each platform with its own registry or cache adds mandatory steps: npm publish + `npm view` verification for OpenCode (interactive — 2FA); `gh release create --latest` to flip the badge; and per-platform **update instructions in the release notes**, including cache gotchas ("a plain `plugin update` before `marketplace update` reports 'already current' against the stale cache").

**And one receipt about the notes themselves:** release-notes generators trust heading boundaries. Engram's v1.11.0 CHANGELOG edit accidentally consumed the `## 1.10.1` heading beneath it — so the previous release's entire entry (including its gate claims: "nothing to audit", "§5.5/§5.7 not triggered") published *under the new version's header*, and the extraction script faithfully shipped all of it as v1.11.0's release notes. Caught only by the post-release review; fixed by restoring the header and editing the published notes. After generating notes, grep them for the **previous** version's title — if it's there, a heading got eaten.

## 2 · The README is a support matrix, and it drifts

The front door is a table: platform / install commands / command spelling / status. Two disciplines:

- **Disambiguation-first.** If your plugin is commonly mistaken for an adjacent category, the README's first bold paragraph kills the confusion before the pitch (engram: "not an agent-memory plugin — it's a learning system for the human"). Multi-platform reach multiplies the misread, because each platform's audience arrives with different priors.
- **The consistency pass.** Every platform addition invalidates prose elsewhere. The v1.0.5 review caught five stale cross-platform claims in one README: "on all four platforms" counting one still in review, a missing second install command in one cell, dropped per-platform details, an unscoped example under a matrix that had just grown a row. On every release: re-read every sentence containing a platform name or count.

## 3 · Honest status, forever

Every install doc carries a **Verified / Not verified** section, and it never silently graduates. "Verified live on v0.18.2" names the version; "not independently verified against a live Codex binary" names the gap and why it's harmless; recipe-documented flows say "reports welcome." This is cheap to write at port time and impossible to reconstruct later — and it's what lets you ship platforms you can't run without lying about them.

Track the ladder rung per platform (L0–L4, [01 · Anatomy](01-anatomy.md)) and upgrade the doc when a user or contributor verifies a path you couldn't.

## 4 · The engine is tested once; adapters are tested like products

- The **engine selftest** is platform-independent by construction — `python3 scripts/engine.py selftest` is the same N/N everywhere, doubles as every platform's install-verification command, and its count is a README badge (so it's load-bearing: the protocol pins badge == actual).
- **Adapter code** (when a platform forced real code, like OpenCode's TS bridge) gets its own suite in CI: engram runs vitest (88) + `tsc --noEmit` + engine selftest on every push.
- **Hook adapters** get failure batteries — the 9-case Hermes battery exists because the hook failed open twice in review. A hook's failure modes (missing runtime, unset env, unwritable tmp, empty payload, garbage payload) are enumerable; enumerate them.

## 5 · Community runs the platforms you can't

With N platforms you will not be able to run all N locally. Structure for that:

- **Issues are the demand signal** (Phase 0) and the verification channel ("if anything misbehaves, open an issue with what you see" — in every install doc).
- **Contributors port; the maintainer re-researches the loader.** Two of the first seven platforms arrived as external PRs, and two more (OpenClaw, Pi) began as user issues. The maintainer's review job is Phase-1 research against primary sources — the OpenCode PR hardened across four review rounds; the AG review *removed* most of the contribution and cited the official schema, the CLI changelog, and a flagship plugin for every requested change.
- **Close the loop with strangers.** After resolving an external issue/PR: thank them, state what shipped and how to get it, name what's still unverified and how they can help. This is how a requester becomes your standing test environment for a platform you'll never install.

## 6 · Watch for platform drift

Platforms are young and their loaders change monthly. Defenses, cheapest first:

1. Every crib sheet and install doc **pins the version researched against** ("agy CLI v1.1.4", "Hermes v0.18.2") — so staleness is at least visible.
2. Prefer glue that rides **convention over API** (directory discovery survives more releases than SDK calls; engram's only real API-coupled adapter, OpenCode's, deliberately notes which SDK config shapes it targets and why).
3. When a user reports a break on a platform you can't run: fix toward **harmless degradation** first (restore silence), toward feature parity second.

## 7 · Know what stays shared, and defend it

The whole model rests on `skills/` and the engine staying **byte-identical across platforms**. Pressure to fork them will arrive disguised as convenience ("just add an AG-specific line to the skill…"). Hold the line:

- Platform differences go in the **resolution waterfall**, the **hook variants**, or the **install docs** — never as forks of core prose or engine logic.
- Where per-platform *output* must differ (the `/learn` → `/skill learn` rewrite on Hermes), transform at the adapter boundary (the hook's `sed`), leaving the core's output canonical.
- If a platform truly cannot run the shared core, that platform is L0-only until it can — a caveat, not a fork.
