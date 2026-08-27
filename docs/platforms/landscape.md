# The platform landscape — July 2026

> Survey of the plugin/extension surfaces of 12 agentic platforms, researched 2026-07-18 against official docs (URLs inline), with popularity numbers re-verified against the live GitHub API the same day. Confidence is flagged per platform; UNKNOWN means UNKNOWN, not "probably". The five platforms engram ships on have deeper crib sheets in this directory — for those, the crib sheet wins on detail.
>
> Platform loaders drift monthly. Before acting on any row, re-run the [intake questions](../../templates/platform-intake.md) against current docs.

## 1 · Extension-surface matrix

Y = yes · P = partial/caveat · N = no · ? = unknown.

| Platform | Instructions-file | Commands | Hooks | Subagents | Skills | MCP | Marketplace |
|---|---|---|---|---|---|---|---|
| **Claude Code** | Y `CLAUDE.md` (auto) | Y `/name` | Y (29 events) | Y `agents/` | Y `SKILL.md` | Y `.mcp.json` | Y git-backed |
| **Codex CLI** | Y `AGENTS.md` (auto) | P deprecated→skills | Y (10 events) | Y `agents/*.toml` | Y `SKILL.md` | Y `config.toml` | Y git-backed (~Mar 2026) |
| **Antigravity** | Y `GEMINI.md`/`AGENTS.md` (auto) | Y workflows+skills | Y (5 CLI / 9 SDK) | Y | Y `SKILL.md` | Y `mcp_config.json` | ? plugins yes, registry UNKNOWN |
| **Gemini CLI** | Y `GEMINI.md` (auto) | Y TOML | Y (11 events) | Y `@agent` | Y `SKILL.md` | Y `settings.json` | Y gallery + git |
| **Cursor** | Y `.cursor/rules/*.mdc` + `AGENTS.md` (auto) | Y `.cursor/commands` | Y (~20 events) | Y `.cursor/agents` | Y `SKILL.md` | Y `.cursor/mcp.json` | Y `plugin.json` (Feb 2026) |
| **Windsurf → Devin Desktop** | Y rules (auto) | Y workflows (manual-only) | Y (12 events) | P (successor "Devin Local") | Y `SKILL.md` | Y `mcp_config.json` | P MCP store only |
| **Cline** | Y `.clinerules/` (auto) | Y workflows | Y (4 events) | P built-in, not user-definable | Y `SKILL.md` | Y | P MCP-only marketplace |
| **Roo Code** ‡ | Y `.roo/rules/` (auto) | Y `.roo/commands` | **N** | Y Boomerang/Orchestrator | Y `.roo/skills` | Y | P modes+MCP only |
| **OpenCode** | Y `AGENTS.md` (auto) | Y `.opencode/command` | Y (JS/TS plugin event bus) | Y primary/subagent | Y `SKILL.md` | Y `opencode.json` | P npm-distributed, no GUI |
| **Goose** | Y `.goosehints`/`AGENTS.md` (auto) | P recipes-as-slash | **N** (no generic event hooks) | Y sub-recipes | Y `SKILL.md` | Y (extensions = MCP) | Y recipe cookbook + MCP registry |
| **Amp** | Y `AGENTS.md` (auto) | P built-in + `registerCommand` | Y (`amp.on`, 5 events) | Y auto-spawned | Y `SKILL.md` | Y `settings.json` | **N** git/manual (toolboxes deprecated) |
| **Hermes** | Y `SOUL.md` + project ctx (auto) | Y skills→`/name` | Y (11+ events) | Y `delegate_task` | Y `SKILL.md` (headline) | Y `config.yaml` | Y Skills Hub + pip plugins |

‡ **Roo Code's repo is ARCHIVED (read-only) since 2026-05-15** — users migrating to forks (Kilo Code). Deprioritize.

## 2 · Popularity — the integration-priority signal

Open-source (GitHub stars; ✔ = re-verified directly against api.github.com on 2026-07-18):

| Rank | Platform | Stars | Note |
|---|---|---|---|
| 1 | Hermes (`NousResearch/hermes-agent`) | **216,661** ✔ | created 2025-07-22; active |
| 2 | OpenCode (`anomalyco/opencode`, ex-`sst/opencode`) | **187,102** ✔ | active |
| 3 | Claude Code (`anthropics/claude-code`) | **138,162** ✔ | distribution/issue repo |
| 4 | Gemini CLI | ~100–104k | free API tier restricted Jun 2026 → enterprise pivot |
| 5 | Codex CLI (`openai/codex`) | **99,282** ✔ | 5M+ weekly users |
| 6 | Cline | 64,761 | active |
| 7 | Goose (`block/goose`) | 51,255 | ~60% internal Block adoption |
| 8 | Roo Code | 24,354 | ARCHIVED |

Closed-source (large reach; don't rank against the stars column): **Cursor** (1M+ DAU, ~$4B ARR — highest-reach editor) · **Windsurf/Devin Desktop** (Cognition; rebrand Jun 2026) · **Antigravity** (Google first-party, Gemini 3; "Antigravity 2.0" at I/O May 2026) · **Amp** (Sourcegraph; adoption UNKNOWN).

## 3 · Per-platform notes (packaging · paths · distribution · ambient mechanism · confidence)

**Claude Code** — `.claude-plugin/plugin.json` (+ `marketplace.json`) wrapping `skills/ commands/ agents/ hooks/hooks.json .mcp.json monitors/`. Paths `~/.claude/`, `.claude/`. Git-backed marketplaces. **Ambient: strongest** — 29 hook events, auto `CLAUDE.md` + `.claude/rules/`, model-invoked skills, `monitors/` background watchers. Docs: code.claude.com/docs/en/{plugins,hooks,skills,sub-agents,memory}. **High.** → [crib sheet](claude-code.md)

**Codex CLI** — `.codex-plugin/plugin.json` → `skills/ .mcp.json .app.json hooks`. Paths `~/.codex/` (config.toml, hooks.json, prompts/, agents/), `.codex/`, skills in `.agents/skills`. Git-backed marketplace (GA ~Mar 2026). **Ambient: yes** — `AGENTS.md` auto-inject, 10 hook events, implicit skills. Custom prompts DEPRECATED → skills. Docs: learn.chatgpt.com/docs/{plugins,hooks,build-skills,config-file/config-reference}. **High** (marketplace date partly third-party). → [crib sheet](codex.md)

**Antigravity** — "agy" plugin = namespaced dir with `plugin.json` (+ optional `mcp_config.json hooks.json skills/ agents/ rules/`; **no `commands/`**). Staged under `~/.gemini/antigravity-cli/plugins/<name>/`; project `.agents/`. **Ambient: yes** — auto `GEMINI.md`/`AGENTS.md` + Rules; hooks.json (PreToolUse/PostToolUse/PreInvocation/PostInvocation/Stop) + SDK hook points. **Medium confidence** — the docs site is a JS SPA unfetchable by tooling; several facts came from search-index snippets; the survey couldn't verify an install command or registry. The [crib sheet](antigravity.md) documents `agy plugin install <git-url>` and whole-repo staging from the agy CLI changelog (v1.1.4) — primary-source, researched for engram PR #8. → [crib sheet](antigravity.md)

**Gemini CLI** — `gemini-extension.json` wrapping `commands/ GEMINI.md mcpServers agents/ skills/ hooks/`. Paths `~/.gemini/extensions/`, `.gemini/`. Install: `gemini extensions install <github-url>`; official gallery geminicli.com/extensions/browse/. **Ambient: yes** — auto `GEMINI.md`, 11 hook events (BeforeTool, AfterTool, BeforeAgent, AfterAgent, BeforeModel, BeforeToolSelection, AfterModel, SessionStart, SessionEnd, Notification, PreCompress), auto MCP + skills. Docs: geminicli.com/docs/extensions/ + github.com/google-gemini/gemini-cli docs/hooks/reference.md. **High.**

**Cursor** — `.cursor-plugin/plugin.json` (+ `marketplace.json`) wrapping `rules/ skills/ agents/ commands/ hooks/ mcp.json` (Cursor 2.5, Feb 2026). Paths `.cursor/`, `~/.cursor/`. Dist: cursor.com/marketplace (`/add-plugin`, OAuth one-click), team marketplaces; plugins can be **"Required"** or **"Default On"** for teams. **Ambient: strongest of the editors** — auto rules + `AGENTS.md`, ~20 hook events incl. `workspaceOpen`/`beforeSubmitPrompt`/`beforeShellExecution`, auto skills. Docs: cursor.com/docs/{rules,hooks,subagents,skills,mcp,plugins}. **High.**

**Windsurf → Devin Desktop** (Cognition) — docs.windsurf.com now redirects to docs.devin.ai/desktop; rebrand via OTA Jun 2026, legacy Cascade EOL Jul 2026. **No bundle — loose files** under `.devin/` or `.windsurf/` (`rules/ workflows/ skills/ hooks.json`) + `~/.codeium/windsurf/`. Dist: git-committed files + MCP Plugin Store. **Ambient: yes** — auto rules/memories, 12 hook events (pre/post_read_code, pre/post_write_code, pre/post_run_command, pre/post_mcp_tool_use, pre_user_prompt, post_cascade_response, post_setup_worktree), auto skills. Workflows manual-only. Docs: docs.devin.ai/desktop/cascade/{hooks,workflows,memories,skills,mcp}. **High** (subagents Medium).

**Cline** — **No bundle — loose files**: `.clinerules/` (rules + `workflows/` + `hooks/`) + `.cline/skills/`; cross-tool `~/.agents/AGENTS.md`. Dist: MCP Marketplace (MCP servers only); rules/skills = git/manual. **Ambient: yes** — auto `.clinerules/`; hooks are executables named for their event in `.clinerules/hooks/` (TaskStart, PreToolUse, PostToolUse, UserPromptSubmit; PreToolUse can block). Docs: docs.cline.bot/features/{cline-rules,hooks/hook-reference,subagents}. **High** (hook names Medium-High — JS-rendered page).

**Roo Code** — ARCHIVED 2026-05-15. Loose `.roo/` (`rules/ rules-{mode}/ commands/ skills/ mcp.json`) + `.roomodes`. **Ambient: instruction-only — no hooks/event system.** Docs: roocodeinc.github.io/Roo-Code/. **High** (incl. archive status via API).

**DeepSeek Harness** — `@deepseek-ai/dsh`, Cordis everything-is-a-plugin, developer preview (2026-08). Native SKILL.md bundle skills from `~/.agents/skills` (+ project `.dsh/.agents` roots), AGENTS.md/CLAUDE.md instructions, unmodified-CC-hook bridge (JSON additionalContext only), subagent tool w/ CC/Codex drivers. Needs DEEPSEEK_API_KEY, no free tier. **Thinnest port class: zero adapter code.** → [crib sheet](dsh.md)

**ZCode (Z.ai)** — Claude Code-compatible by construction: `.zcode-plugin/plugin.json` (falls back to the `.claude-plugin/` name it also accepts) wrapping convention dirs; marketplaces read the Claude catalog directly from a GitHub repo. Paths `~/.zcode/cli/config.json`, `~/.zcode/skills`, legacy `~/.agents/skills`. Ambient: yes — 7 hook events incl. SessionStart (`startup|resume|clear|compact`) with **JSON-only stdout parsing** (non-conforming output is dropped *and* logged failed); exports BOTH `ZCODE_PLUGIN_ROOT` and `CLAUDE_PLUGIN_ROOT`. Generic Agent tool = fresh-context children; declared plugin agents diagnostic-only in 3.9.2. **High confidence on loader/hook facts** — verified against the shipped runtime bundle, not docs alone. **Thinnest port class.** → [crib sheet](zcode.md)

**OpenCode** — `opencode.json` + `.opencode/` convention; a plugin is a **JS/TS npm module** in the `"plugin": []` array. Paths `.opencode/{plugin,agent,command,skills}/`, `~/.config/opencode/`. Dist: npm + git; no GUI marketplace. **Ambient: strongest programmatic model** — auto `AGENTS.md`; hooks `tool.execute.before/after`, `shell.env`, `experimental.session.compacting`, plus a generic event bus (session.idle, file.edited, permission.asked, …). Docs: opencode.ai/docs/{plugins,agents,commands,rules,skills,mcp-servers,config}. **High.** → [crib sheet](opencode.md)

**Goose** (Block) — Recipe (`.yaml`: instructions, extensions, parameters, sub_recipes, response schema, retry) + Skill (`SKILL.md`) + Extension (= MCP). Paths `~/.config/goose/`. Dist: recipe deeplinks + `/recipes` cookbook + MCP registry. **Ambient: instruction-only — no generic lifecycle hooks.** Auto `.goosehints`/`AGENTS.md`, auto skills, auto MCP connect; recipes must be run. Docs: goose-docs.ai/docs/guides/. **High** ("no hooks" Medium-High).

**Amp** (Sourcegraph) — plugin = **a `.ts` file** in `.amp/plugins/` or `~/.config/amp/plugins/` (`registerTool`/`registerCommand`/`amp.on`); Skills (`.agents/skills/`) are the instruction unit. **Toolboxes DEPRECATED** → TS plugins. Dist: manual/git; no first-party marketplace. **Ambient: yes** — auto `AGENTS.md`, `amp.on` events (session.start, agent.start, agent.end, tool.call, tool.result), auto skills. Docs: ampcode.com/manual. **High** (adoption UNKNOWN).

**Hermes** (Nous Research) — plugin = `~/.hermes/plugins/<name>/plugin.yaml` + `__init__.py` `register(ctx)` (tools + hooks + CLI subcommands); lighter units = Skills (`SKILL.md`) + skill-bundles (`.yaml`). Paths: `~/.hermes/` (config.yaml with `hooks:`/`mcp_servers:`/`skills:`/`delegation:`, SOUL.md). Dist: Skills Hub / agentskills.io + pip entry-point plugins + git (⚠ hub staging severs shared cores — see crib sheet). **Ambient: strongest** — shell hooks + Python callbacks on `pre_llm_call`, `pre/post_tool_call`, `on_session_start/end/reset`, `pre_verify`, `on_error`, `pre/post_compress`; `SOUL.md` always loaded; auto skills. Docs: hermes-agent.nousresearch.com/docs/user-guide/features/{context-files,hooks,mcp}. **High.** → [crib sheet](hermes.md)

## 4 · The ambient shortlist

Ambient bar = the plugin acts on install with no command, via auto-loaded instructions and/or event hooks.

- **Tier A — full ambient** (auto-instructions + hooks that *run code* on events): Claude Code, Codex, Gemini CLI, Antigravity, Cursor, Windsurf/Devin, Cline, OpenCode, Amp, Hermes. **11 of 13.**
- **Tier B — instruction-only ambient** (rules/skills auto-load; no event execution): Roo Code (archived), Goose. **2 of 13.**
- **Command-only: none.** Every surveyed platform auto-loads at least one instruction file — a minimal ambient footprint is achievable everywhere.

## 5 · Cross-platform build levers

1. **The universal ambient substrate is the `AGENTS.md` family.** Identical instructions under **three filenames** cover all 13 platforms: `AGENTS.md` (Codex, Cursor, OpenCode, Goose, Amp, Antigravity, Hermes, Cline via `~/.agents/AGENTS.md`, Windsurf, ZCode) + `CLAUDE.md` (Claude Code — it does **not** read AGENTS.md) + `GEMINI.md` (Gemini CLI, Antigravity).
2. **Skills are near-universal: `SKILL.md` (agentskills.io) is supported by all 13** — model-invoked, semi-ambient (fires on description match). One folder is portable; several platforms cross-read each other's skill paths. This is why the omni-repo core is written as skills ([01 · Anatomy](../01-anatomy.md)).
3. **Hooks are the most powerful ambient lever and completely non-portable.** 10/12 support them; every schema, vocabulary, and config location differs. Budget a per-platform hook-adapter shim ([templates/session-hook.sh](../../templates/session-hook.sh)); the common denominators to target first: **pre/post-tool-use** and **session-start**.
4. **MCP is universal (12/12)** for shipping *tools*; auto-connects once configured; only the config path differs.
5. **Packaging is fragmented and will stay so.** Real manifests: Claude, Codex, Cursor, Gemini, Antigravity, OpenCode (npm), Hermes (plugin.yaml/pip). Loose-files platforms: Cline, Roo, Windsurf, Goose (+ Amp = one .ts file). Real marketplaces: Claude, Codex, Cursor, Gemini, Hermes, Goose (recipes); MCP-only: Cline, Roo; none: Amp. Design for the manifest platforms; the loose-file platforms get install docs instead.

## 6 · Known unknowns

- Antigravity: install command + registry existence unverified by this survey (SPA docs); the [crib sheet](antigravity.md) carries changelog-sourced answers.
- Codex marketplace launch date partly third-party.
- Amp adoption numbers unavailable (closed source).
- Windsurf subagent story rides the Devin Local successor — blog-sourced, Medium confidence.
