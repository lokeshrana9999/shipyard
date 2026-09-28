#!/usr/bin/env bash
# Runs `claude plugin eval` for one plugin. Works as-is on Linux and macOS.
#
#   bash scripts/run-evals.sh <plugin dir> [claude plugin eval args...]
#   e.g. bash scripts/run-evals.sh plugins/shipyard-delivery --tag ship --ablation none -j 3
#
# Eval cases live outside the shipped plugin, in evals/<plugin name>/ at the repo root, so the
# published plugin carries no fixtures. `claude plugin eval` reads cases only from a directory
# below the plugin, so the runner stages a copy: it copies the plugin to
# $EVAL_STAGE_DIR/<plugin name>/ (default: ${TMPDIR:-/tmp}/shipyard-eval-stage), copies the
# cases into its evals/ (without results/), and runs there. The stage path is stable across
# runs, so the first-run trust prompt is asked once per machine (or pass --trust-plugin).
# Results go to evals/<plugin name>/results/<timestamp>/ unless you pass --output-dir.
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

PLUGIN_DIR="$(cd "$PLUGIN_DIR" && pwd)"
PLUGIN_NAME="$(basename "$PLUGIN_DIR")"
CASES_DIR="$REPO_ROOT/evals/$PLUGIN_NAME"
[ -d "$CASES_DIR" ] || { echo "error: no eval cases at ${CASES_DIR#"$REPO_ROOT"/}" >&2; exit 64; }

STAGE_ROOT="${EVAL_STAGE_DIR:-${TMPDIR:-/tmp}/shipyard-eval-stage}"
STAGE="$STAGE_ROOT/$PLUGIN_NAME"
rm -rf "$STAGE" && mkdir -p "$STAGE" || { echo "error: cannot create stage dir $STAGE" >&2; exit 1; }
# Copy the plugin (minus any evals/ it might have) and the cases (minus results/).
( cd "$PLUGIN_DIR" && tar cf - --exclude=./evals . ) | ( cd "$STAGE" && tar xf - ) || exit 1
mkdir -p "$STAGE/evals"
( cd "$CASES_DIR" && tar cf - --exclude=./results . ) | ( cd "$STAGE/evals" && tar xf - ) || exit 1

# Keep results in the repo (git-ignored), not in the throwaway stage.
HAS_OUTPUT_DIR=0
for a in "$@"; do case "$a" in --output-dir|--output-dir=*) HAS_OUTPUT_DIR=1 ;; esac; done
OUT_ARGS=()
if [ "$HAS_OUTPUT_DIR" = 0 ]; then
  OUT_ARGS=(--output-dir "$CASES_DIR/results/$(date -u +%Y-%m-%dT%H-%M-%SZ)")
fi

echo "staged ${PLUGIN_DIR#"$REPO_ROOT"/} + evals/$PLUGIN_NAME at $STAGE" >&2
cd "$STAGE" || exit 1
# ${arr[@]+...} keeps an empty array safe under `set -u` on bash 3.2 (macOS).
"$CLAUDE_BIN" plugin eval . ${EVAL_DEFAULT_ARGS[@]+"${EVAL_DEFAULT_ARGS[@]}"} ${OUT_ARGS[@]+"${OUT_ARGS[@]}"} "$@"
