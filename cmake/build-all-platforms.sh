#!/bin/bash
[[ "$(uname)" == Darwin ]] && osx=1 || osx=0

(( osx )) && lld_default= || lld_default='--lld'
(( osx )) && mold_default= || mold_default='--mold'

c_norm="\033[00m"
c_green="\033[32m"
c_red="\033[31m"
c_blue="\033[34m"

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

now_secs() {
  date +%s
}

# This function expects a bunch of variables to be set.
run_for_args() {
  flags="$@"
  local start_time="$(now_secs)"
  build_and_test "$flags"
  code=$?
  local end_time="$(now_secs)"
  local delta_time="$(( end_time-start_time ))s"
  # This is to right justify the time.
  # delta_time="       $delta_time"
  # [[ "$delta_time" =~ .*(....)$ ]]
  # delta_time="${BASH_REMATCH[1]}"
  delta_time="${c_blue}$delta_time${c_norm}"
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
  echo -e "$platform $status $delta_time" >> $logfile
}

platforms=( )

# for cc in --clang '' --gcc=current; do
for cc in --gcc=current --clang; do
  # for lib in '' --libcxx --libstdcxx; do
  for lib in --libstdcxx --libcxx; do
    for opt in '' --relwdeb; do
      for asan in --asan ''; do
        [[ "$cc" =~ gcc && "$lib" =~ libcxx ]] && continue
        [[ "$cc" == ""  && "$lib" =~ libcxx ]] && continue
        flags="$cc $lib $opt $asan"
        [[ "$cc" =~ --clang ]] && flags="$flags $lld_default"
        [[ "$cc" =~ gcc ]]     && flags="$flags $mold_default"
        platforms=( "${platforms[@]}" "$flags" )
      done
    done
  done
done

# Do --lto just once since it can take a really long time.
# cc=--clang; lib=; opt=--relwdeb; asan=; lto=--lto;
# run_for_args

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

native_gcc_version() {
  gcc --version | head -n1 | fmt --width=0 | tail -n1 | tr '.' ' '
}

native_gcc_major_version="$(native_gcc_version | awk '{ print $1 }')"
native_gcc_minor_version="$(native_gcc_version | awk '{ print $2 }')"
native_gcc_patch_version="$(native_gcc_version | awk '{ print $3 }')"

# Restore to default devel flags.
(( native_gcc_major_version >= 14 )) && cmc --cached --clang --lld --asan \
                                     || cmc --cached --clang --lld --asan --libstdcxx

print_table() {
  {
    echo "Configuration Result Time"
    cat $logfile
  } | column -t
}

clear
echo -e "$(print_table)"
