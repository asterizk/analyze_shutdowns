#!/bin/zsh

# Collect shutdown/reboot entries
entries=()
while IFS= read -r line; do
  entries+=("$line")
done < <(last | grep -E 'shutdown|reboot')

# Parse event types and timestamps
types=()
times=()
epochs=()

for line in "${entries[@]}"; do
  type=$(echo "$line" | awk '{print $1}')
  timestamp=$(echo "$line" | awk '{for(i=0;i<NF;i++) if($i ~ /^[A-Z][a-z]{2}$/ && $(i+1) ~ /^[0-9]{1,2}$/ && $(i+2) ~ /^[0-9]{2}:[0-9]{2}$/) print $i, $(i+1), $(i+2)}')
  epoch=$(date -j -f "%b %d %H:%M" "$timestamp" "+%s" 2>/dev/null)

  types+=("$type")
  times+=("$timestamp")
  epochs+=("$epoch")
done

echo "=== Reboot Event Timeline ==="

for ((i=0; i<${#types[@]}; i++)); do
  if [[ "${types[$i]}" == "reboot" ]]; then
    label=""
    # Look one entry down for a shutdown
    if [[ "${types[$((i+1))]:-}" == "shutdown" ]]; then
      label="[intentional]"
    fi

    # Find next *reboot* (not just next line)
    uptime=""
    for ((j=i+1; j<${#types[@]}; j++)); do
      if [[ "${types[$j]}" == "reboot" ]]; then
        curr_epoch=${epochs[$i]}
        next_epoch=${epochs[$j]}
        if [[ "$curr_epoch" -gt "$next_epoch" ]]; then
          diff=$((curr_epoch - next_epoch))
          days=$((diff / 86400))
          hours=$(( (diff % 86400) / 3600 ))
          mins=$(( (diff % 3600) / 60 ))
          uptime="(${days}d ${hours}h ${mins}m uptime)"
        fi
        break
      fi
    done

    printf "%-15s  %-13s %s\n" "${times[$i]}" "$label" "$uptime"
  fi
done

