# Completion cache: retyping or backspacing to a line already answered in
# this directory shows its ghost text at once, without a request.
#
# Keyed by directory + line, since the context (files, git) depends on the
# directory. Holds at most 200 entries; the oldest go first.

typeset -gA _ZGA_CACHE
typeset -ga _ZGA_CACHE_ORDER
typeset -gi _ZGA_CACHE_MAX=200

_zga_cache_get() {
  local key="$PWD"$'\x1f'"$1"
  (( ${+_ZGA_CACHE[$key]} )) || return 1
  REPLY=${_ZGA_CACHE[$key]}
}

_zga_cache_put() {
  local key="$PWD"$'\x1f'"$1"
  if (( ! ${+_ZGA_CACHE[$key]} )); then
    _ZGA_CACHE_ORDER+=("$key")
    while (( $#_ZGA_CACHE_ORDER > _ZGA_CACHE_MAX )); do
      unset "_ZGA_CACHE[${_ZGA_CACHE_ORDER[1]}]"
      shift _ZGA_CACHE_ORDER
    done
  fi
  _ZGA_CACHE[$key]=$2
}

_zga_cache_clear() {
  _ZGA_CACHE=()
  _ZGA_CACHE_ORDER=()
}
