# Plain git steps

The commands behind SKILL.md steps 1 to 5, in plain git so they run in any checkout on any host. `R` is the remote (default `origin`), `BASE` the base branch, `BR` the branch, `HEAD_SHA` the branch tip. Read this file; run the commands it shows.

## 1 preconditions and lock

| Check | Command | On failure, report |
|---|---|---|
| inside a repo | `git rev-parse --is-inside-work-tree` | not a git checkout; stop |
| clean tree | `git status --porcelain` prints nothing | `uncommitted changes in <files>. cause: a sync would mix them into the merge. fix: commit or stash them, then run land again` |
| git identity | `git config user.name` and `git config user.email` both print | `no git identity. cause: merge commits need an author. fix: git config --global user.name "<name>" and git config --global user.email "<email>"` |
| remote | `git remote get-url R` | `remote R missing. fix: git remote add R <url>` |
| branch exists on the remote | `git ls-remote --heads R BR` prints a line | `BR is not pushed. fix: git push -u R BR` |

Lock: the file `.git/shipyard-land.lock` holding `<branch> <utc time> <pid or session>`. Create it only if it does not exist (`set -o noclobber` in a POSIX shell, or check then write). If it exists, read it: a lock younger than the stale age stops this run with its holder quoted; an older one is reported as stale and removed only after the user says yes. Remove the lock on every exit, in a trap or the last step, including after a failure.

## 2 sync the base into the branch

```sh
git fetch R BASE BR
BASE_BEFORE=$(git rev-parse R/BASE)
git merge-base --is-ancestor R/BASE HEAD && echo "already synced"
```

Not synced, strategy `merge` or `squash`: `git merge --no-edit R/BASE`. Strategy `rebase`: `git rebase R/BASE`. A conflict: `git merge --abort` (or `git rebase --abort`), list the files from `git diff --name-only --diff-filter=U` taken before the abort, verdict `not merged`, `next:` implement.

When the checkout is not on `BR` or is dirty, do the same in a temporary worktree: `git worktree add --detach <tmp dir> R/BR`, run the merge there with `-C <tmp dir>`, then `git push R HEAD:refs/heads/BR` from it (after a rebase the branch moved, so push with `--force-with-lease=refs/heads/BR:<old BR sha>`, never bare `--force`), and `git worktree remove --force <tmp dir>`.

Then push the synced branch: `git push R BR`.

## 3 did the base move during the gate?

```sh
git fetch R BASE
[ "$(git rev-parse R/BASE)" = "$BASE_BEFORE" ] || echo "base moved"
```

Moved: back to step 2 with the count incremented; past the cap, stop with `not merged` and both shas in the report.

## 4 merge with plain git

Used when no pull request is open or the host's CLI is not signed in; otherwise the host's merge call does this and the read-back below still runs. Work in a temporary worktree so the user's checkout never switches branch:

```sh
W=<tmp dir>
git worktree add --detach "$W" R/BASE
git -C "$W" merge --no-ff --no-edit -m "Merge BR into BASE" HEAD_SHA        # strategy merge
git -C "$W" merge --squash HEAD_SHA && git -C "$W" commit -m "<title>"       # strategy squash
git -C "$W" merge --ff-only HEAD_SHA                                         # strategy rebase (BR was rebased in step 2)
MERGE_SHA=$(git -C "$W" rev-parse HEAD)
git -C "$W" push R HEAD:refs/heads/BASE
git worktree remove --force "$W"
```

`push` is a plain fast-forward push with no force flag, so a remote whose base moved rejects it (`! [rejected] ... (fetch first)` or `non-fast-forward`). That rejection means the base moved: remove the worktree and go back to step 2, counting toward the cap.

## 5 read the merge back

```sh
git fetch R BASE
[ "$(git rev-parse R/BASE)" = "$MERGE_SHA" ] && echo "landed $MERGE_SHA"
```

A mismatch is an andon: report both shas, change nothing more.

## failures and their fixes

| Symptom | Cause | Fix to report |
|---|---|---|
| `Author identity unknown` / `Please tell me who you are` | no `user.name` or `user.email` | the two `git config --global` commands |
| `fatal: Unable to create '.git/index.lock': File exists` | another git process, or a crashed one | wait for it; if no git is running, remove `.git/index.lock` |
| `! [rejected] ... non-fast-forward` on the base | the base moved | re-sync (step 2); past the cap, stop |
| `! [rejected] ... stale info` on the branch | the branch moved on the remote since the fetch | fetch and re-sync; never bare `--force` |
| `CONFLICT (content)` | the branch and the base changed the same lines | abort, verdict `not merged`, files listed, `next:` implement |
| `fatal: '<tmp dir>' is a missing but already registered worktree` | a previous run died with its worktree registered | `git worktree prune`, then retry |
| `error: cannot lock ref '<ref>'` | a `.lock` file beside that ref, left by a crashed git | when no git is running, remove the named `<ref>.lock` file under `.git/`, then retry |
| protected branch refuses the push | the host requires merging through its pull request | merge through the host's CLI instead; say so |
