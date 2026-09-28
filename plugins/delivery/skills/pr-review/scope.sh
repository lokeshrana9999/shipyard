#!/usr/bin/env bash
# Scope a change for pr-review. Portable: POSIX awk, no GNU-only flags.
#
# usage: scope.sh <worktree> <base-ref> <out-dir> [path ...]
#        scope.sh --diff <unified-diff-file> <out-dir> [path ...]
#
# <base-ref> is any ref git can resolve (main, origin/main, a sha); a bare branch
# name that only exists on origin is tried as origin/<name>.
# Paths are the review paths from the project settings (default: everything).
# A path starting with ':!' is excluded (git pathspec syntax), e.g. ':!docs/'.
#
# Writes <out-dir>/full.diff (unified diff, 3 lines of context) and
# <out-dir>/diff.txt (added lines only, one per line as "path:line: code").
# Prints "files=N added=M", then "No changes to review." when M is 0.
set -eu

usage() {
  echo "usage: scope.sh <worktree> <base-ref> <out-dir> [path ...]" >&2
  echo "       scope.sh --diff <unified-diff-file> <out-dir> [path ...]" >&2
  exit 2
}

[ $# -ge 3 ] || usage

if [ "$1" = "--diff" ]; then
  SRC=$2
  OUT=$3
  shift 3
  [ -f "$SRC" ] || { echo "scope.sh: no such diff file: $SRC" >&2; exit 2; }
  mkdir -p "$OUT"
  cp "$SRC" "$OUT/full.diff.in"
  MODE=file
else
  WT=$1
  BASE=$2
  OUT=$3
  shift 3
  if ! git -C "$WT" rev-parse --verify --quiet "$BASE^{commit}" >/dev/null; then
    if git -C "$WT" rev-parse --verify --quiet "origin/$BASE^{commit}" >/dev/null; then
      BASE="origin/$BASE"
    else
      echo "scope.sh: base ref '$BASE' does not resolve in $WT" >&2
      exit 2
    fi
  fi
  mkdir -p "$OUT"
  # Three-dot diff: only what the branch adds since it left the base.
  if [ $# -gt 0 ]; then
    # Rewrite review paths into top-relative pathspecs; ':!x' becomes an exclude.
    n=$#
    has_include=0
    for p in "$@"; do
      case "$p" in
        ":!"*) set -- "$@" ":(top,exclude)${p#:!}" ;;
        .|./) set -- "$@" ":(top)"; has_include=1 ;;
        *) set -- "$@" ":(top)$p"; has_include=1 ;;
      esac
    done
    shift "$n"
    # Only excludes given: include everything else.
    [ "$has_include" -eq 1 ] || set -- ":(top)" "$@"
    git -C "$WT" diff --no-color --no-ext-diff --unified=3 "$BASE...HEAD" -- "$@" > "$OUT/full.diff.in"
  else
    git -C "$WT" diff --no-color --no-ext-diff --unified=3 "$BASE...HEAD" > "$OUT/full.diff.in"
  fi
  MODE=git
  set --
fi

# In --diff mode the path filter is applied here, by prefix; git mode already filtered.
FILTER=""
if [ "$MODE" = file ]; then
  for p in "$@"; do FILTER="$FILTER$p
"; done
fi

# Split the diff per file, keep files that pass the filter, and emit
# "path:line: code" for every added line. Hunk line counts decide what is
# content, so an added line that starts with "++" is never read as a header.
awk -v filter="$FILTER" -v full="$OUT/full.diff" -v files_out="$OUT/files.txt" '
  function keep(path,   n, i, pats, p, inc, has_inc, exc) {
    if (filter == "") return 1
    n = split(filter, pats, "\n")
    inc = 0; has_inc = 0; exc = 0
    for (i = 1; i <= n; i++) {
      p = pats[i]
      if (p == "") continue
      if (substr(p, 1, 2) == ":!") {
        p = substr(p, 3)
        if (index(path, p) == 1) exc = 1
      } else {
        has_inc = 1
        if (p == "." || index(path, p) == 1) inc = 1
      }
    }
    if (exc) return 0
    return has_inc ? inc : 1
  }
  function flush() {
    if (buf != "" && keep(cur)) { printf "%s", buf > full; if (cur != "") print cur > files_out }
    buf = ""
  }
  /^diff --git / && oldleft <= 0 && newleft <= 0 {
    flush(); cur = $0; sub(/^diff --git a\/.* b\//, "", cur); buf = $0 "\n"; next
  }
  oldleft <= 0 && newleft <= 0 && /^\+\+\+ / {
    p = substr($0, 5); sub(/\t.*$/, "", p)
    if (p != "/dev/null") { sub(/^b\//, "", p); cur = p }
    buf = buf $0 "\n"; next
  }
  oldleft <= 0 && newleft <= 0 && /^--- / {
    p = substr($0, 5); sub(/\t.*$/, "", p)
    if (p != "/dev/null" && cur == "") { sub(/^a\//, "", p); cur = p }
    buf = buf $0 "\n"; next
  }
  /^@@ / {
    split($2, o, ","); split($3, a, ",")
    oldleft = (o[2] == "") ? 1 : o[2] + 0
    newleft = (a[2] == "") ? 1 : a[2] + 0
    n = substr(a[1], 2) + 0
    buf = buf $0 "\n"; next
  }
  {
    buf = buf $0 "\n"
    if (oldleft <= 0 && newleft <= 0) next
    c = substr($0, 1, 1)
    if (c == "+") { added[++na] = cur SUBSEP n SUBSEP substr($0, 2); n++; newleft-- }
    else if (c == "-") { oldleft-- }
    else if (c == " " || $0 == "") { n++; oldleft--; newleft-- }
  }
  END {
    flush()
    for (i = 1; i <= na; i++) {
      split(added[i], parts, SUBSEP)
      if (keep(parts[1])) print parts[1] ":" parts[2] ": " parts[3]
    }
  }
' "$OUT/full.diff.in" > "$OUT/diff.txt"
rm -f "$OUT/full.diff.in"
[ -f "$OUT/full.diff" ] || : > "$OUT/full.diff"
[ -f "$OUT/files.txt" ] || : > "$OUT/files.txt"

FILES=$(sort -u "$OUT/files.txt" | awk 'END { print NR }')
ADDED=$(awk 'END { print NR }' "$OUT/diff.txt")
rm -f "$OUT/files.txt"
echo "files=$FILES added=$ADDED"
if [ "$ADDED" -eq 0 ]; then
  echo "No changes to review."
fi
