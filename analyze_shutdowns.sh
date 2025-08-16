#!/bin/zsh

# --- Config ---
MATCH_WINDOW_SEC=1800   # widen to 1800 if you like

# --- Collect shutdown/reboot entries from `last` (latest first) ---
entries=()
# Only lines that start with reboot|shutdown (avoid "root ... - shutdown" noise)
while IFS= read -r line; do
  entries+=("$line")
done < <(last | grep -E '^(reboot|shutdown)')

types=()
times=()
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

# --- Parse entries and detect year rollover ---
for line in "${entries[@]}"; do
  type=$(echo "$line" | awk '{print $1}')

  # Find the "Mon DD HH:MM" triplet anywhere in the line
  raw_ts=$(echo "$line" | awk '
    { for (i=1; i<=NF-2; i++)
        if ($i ~ /^[A-Z][a-z]{2}$/ && $(i+1) ~ /^[0-9]{1,2}$/ && $(i+2) ~ /^[0-9]{2}:[0-9]{2}$/)
          { print $i, $(i+1), $(i+2); break } }')

  [[ -z "$raw_ts" ]] && continue

  month=$(echo "$raw_ts" | awk '{print $1}')
  month_num=$(month_to_num "$month")

  # Year rollover: months increase when scanning reverse-chronologically
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

# --- Fetch and parse software update history ---
# Skip header/separator lines cleanly
update_lines=("${(@f)$(softwareupdate --history | awk 'NR>1 && $0 !~ /^-+/{print}')}")

update_epochs=()
update_names=()

for line in "${update_lines[@]}"; do
  # Columns typically: NAME  VERSION  DATETIME
  # Use multiple spaces as field separators
  name=$(echo "$line" | awk -F'  +' '{print $1}')
  version=$(echo "$line" | awk -F'  +' '{print $2}')
  col3=$(echo "$line" | awk -F'  +' '{print $3}')

  # Normalize: remove commas in the datetime field
  col3_nocomma=${col3//,/}

  # Try to parse full datetime from column 3
  update_epoch=$(date -j -f "%m/%d/%Y %H:%M:%S" "$col3_nocomma" "+%s" 2>/dev/null)

  # Fallback in case some systems still split date/time into col3/col4
  if [[ -z "$update_epoch" ]]; then
    date_str=$(echo "$line" | awk -F'  +' '{print $3}' | sed 's/,//g')
    time_str=$(echo "$line" | awk -F'  +' '{print $4}')
    if [[ -n "$date_str" && -n "$time_str" ]]; then
      dt="$date_str $time_str"
      update_epoch=$(date -j -f "%m/%d/%Y %H:%M:%S" "$dt" "+%s" 2>/dev/null)
    fi
  fi

  [[ -z "$update_epoch" ]] && continue

  # Build label (avoid duplicating version if it's in the name)
  if [[ "$name" == *"$version" ]]; then
    update_label="$name"
  else
    update_label="$name $version"
  fi

  update_names+=("$update_label")
  update_epochs+=("$update_epoch")
done

echo "=== Reboot Event Timeline ==="

# zsh arrays are 1-based — loop accordingly
for (( i=1; i<=${#types[@]}; i++ )); do
  if [[ "${types[$i]}" == "reboot" ]]; then
    label=""
    [[ "${types[$((i+1))]:-}" == "shutdown" ]] && label="[intentional]"

    # Compute uptime until the next reboot entry
    uptime=""
    for (( j=i+1; j<=${#types[@]}; j++ )); do
      if [[ "${types[$j]}" == "reboot" ]]; then
        curr_epoch=${epochs[$i]}
        next_epoch=${epochs[$j]}
        if [[ -n "$curr_epoch" && -n "$next_epoch" && "$curr_epoch" -gt "$next_epoch" ]]; then
          diff=$((curr_epoch - next_epoch))
          days=$((diff / 86400))
          hours=$(( (diff % 86400) / 3600 ))
          mins=$(( (diff % 3600) / 60 ))
          uptime=$(printf "(%2dd %2dh %2dm uptime)" $days $hours $mins)
        fi
        break
      fi
    done

    # Match software updates completed within MATCH_WINDOW_SEC before this reboot
    swu_updates=()
    curr_epoch=${epochs[$i]}
    if [[ -n "$curr_epoch" ]]; then
      for (( k=1; k<=${#update_epochs[@]}; k++ )); do
        delta=$(( curr_epoch - update_epochs[$k] ))
        if (( delta >= 0 && delta <= MATCH_WINDOW_SEC )); then
          swu_updates+=("${update_names[$k]}")
        fi
      done
    fi

    # Pretty-print any matched updates
    swu_label=""
    if (( ${#swu_updates[@]} > 0 )); then
      swu_label="[$(printf "%s" "${swu_updates[1]}")"
      for (( s=2; s<=${#swu_updates[@]}; s++ )); do
        swu_label+=", ${swu_updates[$s]}"
      done
      swu_label+="]"
    fi

    printf "%-13s %-13s %-21s %s\n" "${times[$i]}" "$label" "$uptime" "$swu_label"
  fi
done
