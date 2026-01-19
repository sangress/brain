# Load brain (AI command helper)
brain() {
  local prompt="${*:-${READLINE_LINE:-}}"
  local cmd

  if [[ -z "${prompt// }" ]]; then
    echo 'Usage: brain "..." (or type text and press hotkey)' >&2
    return 1
  fi

  cmd="$(~/dev/scripts/brain.sh "$prompt")" || return $?

  # paste into current command line (no execute)
  if [[ -n "${READLINE_LINE+x}" ]]; then
    READLINE_LINE="$cmd"
    READLINE_POINT=${#READLINE_LINE}
  else
    echo "$cmd"
  fi
}
