#!/usr/bin/env bash
# Ambient session hook — the omni-platform reference pattern.
# Distilled from engram's hooks/session-start.sh + session-start-hermes.sh
# (the latter shipped only after review found it failing open twice — every
# guard below is there because its absence was a real bug).
#
# The contract (memorize it):
#   1. SELF-RESOLVING  — works from any staging path, env var or not.
#   2. SILENT-UNLESS-USEFUL — prints nothing when there is nothing to say.
#   3. DEGRADE TO SILENCE — on ANY failure: silence. Never an error,
#      never a repeat. "Silence over repetition."
#   4. FAIL CLOSED on dedupe — can't identify the session? At most once
#      per process. Never once per call.
#   5. exit 0, always. A hook must never break a session.
#
# Adapt per platform:
#   - Claude Code / Codex SessionStart: plain stdout, no dedupe needed
#     (the platform fires it once per session).
#   - Hermes pre_llm_call: JSON protocol + dedupe (fires per LLM call!) —
#     see the dual-mode variant below.
#   - Platform-specific command spellings: rewrite YOUR OWN strings
#     (e.g. sed 's|/learn|/skill learn|g') in EVERY output path.
#   - One file, two runner contracts (engram v1.15, ZCode): if a host parses stdout
#     as JSON-only — and logs non-conforming runs FAILED — branch the OUTPUT FORMAT
#     inside this script on an observable env property ($PLATFORM_ROOT / a forced
#     FORMAT var). Never duplicate the registration; pitfalls #22–23.

set -u
command -v python3 >/dev/null 2>&1 || exit 0                     # missing runtime → silence

# --- Root resolution: waterfall, then landmark (own location) ---------------
ROOT="${YOURPLUGIN_ROOT:-${OPENCODE_PLUGIN_ROOT:-${CLAUDE_PLUGIN_ROOT:-${CODEX_PLUGIN_ROOT:-}}}}"
if [ -z "$ROOT" ] || [ ! -f "$ROOT/scripts/engine.py" ]; then
  ROOT="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")/.." 2>/dev/null && pwd)"
fi
[ -f "$ROOT/scripts/engine.py" ] || exit 0                       # still lost → silence

# --- The nudge: engine decides; empty output means say nothing --------------
python3 "$ROOT/scripts/engine.py" session-start 2>/dev/null || true
exit 0

# =============================================================================
# DUAL-MODE VARIANT (JSON hook protocol + cron/plain delivery), for platforms
# like Hermes where the same script serves pre_llm_call AND no-agent cron:
#
#   payload="$(cat - 2>/dev/null || true)"
#
#   # Plain mode (empty stdin): print the nudge verbatim; no dedupe —
#   # each scheduled run SHOULD deliver. Nothing when nothing is due.
#   if [ -z "$payload" ]; then emit_nudge; exit 0; fi
#
#   # Hook mode: dedupe once per session. Extract session_id defensively;
#   # if extraction fails, fall back to "pid-${PPID}" so the guard fails
#   # CLOSED (once per host process), never OPEN (once per call).
#   #   marker="${TMPDIR:-/tmp}/yourplugin-nudge-${session_id}"
#   #   [ -e "$marker" ] && { printf '{}\n'; exit 0; }
#   #   : > "$marker" 2>/dev/null || { printf '{}\n'; exit 0; }   # unwritable → silence
#   # Emit {"context": "<nudge>"} or {} — valid JSON on every path.
#
# And ship a failure battery with it (engram's has 9 cases): missing python,
# unset env, unresolvable root, empty payload, garbage JSON, empty session_id,
# unwritable TMPDIR, second call same session, plain-mode cron call.
# =============================================================================
