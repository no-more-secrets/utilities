#!/bin/bash
[[ "$(uname)" == Darwin ]] && osx=1 || osx=0

(( osx )) && lld_default= || lld_default='--lld'

[[ "$1" == '--print-only' ]] && print_only=1

c_norm="\033[00m"
c_green="\033[32m"
c_red="\033[31m"

log() {
    echo -e "[$(date)] ${c_green}INFO${c_norm} $*"
}

error() {
    echo -e "[$(date)] ${c_red}ERROR${c_norm} $*" >&2
}

die() {
  error "$*"
  exit 1
}

configure_cached() {
  flags="$@"
  cmc c $flags --cached >/dev/null
}

configure() {
  flags="$@"
  cmd="cmc c $flags --no-symlink"
  # echo "cmd: $cmd"
  if (( print_only )); then
    echo "$cmd"
    return
  fi
  # log "configuration: $flags"
  if ! $cmd; then
    error "configure failed for flags: $flags"
    return 1
  fi
  return 0
}

build_and_test() {
  flags="$@"
  configure_cached "$flags"
  if ! make all; then
    error "build failed for flags: $flags"
    return 2
  fi
  if ! make test; then
    error "tests failed for flags: $flags"
    return 3
  fi
  return 0
}

# If a given configuration fails the configure stage then this
# will be called to print an error message.
print_failed_configuration() {
  flags="$@"
  # Configure failed.
  status="${c_red}FAILURE:configuration${c_norm}"
  # We need to craft our own platform string because
  # `cmc` has presumably not done so for us since it
  # failed.
  platform="$(echo "$flags" \
    | sed -r 's/,+/,/g; s/(.*),$/\1/; s/--//g')"
  return 1
}

[[ -z "$COLUMNS" ]] && COLUMNS=65

print_bar() {
  n=$1
  for (( i=0; i < $n; i++ )); do
    echo -n '-'
  done
}

print_title_bar() {
  title="$1"
  len_title="${#title}"
  half="$(( ( COLUMNS - len_title - 2 )/2 ))"
  print_bar $half
  echo -en " ${c_green}${s_bold}$title$c_norm "
  print_bar $half
  echo
}

logfile="/tmp/build-all.log"

rm -f $logfile
echo -n >$logfile

# This function expects a bunch of variables to be set.
run_for_args() {
  flags="$@"
  build_and_test "$flags"
  code=$?
  if (( code == 0 )); then
    # Success.
    status="${c_green}SUCCESS${c_norm}"
    platform="$(cmc st | awk '{print $2}')"
  elif (( code == 2 )); then
    # Build failed.
    status="${c_red}FAILURE:build${c_norm}"
    platform="$(cmc st | awk '{print $2}')"
  elif (( code == 3 )); then
    # Testing failed.
    status="${c_red}FAILURE:test${c_norm}"
    platform="$(cmc st | awk '{print $2}')"
  else
    status="${c_red}FAILURE:unknown${c_norm}"
    platform="$(echo "$flags" \
      | sed -r 's/,+/,/g; s/(.*),$/\1/; s/--//g')"
  fi
  echo -e "$platform $status" >> $logfile
}

platforms=( )

# for cc in --clang '' --gcc=current; do
for cc in --gcc=current --clang; do
  # for lib in '' --libcxx --libstdcxx; do
  for lib in --libstdcxx --libcxx; do
    for opt in '' --release; do
      for asan in --asan ''; do
        [[ "$cc" =~ gcc && "$lib" =~ libcxx ]] && continue
        [[ "$cc" == ""  && "$lib" =~ libcxx ]] && continue
        flags="$cc $lib $opt $asan"
        [[ "$cc" =~ --clang ]] && flags="$flags $lld_default"
        platforms=( "${platforms[@]}" "$flags" )
      done
    done
  done
done

pids=
for flags in "${platforms[@]}"; do
  # echo "platform: $flags"
  { configure "$flags" || print_failed_configuration "$flags"; } &
  pids="$pids $!"
done

# Wait for the above to print all of their "configuring..." mes-
# sages, then print ours over top of it (and clear to end of
# line).
sleep 0.1
echo -en "\rconfiguring ${#platforms[@]} platforms...\033[K"

wait $pids || {
  echo
  echo
  echo -e "${c_red}Some configurations failed${c_norm}!"
  exit 1
}

clear

for flags in "${platforms[@]}"; do
  clear
  configure_cached "$flags"
  # Don't use `cmc st` here since it outputs color.
  platform="$(basename $(readlink -f .builds/current))"
  print_title_bar "$platform"
  run_for_args "$flags"
done

# Do --lto just once since it can take a really long time.
# cc=--clang; lib=; opt=--release; asan=; lto=--lto;
# run_for_args

# Restore to default devel flags.
(( print_only )) || cmc --cached --clang --lld --asan

print_table() {
  {
    echo "Configuration Result"
    cat $logfile
  } | column -t
}

clear
echo -e "$(print_table)"
