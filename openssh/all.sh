#!/bin/sh -u
#
# We do not use -e: if building fails, we continue but grab what we got so far

# Ah sod it, declare for this wrapper that must be invoked in correct dir
. ./Version.sh

[ $# -eq 0 ] && set arch bento-centos7 bento-debian9.1 bento-fedora26 bento-freebsd11 jessie netbsd7 stretch trusty xenial


progname="$(basename -s .sh "$0")"
warn() { printf >&2 "%s: %s\n" "$progname" "$*"; }
die() { warn "$@"; exit 1; }
run() {
  printf "+ %s\n" "$*"
  [ ".${NOTREALLY:-}" != "." ] && return 0
  "$@"
}

readonly log_dir="./logs/SNAP-${SNAPDATE:?}"
[ -d logs ] || die "missing logs parent dir, are you in the right place?"
[ -d "$log_dir" ] || mkdir -v "$log_dir"

for machine
do
  if [ -f "${log_dir}/${machine}.txt" ]; then
    if [ ".${PT_REDO:-}" != "." ]; then
      mv -v "${log_dir}/${machine}.txt" "${log_dir}/${machine}.old"
    else
      warn "skipping without \$PT_REDO because already done: $machine"
      continue
    fi
  fi
  run ./buildtest-openssh up $machine
  run ./grab-report $machine
  run ./buildtest-openssh suspend $machine
done

cd ../stub
run vagrant status
