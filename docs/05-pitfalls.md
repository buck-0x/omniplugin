# 05 · Pitfalls — field notes with receipts

Every entry: what actually happened → the rule it taught. All from [engram](https://github.com/nagisanzenin/engram)'s history; dates and versions are real.

---

## 1 · The port built by analogy

**What happened:** an external Antigravity PR (engram #8) shipped a `commands/` directory and a manifest with `skills`/`agents`/`commands`/`version` fields — all reasonable *by analogy to Codex*. On the actual target: AG's schema allows exactly `{name, description}` (`additionalProperties: false`), discovery is by directory convention, commands don't exist as a concept, and skills auto-derive slash commands anyway. Nearly the entire contribution was dead weight on the platform it targeted.

**Rule:** research the target's actual loader from primary sources (schema, CLI changelog, flagship plugin) before writing or accepting a line of glue. A port's correctness is a property of the *target platform*, not of the diff.

## 2 · Namespace bleed: the file that did nothing on its platform and broke another

**What happened:** that same `commands/` directory — inert on Antigravity — would have been auto-discovered by **Claude Code**, which scans root `commands/` with no manifest declaration. Every existing CC user would have received a stray `/engram:review-loop` on their next update, with the `learn`/`coach` stubs silently shadowed by same-named skills (skill takes precedence).

**Rule:** platforms scan overlapping root namespaces. Every new root path gets checked against every *shipped* platform's discovery conventions, not just the target's.

## 3 · Version drift multiplies per platform

**What happened, three ways:** the README version badge was missed in v1.0.3 *and* v1.0.4; a stale `package.json` would make npm publish old code under a new tag; the AG PR's optional `version` field would have created a fourth manifest location that the release-grep didn't scan.

**Rule:** the bump is a grep with an authoritative location list; a selftest pins engine-version == manifest-version; optional version fields are refused. ([04 · Maintenance](04-maintenance.md) §1.)

## 4 · The installer that severs your core

**What happened:** Hermes' hub installer copies each skill folder plus only files referenced *inside it* — "unreferenced repository files are not copied." Engram's skills share a repo-level engine and `skills/_shared/`; hub-installed copies would be skills with no engine, a breakage no error message would ever explain.

**Rule:** the staging model (whole-repo vs referenced-files-only) is intake question #7, answered before the install doc is written. Where staging severs, the install route is clone + external-dirs — and the doc says *why*.

## 5 · The ambient hook that failed open

**What happened:** the Hermes `pre_llm_call` hook — contract: "at most one nudge per session, silence on any failure" — reached review failing open two ways: an empty `session_id` bypassed the dedupe entirely (nudge on every LLM call), and a misplaced `2>/dev/null` made an unwritable TMPDIR both leak bash errors and re-nudge per call.

**Rule:** ambient adapters fail **closed**: can't identify the session → at most once per process; can't write the dedupe marker → silence. "Silence over repetition" is the contract, and it gets a failure battery (9 cases) shipped with the hook.

## 6 · Your command name is someone's built-in

**What happened:** `/learn` is Hermes' flagship built-in (authors new skills). And after the collision was found, documented, and the hook taught to rewrite its nudge to `/skill learn` — a review *still* caught the cron delivery path emitting the un-rewritten `/learn`, two sections after the doc warned about exactly that.

**Rule:** collision handling is: detect → escape hatch → rewrite your own strings in **every** output path → document per-platform spelling in the matrix. ([02 · Portability rules](02-portability-rules.md) R5.)

## 7 · The platform you can't run

**What happened:** the Codex port was built without a live Codex binary. It shipped anyway — legitimately — because every unverified path degrades harmlessly (self-resolving hook, silence on failure), a skills-only Route B carries the whole loop, and the install doc splits Verified / Not-verified item by item and asks users to report.

**Rule:** "can't verify" is shippable; *pretending* you verified is not. Harmless degradation + honest status + a fallback route is the template. ([03 · Adding a platform](03-adding-a-platform.md) Phase 4.)

## 8 · The platform whose cache isn't a config dir

**What happened:** OpenCode loads npm-installed plugins from its npm cache, which its discovery never scans for skills/agents — so a "correct" package was invisible. The fix was a real adapter: self-extract into the config dir on first run, a first-session config bridge so everything works *immediately* (not after a restart), `copyMissing` so user edits are never overwritten, and a deterministic `/engram-update` flow (byte-compare diffs, allowlisted deletes, path-traversal guards, zero bash in templates) because "just re-extract" would clobber users.

**Rule:** when a platform forces real adapter code, the adapter inherits product-grade obligations: its own test suite (88 vitest), CI, an update story that respects user edits, and security posture (no interpolated shell, validated paths).

## 9 · Cross-platform prose drift

**What happened:** one release review found five stale cross-platform claims in the README at once — "four platforms" counting one still in review, a missing second install command in a matrix cell, dropped platform-specific details, an example unscoped under a matrix that had just grown a row, and a nudge-coverage claim that had silently become true of more platforms than it named.

**Rule:** every sentence containing a platform name or count is re-read on every release. The matrix is load-bearing documentation, not decoration.

## 10 · Sandbox and environment asymmetries

**What happened, small but real:** Codex's default `workspace-write` sandbox prompts on state writes outside the workspace (state dir placement must be documented per platform); Hermes' headless `chat -q` passes slash commands through as literal text (so the obvious smoke test is a false negative — the doc says how *not* to test); Hermes state lives on whatever host runs the terminal backend, which changes what "shared schedule" means on remote backends.

**Rule:** intake questions 9 and 11 exist because each of these cost a debugging session. Answer them during research, not from bug reports.

## 11 · Trigger semantics differ even when formats port cleanly

**What happened:** Claude Code auto-delegates subagents ("MUST BE USED" descriptions work); Codex spawns TOML agents **only on explicit request**; Hermes needs `delegate_task` with the prompt passed as context. The same assessor prompt ports everywhere — but a skill that says "spawn the assessor" silently does nothing on platforms without auto-routing unless the skill/docs carry the per-platform invocation.

**Rule:** port the prompt, adapt the trigger, preserve the guarantee — and verify the *invocation path*, not just the file format. ([02 · Portability rules](02-portability-rules.md) R6.)

## 12 · The loader's code disagrees with the loader's docs

**What happened:** OpenClaw's `plugins/bundles.md` states plainly that a native manifest wins detection — *"If a directory contains both, OpenClaw uses the native path."* The shipped `detectBundleManifestFormat` checks `.codex-plugin/plugin.json` **first** and only reaches `openclaw.plugin.json` fourth. engram ships a Codex manifest, so it is *always* a Codex bundle on OpenClaw regardless of what else it ships. A native `openclaw.plugin.json` was written, tested, observed to be completely inert, and deliberately **not** shipped — because the day upstream makes the code match the docs, that file would silently change the plugin's entire shape.

**Rule:** for anything load-bearing, read the loader's **code**, not its prose — the docs describe intent, the code describes behavior. And when you find the two disagreeing, do not ship a file that is inert under today's behavior and load-bearing under tomorrow's. That is a landmine with a timer on it.

## 13 · The same manifest key, different meaning on two platforms

**What happened:** engram's Codex manifest declared `"hooks": "./hooks/hooks.json"`. On Codex that is a file path. On OpenClaw — which reads that same Codex manifest — the `hooks` value is a list of **directories to scan for hook packs**. So OpenClaw dutifully scanned a *JSON file* for `*/HOOK.md`, found nothing, and loaded no hooks at all. The fix was to **delete the key**: OpenAI documents that Codex auto-discovers `./hooks/hooks.json` when it is absent, and OpenClaw then falls back to scanning `./hooks/`. Both platforms found their hooks by convention once neither was being told anything.

**Rule:** when platforms share a manifest, they share a **namespace, not a schema**. Check the semantics of every key against every platform that reads that file. And prefer convention to declaration: an omitted key that both platforms auto-discover correctly beats a declared one that means two different things.

## 14 · Declared-and-broken looks exactly like working

**What happened:** through all of the above, `openclaw plugins inspect engram` cheerfully listed `hooks` among the bundle's capabilities — because the capability probe only checks whether a `hooks/` path *exists*, not whether anything loaded from it. The diagnostic said "hooks ✓" for a plugin that was loading precisely zero.

**Rule:** a capability listing is a statement about your manifest, not about the running system. **Assert the behavior, never the listing** — find the log line that proves the thing registered, or trigger it and observe the effect.

## 15 · The feature gated behind a host flag your plugin cannot set

**What happened:** OpenClaw skips internal hook discovery entirely until something opts in, and *shipping a hook pack inside a plugin does not opt in*. Without `openclaw config set hooks.internal.enabled true`, `openclaw hooks list` shows the hook as `✓ ready` — correct events, requirements satisfied, green tick — and it never runs once. Proven both directions in the loader log: zero handlers registered without the flag, `Registered hook: engram-due -> command:new, command:reset` with it.

**Rule:** for every capability you contribute, find the host's **global enable gate** and put it in the install doc's numbered steps, not its troubleshooting section. A silent failure that renders as a green tick is the most expensive kind: users don't report it, because nothing looks wrong.

## 16 · You tested the version the platform had cached, not the one you're shipping

**What happened:** an agent dogfood was reported green. It had run against the agent definitions in the **platform's plugin cache** — four months and 83 commits stale, from a version whose assessor spec had neither of the two output rules the shipped spec enforces. The run "passed" while emitting a fabricated model id in a field the current spec explicitly forbids. Nothing looked wrong: clean prompt, plausible output, every field present. The only tell was a version number nobody printed.

**Rule:** with N platforms you have **N independently drifting caches**. Any gate that runs *through* a platform tests whatever that platform cached; only gates that invoke your repo directly test what you're shipping. Print the loaded version before trusting a single result — and prefer driving agents by handing them the repo's file by absolute path.

## 17 · Prose written for the platform you're porting is read by the ones you aren't

**What happened:** the OpenClaw port wrote *"On OpenClaw, engram's agents are not registered — call `sessions_spawn`…"* into all three **shared** skills. Those files are read verbatim by six platforms. A blind read by an agent on Claude Code came back confused: the branch was posed as a choice between two platforms, Claude Code's own Task tool was never named, and the skills used bare agent names where that platform requires a namespaced type. Separately, a two-line engine-resolution snippet got **paraphrased into a guessed path** by a live model and broke `/review` — the variable it should have read was in the environment the whole time.

**Rule:** in shared files, branch on **observable capability** (*"if your only mechanism is a generic `sessions_spawn`…"*), never on a platform name the reader has to recognise; and state the **property** (*"a fresh-context child running that agent's definition"*) so platform N+1 inherits it for free. For critical shell, ship **one copy-and-run block** and say `RUN THIS VERBATIM` — a base expression plus a correction line is an invitation to improvise. Both regressions were found by handing the edited files to an uncontaminated agent **on a different platform** and asking three questions: which mechanism applies to you, what does this block resolve to, and does anything here reference a tool you don't have?

## 18 · The strict parser that skips silently

**What happened:** pi parses prompt-template frontmatter as real YAML. Engram's `/learn` template carried `description: Engram — learn any topic properly: first-principles curriculum…` — an unquoted value with a second colon, which is invalid YAML. Pi's response was not an error: the template **silently didn't load**, so `/learn kalman filters` reached the model as literal text, on two pi versions, and the hunt went through pi's resource-loader source twice before the difference turned out to be a colon. The debugging cost an hour; the fix was quotation marks. (engram v1.11.0 development, caught by the port's own harness failing exactly one check.)

**Rule:** every declarative file you ship is parsed by *someone's* parser, and the strict ones fail as **absence, not error** — the quieter cousin of namespace bleed. Quote frontmatter values everywhere, and make your verification harness invoke each command once: a parse failure that renders as "command not found by the model" is invisible to any check that only lists files.

## 19 · The lifecycle hook the host awaits

**What happened:** engram's pi extension ran its session-start probe (`engram.py session-start`, a subprocess) with `await` inside the `session_start` handler. Pi **awaits all `session_start` handlers before rendering the TUI and before completing `/new` and `/resume`** — so a slow engine (cold network home dir, macOS's python3 installer stub) would have frozen the entire agent's startup for the full 15-second timeout, unattributed. Found by an adversarial reviewer reading pi's runner source, not by any test — the harness's engine was always fast. A sibling in the same review: pi's exec resolves a **timed-out, signal-killed child as `code: 0`** with a separate `killed: true` flag, so the "success" guard would have injected a truncated nudge fragment under `PYTHONUNBUFFERED=1`.

**Rule:** before putting work in a host's lifecycle hook, find out whether the host **awaits it** — an awaited handler is on the startup critical path, so fire-and-forget anything that touches disk or subprocesses. And read the exec contract to its edges: what does a *killed* child return? The flattering interpretation of an exit code is exactly the one to distrust.

## 20 · The dist-tag that downgrades silently

**What happened:** `npm install -g` of pi on a Node 20 machine installed **0.74.2** while `latest` was 0.83.0 — nine minor versions of skew, no warning. Pi gates current releases on Node ≥ 22.19 and publishes a `legacy-node20` dist-tag for older runtimes; npm resolves it silently. Half a day of source-reading targeted the wrong version's code, and any user following the install doc on Node 20 gets a different binary than the one you verified.

**Rule:** before writing a requirements line, run `npm view <pkg> dist-tags` and `npm view <pkg> engines` — a platform with engine-gated releases has **multiple lines your users actually receive**. Verify your plugin against every line users get by default, or name the one you verified. (Engram's answer: the harness runs green on both, and the install doc says so.)

## 21 · The check that cannot fail for the documented reason

**What happened:** engram's pi harness asserted "no nudge on an empty store" — in print mode, where the extension is **inert regardless of the store** (`ctx.hasUI` is false in `-p`). The check could never fail for the reason the docs implied it guarded; store-driven silence was proven by zero of the checks while two documents cited it as verified. The same review round found the docs saying "asserted" where the harness merely `console.log`ged (a context-file canary, a notify request). Both fixed in the honest direction — observations promoted to checks (16 → 19 → 20) rather than sentences softened. Caught pre-release by a reviewer diffing *claims against assertions*, and post-release by §7.5 for the empty-store case. (engram v1.11.0 → v1.11.1.)

**Rule:** a check is only evidence if it *can* fail for the documented reason — know which mode, flags, and guards are active when it runs, or you are asserting your test setup, not your feature. And audit the words "asserted"/"verified" in your docs against the instrument: every one must trace to a check that would go red, not to a log line somebody once read.

---

## 22 · The hook output that is also a verdict

**What happened:** ZCode's SessionStart runner parses a command hook's stdout **only if it starts with `{`** and schema-validates it as structured output; anything else — including the two plain-text nudge lines that five other platforms print happily — has its effect silently discarded *and the run recorded as failed* in the host's diagnostics. Engram's first draft registered a second wrapper entry next to the shared hook and told them apart by env-var sniffing. Its own pre-release review killed both halves: every session with reviews due would have logged a permanent red "failed hook" record while the nudge still arrived once (noise forever), and the no-double-delivery guard was only provable under an environment nothing actually produces.

**Rule:** before wiring any ambient hook, find out whether the host treats stdout as **content to deliver** or **structured data to interpret** — and whether non-conforming output is dropped quietly or *adjudicated*. When one shared hook file feeds runners with different contracts, branch the format **inside one script on an observable property** (`$ZCODE_PLUGIN_ROOT` present → JSON; override var for manual routes); never duplicate the registration to fork the contract. One registration cannot double-deliver anywhere; two registrations plus a guard are exactly the shape guards are bad at proving. (engram v1.15.0.)

## 23 · The quoted command that became one word

**What happened:** engram's install doc told config-file route users to wire `"command": "\"ENGRAM_HOOK_FORMAT=json /Users/you/.agents/engram/hooks/session-start.sh\""`. The escaped quotes wrapped assignment **and** path into a single argv token — `command not found`, and on this platform mis-shaped hook output just degrades silently, so a user following the doc verbatim got a permanently missing nudge with zero errors pointing at the doc. Found only by the post-release reviewer trying to execute the documented line.

**Rule:** shell-quoting rules inside manifest JSON are loader semantics you must verify by **execution**, in more than one shell, against the exact string the doc prints. Env assignments go outside quoted path tokens. The failing direction is always silence-with-nothing-registered — the same absence-not-error signature as pitfall #18, arriving through tokenization instead of YAML. (engram v1.15.1 §7.5 finding F1.)

---

## The meta-lesson

Engram's release protocol states it once and it applies double across platforms: **every gate you build misses its own bug class — the only things that ever found the real bugs were a fuzzer, an outside reviewer, and a real user.** With N platforms you cannot even run everything you ship, so the outside world isn't just helpful, it's structural: design for harmless degradation, publish honest status, and treat every user report from a platform you can't run as the integration test it is.
