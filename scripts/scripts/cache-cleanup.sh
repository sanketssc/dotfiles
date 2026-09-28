#!/bin/bash
# cache-cleanup.sh — trim dev caches by age/size (LRU-style). Never wipes a cache wholesale.
#   --dry-run  (default) report each target, its size, and what would be freed
#   --apply    delete; output appended to ~/Library/Logs/cache-cleanup.log
# Scheduled every 3h by ~/Library/LaunchAgents/dev.sanket.cache-cleanup.plist.
# Written for macOS /bin/bash 3.2 and BSD userland (PATH is pinned below).

set -uo pipefail
export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin
export LC_ALL=C

case "${1:---dry-run}" in
  --dry-run) MODE=dry-run ;;
  --apply) MODE=apply ;;
  -h | --help) sed -n '2,6p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  *) echo "usage: $0 [--dry-run|--apply]" >&2; exit 2 ;;
esac

# Re-exec once at background priority (throttled CPU + disk IO).
if [ -z "${CACHE_CLEANUP_BG:-}" ]; then
  export CACHE_CLEANUP_BG=1
  shopt -s execfail
  [ -x /usr/sbin/taskpolicy ] && exec /usr/sbin/taskpolicy -b /bin/bash "$0" "$@"
  exec /usr/bin/nice -n 19 /bin/bash "$0" "$@"
fi

# ---------------------------------------------------------------- config
U=$(id -un)
LOG="$HOME/Library/Logs/cache-cleanup.log"
LOG_MAX=1048576  # truncate log above 1 MB ...
LOG_KEEP=524288  # ... keeping the newest 512 KB
STATE="$HOME/Library/Caches/cache-cleanup"

MONO="$HOME/Documents/matiks/matiks-monorepo"
CLIENT="$HOME/Documents/matiks/matiks-client"
DISK_CACHE="$HOME/.cache/bazel-disk-cache"
BZ_ROOT="$HOME/Library/Caches/bazel/_bazel_$U"
BZ_MAIN_OB="$BZ_ROOT/$(printf %s "$MONO" | md5)"
BZ_CA="$BZ_ROOT/cache/repos/v1/content_addressable"
GRADLE="$HOME/.gradle"
GOCACHE_DIR="$HOME/Library/Caches/go-build"
GOMOD="$HOME/go/pkg/mod"
NPM="$HOME/.npm"
DERIVED="$HOME/Library/Developer/Xcode/DerivedData"
SIM_DEVICES="$HOME/Library/Developer/CoreSimulator/Devices"
TMPD=$(getconf DARWIN_USER_TEMP_DIR 2>/dev/null)
TMPD=${TMPD%/}
[ -d "$TMPD" ] || TMPD=${TMPDIR:-/tmp}
TMPD=${TMPD%/}

DISK_CACHE_AGE_D=7
DISK_CACHE_CAP_KB=$((40 * 1024 * 1024))
BZ_CA_AGE_D=30
GRADLE_VER_AGE_D=30
GRADLE_LOG_AGE_D=7
GOCACHE_AGE_D=5
NPX_AGE_D=14
NPM_VERIFY_EVERY_MIN=1440
DERIVED_AGE_D=7
METRO_AGE_D=3
TRASH_AGE_MIN=1440
WT_BUILD_AGE_D=2

# Deletion guard (see path_ok): a path may be deleted only if it is strictly
# inside ALLOWED_ROOTS (or listed in ALLOWED_EXACT), is not inside NO_DESCEND,
# and is not NO_ANCESTOR itself or a parent of it.
ALLOWED_ROOTS=("$DISK_CACHE" "$BZ_ROOT" "$GRADLE" "$GOCACHE_DIR" "$NPM/_npx" "$DERIVED" "$TMPD"
  "$MONO/.git/wt/trash" "$CLIENT/.git/wt/trash")
ALLOWED_EXACT=("")
NO_DESCEND=("$HOME/.claude" "$BZ_MAIN_OB" "$BZ_ROOT/install" "$BZ_ROOT/cache/repos/v1/contents" "$GOMOD"
  "$CLIENT/android/app/build" "$CLIENT/android/app/.cxx")
NO_ANCESTOR=("${NO_DESCEND[@]}" "${ALLOWED_ROOTS[@]}" "$MONO" "$CLIENT" "$BZ_ROOT/cache")

# ---------------------------------------------------------------- setup
START=$(date +%s)
TOTAL_FREED=0
WORK=$(mktemp -d "$TMPD/cache-cleanup.XXXXXX") || exit 1
LOCK=""
trap 'rm -rf "$WORK" ${LOCK:+"$LOCK"}' EXIT
trap 'exit 130' INT TERM

if [ "$MODE" = apply ]; then
  LOCK="$TMPD/cache-cleanup.lock"
  if ! mkdir "$LOCK" 2>/dev/null; then
    opid=$(cat "$LOCK/pid" 2>/dev/null)
    if [ -n "$opid" ] && kill -0 "$opid" 2>/dev/null; then
      LOCK="" # not ours; leave it
      echo "$(date '+%F %T') another run (pid $opid) in progress; exiting" >>"$LOG"
      exit 0
    fi
    rm -rf "$LOCK" && mkdir "$LOCK" || exit 1
  fi
  echo $$ >"$LOCK/pid"

  mkdir -p "${LOG%/*}" "$STATE"
  if [ -f "$LOG" ] && [ "$(stat -f %z "$LOG")" -gt "$LOG_MAX" ]; then
    # Truncate in place (same inode, so launchd's open stdout stays valid).
    tail -c "$LOG_KEEP" "$LOG" | sed '1d' >"$WORK/log.tail"
    { echo "... (older entries truncated)"; cat "$WORK/log.tail"; } >"$LOG"
  fi
  if [ -t 1 ]; then exec > >(tee -a "$LOG") 2>&1; else exec >>"$LOG" 2>&1; fi
fi

# ---------------------------------------------------------------- helpers
hsize() {
  awk -v k="${1:-0}" 'BEGIN { if (k >= 1048576) printf "%.1fG", k / 1048576
    else if (k >= 1024) printf "%.0fM", k / 1024; else if (k > 0) printf "%dK", k; else printf "0" }'
}

du_kb() { # total allocated KB of the given paths (missing paths count 0)
  local t=0 p s
  for p in "$@"; do
    [ -e "$p" ] || continue
    s=$(du -sk "$p" 2>/dev/null | awk '{ print $1 }')
    t=$((t + ${s:-0}))
  done
  echo "$t"
}

list_kb() { # allocated KB of a NUL-separated file list
  [ -s "$1" ] || { echo 0; return; }
  xargs -0 stat -f %b <"$1" 2>/dev/null | awk '{ s += $1 } END { printf "%d\n", s / 2 }'
}

list_n() { [ -s "$1" ] && tr -cd '\0' <"$1" | wc -c | tr -d ' ' || echo 0; }

newer_than() { # DIR FIND-TIME-ARGS... -> 0 if anything under DIR matches
  local d=$1
  shift
  [ -n "$(find "$d" "$@" -print -quit 2>/dev/null)" ]
}

path_ok() {
  local p=$1 r
  case "$p" in '' | */../* | */.. | */./* | */.) return 1 ;; esac
  for r in "${NO_ANCESTOR[@]}"; do case "$r/" in "$p"/*) return 1 ;; esac; done
  for r in "${NO_DESCEND[@]}"; do case "$p" in "$r" | "$r"/*) return 1 ;; esac; done
  for r in "${ALLOWED_EXACT[@]}"; do [ -n "$r" ] && [ "$p" = "$r" ] && return 0; done
  for r in "${ALLOWED_ROOTS[@]}"; do case "$p" in "$r"/?*) return 0 ;; esac; done
  return 1
}

rm_tree() { # delete one file/dir tree after the guard check
  path_ok "$1" || { detail "! refused (guard): $1"; return 1; }
  [ "$MODE" = apply ] || return 0
  # Some caches (Go modules inside bazel repos, etc.) have read-only dirs.
  find "$1" -type d ! -perm -u+w -exec chmod u+w {} + 2>/dev/null
  rm -rf -- "$1"
}

rm_list() { # NUL-separated file list; every entry must be inside ROOT
  [ "$MODE" = apply ] && [ -s "$1" ] || return 0
  if tr '\0' '\n' <"$1" | awk -v r="$2/" 'index($0, r) != 1 { bad = 1 } END { exit !bad }'; then
    detail "! refused (guard): list has paths outside $2"
    return 1
  fi
  xargs -0 rm -f -- <"$1"
}

detail() { printf '    %s\n' "$*" >>"$WORK/details"; }

row() { # NAME BEFORE_KB FREED_KB NOTE
  local after=$(($2 - $3))
  [ "$after" -lt 0 ] && after=0
  if [ "$MODE" = apply ]; then
    printf '%-20s %7s -> %7s  freed %7s  %s\n' "$1" "$(hsize "$2")" "$(hsize "$after")" "$(hsize "$3")" "$4"
  else
    printf '%-20s %7s  would free %7s  %s\n' "$1" "$(hsize "$2")" "$(hsize "$3")" "$4"
  fi
  flush_details
  TOTAL_FREED=$((TOTAL_FREED + $3))
}

info_row() { printf '%-20s %7s  %s\n' "$1" "$2" "$3"; flush_details; }

flush_details() {
  [ -s "$WORK/details" ] || return 0
  cat "$WORK/details"
  : >"$WORK/details"
}

busy_bazel() { pgrep -x bazel >/dev/null || pgrep -x bazelisk >/dev/null; } # client only; idle server is "bazel(<ws>)"
busy_gradle() { pgrep -f 'org\.gradle\.wrapper\.GradleWrapperMain|org\.gradle\.launcher\.GradleMain' >/dev/null; }
busy_go() { pgrep -f '(^|/)go (build|test|run|install|vet|generate)( |$)' >/dev/null; }
busy_xcode() { pgrep -x xcodebuild >/dev/null; }
busy_npm() { pgrep -f '(^|/)(npm|npm-cli\.js|pnpm|yarn) (install|i|ci|add|update)( |$)' >/dev/null; }

with_timeout() { # SECS CMD... (gtimeout when present)
  local s=$1
  shift
  if [ -x /opt/homebrew/bin/gtimeout ]; then /opt/homebrew/bin/gtimeout "$s" "$@"; else "$@"; fi
}

# ---------------------------------------------------------------- targets

t_bazel_disk_cache() {
  local name=bazel-disk-cache sorted="$WORK/dc.sorted" del="$WORK/dc.del" total res freed n_age n_lru
  [ -d "$DISK_CACHE" ] || { info_row "$name" - "absent"; return; }
  busy_bazel && { info_row "$name" - "skipped: busy (bazel build running)"; return; }
  # last use = max(atime, mtime); oldest first
  find "$DISK_CACHE/ac" "$DISK_CACHE/cas" -type f -print0 2>/dev/null |
    xargs -0 stat -f '%a %m %b %N' 2>/dev/null |
    awk '{ u = ($1 > $2) ? $1 : $2; p = $0; sub(/^[^ ]+ [^ ]+ [^ ]+ /, "", p); print u, $3, p }' |
    sort -n -k1,1 >"$sorted"
  total=$(awk '{ s += $2 } END { printf "%d\n", s / 2 }' "$sorted")
  # Age pass (> 7d), then LRU until under cap. Sorted input makes both one walk.
  res=$(awk -v cut=$((START - DISK_CACHE_AGE_D * 86400)) -v cap="$DISK_CACHE_CAP_KB" -v t="$total" -v out="$del.nl" '
    { kb = $2 / 2; old = ($1 < cut)
      if (old || t > cap) { t -= kb; f += kb; if (old) na++; else nl++
        p = $0; sub(/^[^ ]+ [^ ]+ /, "", p); print p > out } }
    END { printf "%d %d %d\n", f, na, nl }' "$sorted")
  read -r freed n_age n_lru <<<"$res"
  [ -f "$del.nl" ] && tr '\n' '\0' <"$del.nl" >"$del"
  rm_list "$del" "$DISK_CACHE"
  row "$name" "$total" "$freed" "$n_age entries >${DISK_CACHE_AGE_D}d, $n_lru LRU over $(hsize "$DISK_CACHE_CAP_KB") cap"
}

stop_server() { # stop the bazel server of an orphaned output base
  local ob=$1 pid i
  pid=$(cat "$ob/server/server.pid.txt" 2>/dev/null) || return 0
  case "$pid" in '' | *[!0-9]*) return 0 ;; esac
  kill -0 "$pid" 2>/dev/null || return 0
  if ! ps -ww -p "$pid" -o args= 2>/dev/null | grep -qF -- "--output_base=$ob"; then
    detail "pid $pid is not this output base's server; not killed"
    return 0
  fi
  if [ "$MODE" != apply ]; then detail "would stop bazel server pid $pid"; return 0; fi
  kill "$pid" 2>/dev/null
  for i in 1 2 3 4 5 6 7 8 9 10; do kill -0 "$pid" 2>/dev/null || return 0; sleep 1; done
  kill -9 "$pid" 2>/dev/null
  sleep 1
}

t_bazel_output_bases() {
  local name=bazel-output-bases before=0 freed=0 n=0 ob ws kb
  [ -d "$BZ_ROOT" ] || { info_row "$name" - "absent"; return; }
  busy_bazel && { info_row "$name" - "skipped: busy (bazel build running)"; return; }
  for ob in "$BZ_ROOT"/*; do
    case "${ob##*/}" in install | cache) continue ;; esac
    [ -f "$ob/DO_NOT_BUILD_HERE" ] || continue
    ws=$(cat "$ob/DO_NOT_BUILD_HERE" 2>/dev/null)
    kb=$(du_kb "$ob")
    before=$((before + kb))
    if [ "$ob" = "$BZ_MAIN_OB" ] || [ "$ws" = "$MONO" ]; then
      detail "keep  $(hsize "$kb")  ${ob##*/} (main: $ws)"
    elif [ -z "$ws" ] || [ -e "$ws" ]; then
      detail "keep  $(hsize "$kb")  ${ob##*/} (workspace exists: $ws)"
    else
      detail "del   $(hsize "$kb")  ${ob##*/} (orphan: $ws gone)"
      stop_server "$ob"
      rm_tree "$ob" && { freed=$((freed + kb)); n=$((n + 1)); }
    fi
  done
  row "$name" "$before" "$freed" "$n orphaned output base(s)"
}

t_bazel_repo_cache() {
  local name=bazel-repo-cache before freed=0 n=0 e kb
  local all="$WORK/ca.all" recent="$WORK/ca.recent" cand="$WORK/ca.cand"
  [ -d "$BZ_ROOT/cache/repos" ] || { info_row "$name" - "absent"; return; }
  busy_bazel && { info_row "$name" - "skipped: busy (bazel build running)"; return; }
  before=$(du_kb "$BZ_ROOT/cache/repos")
  if [ -d "$BZ_CA" ]; then
    # entry = content_addressable/<algo>/<hash>/ ; used if its dir or any file in it is recent
    find "$BZ_CA" -mindepth 2 -maxdepth 2 -type d | sort >"$all"
    {
      find "$BZ_CA" -mindepth 2 -maxdepth 2 -type d -mtime -"${BZ_CA_AGE_D}"d
      find "$BZ_CA" -mindepth 3 -type f \( -mtime -"${BZ_CA_AGE_D}"d -o -atime -"${BZ_CA_AGE_D}"d \) |
        sed -E 's#^(.*/content_addressable/[^/]+/[^/]+)/.*#\1#'
    } | sort -u >"$recent"
    comm -23 "$all" "$recent" >"$cand"
    while IFS= read -r e; do
      kb=$(du_kb "$e")
      rm_tree "$e" && { freed=$((freed + kb)); n=$((n + 1)); }
    done <"$cand"
  fi
  detail "contents/ (extracted repos) left to Bazel's own --repo_contents_cache_gc_max_age"
  row "$name" "$before" "$freed" "$n download(s) unused >${BZ_CA_AGE_D}d"
}

gradle_keep_versions() { # versions pinned by client worktrees + versions of running daemons
  local wt
  git -C "$CLIENT" worktree list --porcelain 2>/dev/null | sed -n 's/^worktree //p' >"$WORK/wts"
  [ -s "$WORK/wts" ] || echo "$CLIENT" >"$WORK/wts"
  while IFS= read -r wt; do
    sed -nE 's#^distributionUrl=.*gradle-(.+)-(bin|all)\.zip.*#\1#p' \
      "$wt/android/gradle/wrapper/gradle-wrapper.properties" 2>/dev/null
  done <"$WORK/wts"
  ps -axww -o args= 2>/dev/null | grep -F GradleDaemon | grep -v grep |
    sed -nE -e 's#.*GradleDaemon ([0-9][^ ]*).*#\1#p' -e 's#.*/gradle-([0-9][^/]*)/lib/.*#\1#p'
}

t_gradle() {
  local name=gradle before freed=0 keep v p kb vkb logs="$WORK/gr.logs" deleted="$WORK/gr.deleted"
  [ -d "$GRADLE" ] || { info_row "$name" - "absent"; return; }
  busy_gradle && { info_row "$name" - "skipped: busy (gradle build running)"; return; }
  before=$(du_kb "$GRADLE")
  keep=" $(gradle_keep_versions | sort -u | tr '\n' ' ') "
  : >"$deleted"
  {
    find "$GRADLE/caches" "$GRADLE/daemon" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sed 's#.*/##'
    find "$GRADLE/wrapper/dists" -mindepth 1 -maxdepth 1 -type d -name 'gradle-*' 2>/dev/null |
      sed -nE 's#.*/gradle-(.+)-(bin|all)$#\1#p'
  } | grep -E '^[0-9]+(\.[0-9]+)+(-[A-Za-z0-9.-]+)?$' | sort -u >"$WORK/gr.versions"
  while IFS= read -r v; do
    set -- "$GRADLE/caches/$v" "$GRADLE/wrapper/dists/gradle-$v-bin" "$GRADLE/wrapper/dists/gradle-$v-all" "$GRADLE/daemon/$v"
    case "$keep" in *" $v "*) detail "keep  gradle $v (in use)"; continue ;; esac
    vkb=0
    for p in "$@"; do [ -e "$p" ] && newer_than "$p" -maxdepth 2 -mtime -"${GRADLE_VER_AGE_D}"d && vkb=-1; done
    [ "$vkb" = -1 ] && { detail "keep  gradle $v (used <${GRADLE_VER_AGE_D}d)"; continue; }
    for p in "$@"; do
      [ -e "$p" ] || continue
      kb=$(du_kb "$p")
      rm_tree "$p" && { vkb=$((vkb + kb)); echo "$p/" >>"$deleted"; }
    done
    freed=$((freed + vkb))
    detail "del   $(hsize "$vkb")  gradle $v (unused >${GRADLE_VER_AGE_D}d)"
  done <"$WORK/gr.versions"
  # Daemon logs > 7d, excluding ones already inside a deleted version dir.
  find "$GRADLE/daemon" -type f -name '*.log' -mtime +"${GRADLE_LOG_AGE_D}"d 2>/dev/null |
    awk -v dl="$deleted" 'BEGIN { while ((getline l < dl) > 0) d[++n] = l }
      { for (i = 1; i <= n; i++) if (index($0, d[i]) == 1) next; print }' | tr '\n' '\0' >"$logs"
  kb=$(list_kb "$logs")
  rm_list "$logs" "$GRADLE/daemon"
  freed=$((freed + kb))
  row "$name" "$before" "$freed" "$(list_n "$logs") daemon log(s) >${GRADLE_LOG_AGE_D}d; keep: $(echo $keep)"
}

t_go_build() {
  local name=go-build before list="$WORK/go.del" kb
  [ -d "$GOCACHE_DIR" ] || { info_row "$name" - "absent"; return; }
  busy_go && { info_row "$name" - "skipped: busy (go build/test running)"; return; }
  before=$(du_kb "$GOCACHE_DIR")
  # -mindepth 2: only cache entries in the xx/ subdirs, never README/trim.txt
  find "$GOCACHE_DIR" -mindepth 2 -type f -mtime +"${GOCACHE_AGE_D}"d -atime +"${GOCACHE_AGE_D}"d -print0 >"$list"
  kb=$(list_kb "$list")
  rm_list "$list" "$GOCACHE_DIR"
  row "$name" "$before" "$kb" "$(list_n "$list") file(s) unused >${GOCACHE_AGE_D}d"
}

t_go_mod() { info_row go-pkg-mod "$(hsize "$(du_kb "$GOMOD")")" "report only"; }

t_npm() {
  local name=npm before freed=0 n=0 d kb c0 c1 stamp="$STATE/npm-verify.stamp" note
  [ -d "$NPM" ] || { info_row "$name" - "absent"; return; }
  before=$(du_kb "$NPM")
  ps -axww -o args= >"$WORK/ps.args" 2>/dev/null
  if [ -d "$NPM/_npx" ]; then
    find "$NPM/_npx" -mindepth 1 -maxdepth 1 -type d -mtime +"${NPX_AGE_D}"d >"$WORK/npx.cand"
    while IFS= read -r d; do
      newer_than "$d" -maxdepth 2 -type f -atime -"${NPX_AGE_D}"d && continue # run recently
      grep -qF "$d/" "$WORK/ps.args" && continue                            # in use (e.g. MCP server)
      kb=$(du_kb "$d")
      rm_tree "$d" && { freed=$((freed + kb)); n=$((n + 1)); }
    done <"$WORK/npx.cand"
  fi
  note="$n _npx dir(s) unused >${NPX_AGE_D}d"
  if newer_than "$stamp" -mmin -"$NPM_VERIFY_EVERY_MIN"; then
    note="$note; cache verify ran <24h ago"
  elif busy_npm; then
    note="$note; cache verify skipped: busy (npm install running)"
  elif [ "$MODE" = apply ]; then
    c0=$(du_kb "$NPM/_cacache")
    if with_timeout 900 npm cache verify >/dev/null 2>&1; then touch "$stamp"; fi
    c1=$(du_kb "$NPM/_cacache")
    [ "$c0" -gt "$c1" ] && freed=$((freed + c0 - c1))
    note="$note; cache verify done"
  else
    note="$note; would run npm cache verify (GC, amount unknown)"
  fi
  row "$name" "$before" "$freed" "$note"
}

t_derived_data() {
  local name=xcode-deriveddata before freed=0 n=0 d kb
  [ -d "$DERIVED" ] || { info_row "$name" - "absent"; return; }
  busy_xcode && { info_row "$name" - "skipped: busy (xcodebuild running)"; return; }
  before=$(du_kb "$DERIVED")
  find "$DERIVED" -mindepth 1 -maxdepth 1 -type d ! -name '*.noindex' -mtime +"${DERIVED_AGE_D}"d >"$WORK/dd.cand"
  while IFS= read -r d; do
    newer_than "$d" -maxdepth 3 -mtime -"${DERIVED_AGE_D}"d && continue
    kb=$(du_kb "$d")
    detail "del   $(hsize "$kb")  ${d##*/}"
    rm_tree "$d" && { freed=$((freed + kb)); n=$((n + 1)); }
  done <"$WORK/dd.cand"
  row "$name" "$before" "$freed" "$n project(s) untouched >${DERIVED_AGE_D}d"
}

t_simulators() {
  local name=ios-simulators udids kb=0 u n
  if [ -z "$(find "$SIM_DEVICES" -mindepth 1 -maxdepth 1 -type d -print -quit 2>/dev/null)" ]; then
    info_row "$name" 0 "no simulator devices"
    return
  fi
  busy_xcode && { info_row "$name" - "skipped: busy (xcodebuild running)"; return; }
  udids=$(with_timeout 60 xcrun simctl list devices unavailable 2>/dev/null |
    grep -i 'unavailable' | grep -oE '[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}')
  n=0
  for u in $udids; do kb=$((kb + $(du_kb "$SIM_DEVICES/$u"))); n=$((n + 1)); done
  [ "$n" -gt 0 ] && [ "$MODE" = apply ] && with_timeout 300 xcrun simctl delete unavailable >/dev/null 2>&1
  row "$name" "$(du_kb "$SIM_DEVICES")" "$kb" "$n unavailable device(s)"
}

t_metro() {
  local name=metro-haste-tmp before=0 freed=0 files=0 e list="$WORK/metro.del" kb
  find "$TMPD" -mindepth 1 -maxdepth 1 \( -name 'metro-*' -o -name 'haste-map-*' \) >"$WORK/metro.entries" 2>/dev/null
  [ -s "$WORK/metro.entries" ] || { info_row "$name" 0 "none in \$TMPDIR"; return; }
  while IFS= read -r e; do
    before=$((before + $(du_kb "$e")))
    find "$e" -type f -mtime +"${METRO_AGE_D}"d -atime +"${METRO_AGE_D}"d -print0 >"$list"
    kb=$(list_kb "$list")
    files=$((files + $(list_n "$list")))
    rm_list "$list" "$TMPD" && freed=$((freed + kb))
    [ "$MODE" = apply ] && [ -d "$e" ] && find "$e" -mindepth 1 -type d -empty -delete 2>/dev/null
  done <"$WORK/metro.entries"
  row "$name" "$before" "$freed" "$files file(s) >${METRO_AGE_D}d"
}

t_wt_trash() {
  local name=worktrunk-trash before=0 freed=0 n=0 repo t e kb
  for repo in "$MONO" "$CLIENT"; do
    t="$repo/.git/wt/trash"
    [ -d "$t" ] || continue
    before=$((before + $(du_kb "$t")))
    find "$t" -mindepth 1 -maxdepth 1 -mmin +"$TRASH_AGE_MIN" >"$WORK/trash.cand"
    while IFS= read -r e; do
      kb=$(du_kb "$e")
      detail "del   $(hsize "$kb")  ${repo##*/}: ${e##*/}"
      rm_tree "$e" && { freed=$((freed + kb)); n=$((n + 1)); }
    done <"$WORK/trash.cand"
  done
  row "$name" "$before" "$freed" "$n entr(ies) >24h"
}

t_android_worktrees() {
  local name=android-wt-builds before=0 freed=0 n=0 main wt sub d kb
  [ -d "$CLIENT/.git" ] || { info_row "$name" - "client repo absent"; return; }
  busy_gradle && { info_row "$name" - "skipped: busy (gradle build running)"; return; }
  main=$(cd "$CLIENT" && pwd -P)
  git -C "$CLIENT" worktree list --porcelain 2>/dev/null | sed -n 's/^worktree //p' >"$WORK/wts"
  while IFS= read -r wt; do
    [ -d "$wt" ] || continue
    [ "$(cd "$wt" && pwd -P)" = "$main" ] && continue
    case "$wt" in "$HOME/.claude" | "$HOME/.claude/"*) continue ;; esac
    for sub in android/app/build android/app/.cxx; do
      d="$wt/$sub"
      [ -d "$d" ] || continue
      kb=$(du_kb "$d")
      before=$((before + kb))
      if newer_than "$d" -mtime -"${WT_BUILD_AGE_D}"d; then
        detail "keep  $(hsize "$kb")  $d (touched <${WT_BUILD_AGE_D}d)"
        continue
      fi
      detail "del   $(hsize "$kb")  $d"
      ALLOWED_EXACT+=("$d")
      rm_tree "$d" && { freed=$((freed + kb)); n=$((n + 1)); }
    done
  done <"$WORK/wts"
  row "$name" "$before" "$freed" "$n build dir(s) in non-main worktrees"
}

report_extras() { # dry-run only: things we never delete but the user should see
  local kb e
  kb=$(du_kb "$CLIENT/android/app/build" "$CLIENT/android/app/.cxx")
  info_row client-main-android "$(hsize "$kb")" "NOT touched; run \`cd $CLIENT/android && ./gradlew clean\` to reclaim"
  echo
  echo "Other ~/Library/Caches (top 10, report only):"
  for e in "$HOME/Library/Caches"/*; do
    case "${e##*/}" in bazel | go-build) continue ;; esac
    [ -d "$e" ] && printf '%s\t%s\n' "$(du_kb "$e")" "$e"
  done | sort -rn | head -10 | while IFS="$(printf '\t')" read -r kb e; do
    printf '  %7s  ~%s\n' "$(hsize "$kb")" "${e#"$HOME"}"
  done
}

# ---------------------------------------------------------------- main
echo "== cache-cleanup $MODE $(date '+%F %T') =="
t_bazel_disk_cache
t_bazel_output_bases
t_bazel_repo_cache
t_gradle
t_go_build
t_go_mod
t_npm
t_derived_data
t_simulators
t_metro
t_wt_trash
t_android_worktrees
[ "$MODE" = dry-run ] && report_extras
if [ "$MODE" = apply ]; then verb=freed; else verb="would free"; fi
echo "total: $verb $(hsize "$TOTAL_FREED") in $(($(date +%s) - START))s"
