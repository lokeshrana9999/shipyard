#!/usr/bin/env bash
# Runs `claude plugin eval` for one plugin. Works as-is on Linux and macOS.
#
#   bash scripts/run-evals.sh <plugin dir> [claude plugin eval args...]
#   e.g. bash scripts/run-evals.sh plugins/delivery --tag ship --ablation none -j 3
#
# Platform config: the runner detects the platform (linux, macos, windows; WSL and Git Bash
# count as windows) and, if evals/config/<platform>.sh exists at the repo root, sources it
# before the run. A config may:
#   - export env vars (PATH, ...) and set CLAUDE_BIN (default: `claude` on PATH)
#   - set EVAL_DEFAULT_ARGS=(...) : flags placed before the ones given on the command line
#   - define eval_pre  : runs before the eval; a non-zero return aborts the run
#   - define eval_post : always runs once afterwards (success, failure, Ctrl-C), via trap
# Override detection with EVAL_PLATFORM=<name>. The runner exports EVAL_PLATFORM and
# EVAL_WSL (1 under WSL, else 0) for the config to use.

set -u

usage() { echo "usage: $0 <plugin dir> [claude plugin eval args...]" >&2; exit 64; }
[ $# -ge 1 ] || usage

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLUGIN_DIR="$1"; shift
[ -d "$PLUGIN_DIR" ] || { echo "error: plugin dir not found: $PLUGIN_DIR" >&2; exit 64; }

EVAL_WSL=0
if [ -r /proc/version ] && grep -qi microsoft /proc/version; then EVAL_WSL=1; fi
detect_platform() {
  case "$(uname -s)" in
    Linux) if [ "$EVAL_WSL" = 1 ]; then echo windows; else echo linux; fi ;;
    Darwin) echo macos ;;
    MINGW*|MSYS*|CYGWIN*) echo windows ;;
    *) echo unknown ;;
  esac
}
EVAL_PLATFORM="${EVAL_PLATFORM:-$(detect_platform)}"
export EVAL_PLATFORM EVAL_WSL REPO_ROOT

# Defaults a config may override.
CLAUDE_BIN="${CLAUDE_BIN:-claude}"
EVAL_DEFAULT_ARGS=()
eval_pre() { :; }
eval_post() { :; }

CONFIG="$REPO_ROOT/evals/config/$EVAL_PLATFORM.sh"
if [ -f "$CONFIG" ]; then
  # shellcheck source=/dev/null
  . "$CONFIG" || { echo "error: failed to load $CONFIG" >&2; exit 1; }
  echo "platform $EVAL_PLATFORM: loaded ${CONFIG#"$REPO_ROOT"/}" >&2
fi

POST_DONE=0
run_post() {
  [ "$POST_DONE" = 1 ] && return 0
  POST_DONE=1
  eval_post
}
trap run_post EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP

eval_pre || { echo "error: eval_pre failed; not running evals" >&2; exit 1; }

command -v "$CLAUDE_BIN" >/dev/null 2>&1 || { echo "error: claude CLI not found: $CLAUDE_BIN" >&2; exit 127; }
cd "$PLUGIN_DIR" || exit 1
# ${arr[@]+...} keeps an empty array safe under `set -u` on bash 3.2 (macOS).
"$CLAUDE_BIN" plugin eval . ${EVAL_DEFAULT_ARGS[@]+"${EVAL_DEFAULT_ARGS[@]}"} "$@"
