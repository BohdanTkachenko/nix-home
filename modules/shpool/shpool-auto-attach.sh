# Prefix for auto-managed sessions
PREFIX="s"

# Get current sessions, checking for errors first.
if ! SHPOOL_OUTPUT=$(shpool list 2>/dev/null); then
  echo "Error: Could not contact shpool daemon." >&2
  exit 1
fi
# Strip header if output exists
CLEAN_OUTPUT=$(echo "$SHPOOL_OUTPUT" | tail -n +2)

detached_sessions=()
all_auto_indices=()
while IFS=$'\t' read -r name _ status; do
  [ -z "$name" ] && continue

  if [[ "$name" == "$PREFIX"* ]]; then
    index=${name#"$PREFIX"}
    if [[ "$index" =~ ^[0-9]+$ ]]; then
      all_auto_indices+=("$index")
    fi
  fi
done <<<"$CLEAN_OUTPUT"

if [ ${#detached_sessions[@]} -gt 0 ]; then
  mapfile -t sorted_detached < <(printf "%s\n" "${detached_sessions[@]}" | sort -n)

  target_index=${sorted_detached[0]}
  target_session="${PREFIX}${target_index}"
  echo "Found available session. Attaching to $target_session..."

  export TERM=xterm-256color
  exec shpool attach "$target_session"
fi

K=0
if [ ${#all_auto_indices[@]} -gt 0 ]; then
  mapfile -t sorted_indices < <(printf "%s
" "${all_auto_indices[@]}" | sort -n)

  for i in "${sorted_indices[@]}"; do
    index=$((10#$i))
    if [ "$index" -eq "$K" ]; then
      K=$((K + 1))
    elif [ "$index" -gt "$K" ]; then
      break
    fi
  done
fi

new_session="${PREFIX}${K}"
echo "No available sessions. Creating and attaching to new session $new_session..."

export TERM=xterm-256color
exec shpool attach "$new_session"
