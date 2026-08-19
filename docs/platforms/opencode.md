# OpenCode

> Status in engram: **L4 — third platform, shipped v1.0.3 (2026-07-16), hardened v1.0.4.** Contributed by @luanweslley77 (#5, four review rounds; #6, one). The only platform that required *real adapter code*.

OpenCode plugins are npm packages (TypeScript, `@opencode-ai/plugin`), loaded from the npm cache. That one fact drives the entire adapter design — **for plugins that ship commands/agents/tools.** For **skills-only** plugins, the calculus changed in 2026-08: see the `skills.paths` section below before writing any adapter.

## Skills-only plugins need ZERO adapter code now (verified 2026-08-19, OpenCode v1.18.4)

The user config schema (`https://opencode.ai/config.json`, `ConfigV2`) has grown a first-class key:

```jsonc
{
  "skills": {
    "paths": ["~/path/to/clone/skills"],   // extra skill folders (recursive SKILL.md scan, ~ expands)
    "urls": ["https://…/.well-known/skills/"]  // remote skills (untested here)
  }
}
```

So the Phase-3 preference ladder's rung 2 (config entries in the user's config — the Hermes route) now applies to OpenCode: clone the repo, add one `skills.paths` entry, done. `opencode debug skill` lists what actually loaded — a rare **behavior-level** diagnostic (it prints the parsed skill contents, not just your manifest paths), so use it as the verification step.

**Receipt:** production-grade v5.6.0 (14 skills, `_shared/` prose read at runtime, no engine) shipped OpenCode support as exactly one config entry — all 14 skills discovered from a plain clone, `_shared/` correctly not offered, `~` expansion confirmed, on a live v1.18.4 binary. The engram-style self-extract adapter below remains the route when you need **commands, agents, hooks, or an update flow** — none of which `skills.paths` provides.

## Loader model

- Install: `"plugin": ["opencode-engram-learning"]` (npm name) or `"plugin": ["git+https://github.com/<owner>/<repo>.git"]` (pin to source) in `opencode.json` — read globally (`~/.config/opencode/opencode.json`) or per-project.
- **The core problem:** the package lives under `~/.cache/opencode/node_modules/`, and OpenCode does **not** treat the npm cache as a config directory — disk discovery never sees `skills/`/`agents/` inside the package. A naive port is invisible.
- Config dirs that *are* scanned: `~/.config/opencode/` (global) or `{project}/.opencode/` (when the cwd has `opencode.json(c)`).

## Engram's adapter pattern (reusable wholesale)

1. **Self-extract:** the plugin's `config` hook copies `skills/ agents/ scripts/` from the npm cache into the config dir, behind `copyMissing` — **never overwrites existing files**, so user edits survive version bumps. Idempotent via a `.engram-version.jsonc` stamp.
2. **First-execution bridge:** freshly-extracted files aren't discovered until next start, so on first run the hook registers everything through the config layer directly — `cfg.skills.paths.push(...)`, `cfg.command[name] = {template, description}`, agents parsed from frontmatter (custom tools strings → object format, `mode: subagent`, `hidden: true`). Works immediately; disk discovery takes over on the next start and the bridge goes quiet.
3. **Deterministic update flow:** on a version bump, a byte-compare diff (`Buffer.equals`) classifies files; identical → silent, new → extracted, *user-modified* → listed in a manifest + unified `.diff`. A `/engram-update` **pseudo-command** (registered via config only when the manifest exists — never written as a file, so the discovery cache can't lock a stale definition) lets the model show the diff and apply per-file / auto / skip — deletes via `unlinkSync` against a manifest allowlist, an `isWithinTarget` path-traversal guard on every resolved path, zero bash in templates.
4. **Ambient surfaces:** `shell.env` exports `OPENCODE_PLUGIN_ROOT` (the adapter sets the root var *itself* — the platform doesn't); `experimental.chat.system.transform` carries the session nudge; `session.idle` toast announces updates.

## Surfaces

| Surface | Mechanism |
|---|---|
| Manifest | `package.json` (`main` → `.opencode/index.ts`, `files:` allowlist, `engines.opencode`) |
| Skills / agents / commands | extracted copies + config bridge (above) |
| Hooks | plugin SDK hooks: `config`, `shell.env`, `experimental.chat.system.transform`, `session.idle` |
| Root env | `OPENCODE_PLUGIN_ROOT` — self-set, first in the waterfall |
| Distribution | npm (claim the name early — engram holds `opencode-engram-learning` partly against squatting) + git-pin alternative |

## Gotchas

- **SDK config shapes are version-coupled:** the bridge targets v1 shapes (`skills.paths`, singular `command`/`agent`); v2 uses `skills: string[]` and plurals. The adapter documents which it targets and why — pin and note yours.
- **npm publish is a release step** (§6.5 in engram's protocol): skipping it strands npm installers on the old version *and* silently mutes their update notifications (the update manifest diffs against the npm cache). `npm pack --dry-run` first — npm has no gitignore; `__pycache__` will ship. Publishing needs interactive 2FA.
- Adapter code = product code: engram's carries 88 vitest tests + `tsc --noEmit` + engine selftest in CI on every push.

## OpenCode 2.0 (beta) — new plugin contract (verified 2026-08-16, opencode2 v0.0.0-next-17444)

V2 does not load V1 plugins. Facts from the shipped binary's source maps + a live e2e (engram branch `opencode-v2`, issue #18):

- **Contract:** default export `{ id, setup(ctx) }`. `Plugin.define` is identity — a plain object loads, extra keys tolerated. Ship the adapter with ZERO `@opencode-ai/*` imports and it survives the beta's export reshuffles (V1 API moved to `/v1`, promise-V2 became the root, Aug-14 builds).
- **Dual-entry trick:** V2's npm resolution probes package subpath `"server"` before the root (`subpaths: ["server", ""]`). Publish `exports["./server"] = <v2 entry>` and ONE package name installs the right adapter on both engines. Local dirs only follow string `exports`/`module`/`main` — local dev must point at the entry file.
- **THE trap:** plugins run in a background service shared across projects — `process.cwd()` is NOT the workspace. Plugins instantiate per workspace; every domain response is `{ location: {directory, ...}, data }` — read the dir from `await ctx.agent.list()`. Engram's first smoke test extracted into `~/.config/opencode/` because of this.
- **Bridge replacement:** extract to disk, then `ctx.{command,skill,agent}.reload()` — re-scans disk, surfaces live in the same boot. Discovery dirs went plural (`commands/`, `agents/`; singulars remain as compat shims — write plurals). Hooks map: `system.transform` → `session.hook("context")` (push `{type:"text", text}` SystemParts), `shell.env` → `shell.hook("create.before")`, custom tools → `tool.transform(d => d.add(...))` (plain JSON Schema input ok). No toast API. Duplicate plugin ids across sources kill the whole activation — never double-install.
- **Tools (2026-08-16, live-found):** default-options tools route through the CODEMODE meta-tool — direct named calls need `options: { codemode: false }` or every call fails "Unknown tool" while the tool sits advertised. A result declaring `output` without an output schema is rejected; `content` is the free-form field.
- **Location scope (2026-08-16, live-found):** plugins instantiate for locations beyond the configuring project (service root included). Gate extraction on the location OWNING an opencode config file or being the global config dir — otherwise a config-less location falls through to the user's real global config (engram's `extractionScope()` is the reference; it shipped after polluting a real `~/.config/opencode` twice in testing).
- Free bundled models drop connections on SUBAGENT spawns (`Error: Transport`) — document a real-provider requirement for agent-spawning flows.
- Full port receipts: engram v1.12.0 on main — `.opencode-plugin/v2.ts`, `INSTALL-OPENCODE-V2.md`, `docs/user-sessions/v1.12.0-opencode2.md` (first Engram session on the V2 runtime).

## Sources

- Engram's adapter: https://github.com/nagisanzenin/engram/tree/main/.opencode (heavily commented headers — read `index.ts` and `install.ts` first)
- npm package: https://www.npmjs.com/package/opencode-engram-learning
- OpenCode plugin SDK: https://opencode.ai/docs/plugins (`@opencode-ai/plugin`)
