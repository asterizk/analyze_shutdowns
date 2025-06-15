#!/bin/zsh

# Collect shutdown/reboot events from `last`
entries=()
while IFS= read -r line; do
  entries+=("$line")
done < <(last | grep -E 'shutdown|reboot')

types=()
times=()
datetimes=()

# Parse type and full timestamp
for line in "${entries[@]}"; do
  type=$(echo "$line" | awk '{print $1}')
  timestamp=$(echo "$line" | awk '{for(i=0;i<NF;i++) if($i ~ /^[A-Z][a-z]{2}$/ && $(i+1) ~ /^[0-9]{1,2}$/ && $(i+2) ~ /^[0-9]{2}:[0-9]{2}$/) print $i, $(i+1), $(i+2)}')
  types+=("$type")
  times+=("$timestamp")

  # Convert to epoch using assumed current year
  epoch=$(date -j -f "%b %d %H:%M" "$timestamp" "+%s" 2>/dev/null)
  datetimes+=("$epoch")
done

echo "=== Reboot Event Timeline ==="
for ((i=0; i<${#types[@]}; i++)); do
  if [[ "${types[$i]}" == "reboot" ]]; then
    prev="${types[$((i+1))]:-}"
    label=""
    [[ "$prev" == "shutdown" ]] && label="[intentional]"

    # Compute uptime between this and next reboot
    uptime=""
    if (( i+1 < ${#datetimes[@]} )); then
      current_epoch=${datetimes[$i]}
      next_epoch=${datetimes[$((i+1))]}
      if [[ "$next_epoch" =~ ^[0-9]+$ ]] && [[ "$current_epoch" -gt "$next_epoch" ]]; then
        diff_sec=$((current_epoch - next_epoch))
        days=$((diff_sec / 86400))
        hours=$(( (diff_sec % 86400) / 3600 ))
        mins=$(( (diff_sec % 3600) / 60 ))
        uptime="(${days}d ${hours}h ${mins}m uptime)"
      fi
    fi

    printf "%-15s  %-13s %s\n" "${times[$i]}" "$label" "$uptime"
  fi
done

