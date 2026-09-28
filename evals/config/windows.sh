# Platform config for Windows, sourced by scripts/run-evals.sh (not run on its own).
#
# Recommended: run the evals inside WSL2 (Ubuntu with `bubblewrap` and `socat`) with the
# WSL-installed CLI. Native Windows has no sandbox backend, so any case that grants Bash is
# refused there (score 0.00, $0.00, no agent started).
#
#   wsl bash scripts/run-evals.sh plugins/delivery --case boots-and-verifies --scaffold --allow-tools Bash Write
#
# Never run `claude install` or `claude update` inside WSL.
#
# Under WSL the sandbox pre-flight refuses every run when:
#   - PATH holds Windows directories (WSL appends them; some can't be listed: "a PATH directory
#     could not be examined for keychain credential helpers (EACCES)"). Fix: Linux-only PATH below.
#   - ~/.docker holds symlinks (Docker Desktop's WSL integration links `contexts` and
#     `features.json` to /mnt/c/Users/<you>/.docker). Setting DOCKER_CONFIG to an empty dir
#     doesn't help. Fix: eval_pre moves ~/.docker aside for the run; eval_post always puts it back.
#
# From native Windows (Git Bash), cases without Bash still run: `bash scripts/run-evals.sh ...`.
# --scaffold needs Git's bash ahead of WSL's System32\bash.exe on PATH, or fixtures exit 127;
# this config puts Git's /usr/bin first.

if [ "${EVAL_WSL:-0}" = 1 ]; then
  CLAUDE_BIN="$HOME/.local/bin/claude"
  export PATH="/usr/local/bin:/usr/bin:/bin:$HOME/.local/bin"

  DOCKER_DIR="$HOME/.docker"
  DOCKER_ASIDE="$HOME/.docker.eval-aside"
  DOCKER_MOVED=0

  eval_pre() {
    [ -x "$CLAUDE_BIN" ] || { echo "error: $CLAUDE_BIN not found (install the CLI inside WSL)" >&2; return 1; }
    if [ -e "$DOCKER_ASIDE" ]; then
      echo "error: $DOCKER_ASIDE already exists; a previous run didn't restore it. Move it back to $DOCKER_DIR first." >&2
      return 1
    fi
    if [ -e "$DOCKER_DIR" ] || [ -L "$DOCKER_DIR" ]; then
      mv "$DOCKER_DIR" "$DOCKER_ASIDE" || return 1
      DOCKER_MOVED=1
      echo "moved $DOCKER_DIR aside for this run" >&2
    fi
  }

  eval_post() {
    [ "$DOCKER_MOVED" = 1 ] || return 0
    [ -e "$DOCKER_ASIDE" ] || [ -L "$DOCKER_ASIDE" ] || return 0
    if [ -e "$DOCKER_DIR" ] || [ -L "$DOCKER_DIR" ]; then
      # Something recreated ~/.docker during the run; keep both rather than nest one in the other.
      local kept
      kept="$DOCKER_DIR.recreated-$(date +%s)"
      mv "$DOCKER_DIR" "$kept"
      echo "warning: $DOCKER_DIR was recreated during the run; kept it as $kept" >&2
    fi
    mv "$DOCKER_ASIDE" "$DOCKER_DIR" && echo "restored $DOCKER_DIR" >&2
  }
else
  # Git Bash / MSYS: make sure scaffold scripts get Git's bash, not WSL's System32\bash.exe.
  export PATH="/usr/bin:$PATH"
  echo "note: native Windows has no eval sandbox; cases that grant Bash will be refused. Use WSL for those." >&2
fi
