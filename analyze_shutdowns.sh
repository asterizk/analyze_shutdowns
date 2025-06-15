#!/bin/zsh

# Collect shutdown/reboot entries from `last`
entries=()
while IFS= read -r line; do
  entries+=("$line")
done < <(last | grep -E 'shutdown|reboot')

types=()
times=()
months=()
epochs=()

current_year=$(date +%Y)
year=$current_year
last_month_num=13  # invalid to trigger first transition

# Month → number
month_to_num() {
  case "$1" in
    Jan) echo 1 ;; Feb) echo 2 ;; Mar) echo 3 ;; Apr) echo 4 ;;
    May) echo 5 ;; Jun) echo 6 ;; Jul) echo 7 ;; Aug) echo 8 ;;
    Sep) echo 9 ;; Oct) echo 10 ;; Nov) echo 11 ;; Dec) echo 12 ;;
    *) echo 0 ;;
  esac
}

# Format timestamp with zero-padded day
normalize_date() {
  local ts="$1"
  local month=$(echo "$ts" | awk '{print $1}')
  local day=$(echo "$ts" | awk '{print $2}')
  local time=$(echo "$ts" | awk '{print $3}')
  printf "%s %02d %s" "$month" "$day" "$time"
}

# Parse entries and detect year rollover
for line in "${entries[@]}"; do
  type=$(echo "$line" | awk '{print $1}')
  raw_ts=$(echo "$line" | awk '{for(i=0;i<NF;i++) if($i ~ /^[A-Z][a-z]{2}$/ && $(i+1) ~ /^[0-9]{1,2}$/ && $(i+2) ~ /^[0-9]{2}:[0-9]{2}$/) print $i, $(i+1), $(i+2)}')
  month=$(echo "$raw_ts" | awk '{print $1}')
  month_num=$(month_to_num "$month")

  if (( month_num > last_month_num )); then
    year=$((year - 1))
  fi
  last_month_num=$month_num

  types+=("$type")
  ts_formatted=$(normalize_date "$raw_ts")
  times+=("$ts_formatted")
  epoch=$(date -j -f "%b %d %H:%M %Y" "$ts_formatted $year" "+%s" 2>/dev/null)
  epochs+=("$epoch")
done

echo "=== Reboot Event Timeline ==="

for ((i=0; i<${#types[@]}; i++)); do
  if [[ "${types[$i]}" == "reboot" ]]; then
    label=""
    [[ "${types[$((i+1))]:-}" == "shutdown" ]] && label="[intentional]"

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

    printf "%-10s %-13s %s\n" "${times[$i]}" "$label" "$uptime"

  fi
done

