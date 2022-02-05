#!/bin/bash

source ./config.conf

# https://github.com/systemd/systemd/blob/be1eae4fad5562da5cb784c121981206d1b77254/src/basic/unit-def.c#L87
convert_load() {
  local load="$1"
  if [[ "$load" == "stub" ]]; then
    echo 0
  elif [[ "$load" == "loaded" ]]; then
    echo 1
  elif [[ "$load" == "not-found" ]]; then
    echo 2
  elif [[ "$load" == "bad-setting" ]]; then
    echo 3
  elif [[ "$load" == "error" ]]; then
    echo 4
  elif [[ "$load" == "merged" ]]; then
    echo 5
  elif [[ "$load" == "masked" ]]; then
    echo 6
  else
    echo 99
  fi
}

# https://github.com/systemd/systemd/blob/be1eae4fad5562da5cb784c121981206d1b77254/src/basic/unit-def.c#L99
convert_active() {
  local active="$1"
  if [[ "$active" == "active" ]]; then
    echo 0
  elif [[ "$active" == "reloading" ]]; then
    echo 1
  elif [[ "$active" == "inactive" ]]; then
    echo 2
  elif [[ "$active" == "failed" ]]; then
    echo 3
  elif [[ "$active" == "activating" ]]; then
    echo 4
  elif [[ "$active" == "deactivating" ]]; then
    echo 5
  elif [[ "$active" == "maintenance" ]]; then
    echo 6
  else
    echo 99
  fi
}

# Service: https://github.com/systemd/systemd/blob/be1eae4fad5562da5cb784c121981206d1b77254/src/basic/unit-def.c#L181
# Timer: https://github.com/systemd/systemd/blob/be1eae4fad5562da5cb784c121981206d1b77254/src/basic/unit-def.c#L252
# Duplicate values are listed only once
convert_sub() {
  local sub="$1"
  # Service table
  if [[ "$sub" == "dead" ]]; then
    echo 0
  elif [[ "$sub" == "condition" ]]; then
    echo 1
  elif [[ "$sub" == "start-pre" ]]; then
    echo 2
  elif [[ "$sub" == "start" ]]; then
    echo 3
  elif [[ "$sub" == "start-post" ]]; then
    echo 4
  elif [[ "$sub" == "running" ]]; then
    echo 5
  elif [[ "$sub" == "exited" ]]; then
    echo 6
  elif [[ "$sub" == "reload" ]]; then
    echo 7
  elif [[ "$sub" == "stop" ]]; then
    echo 8
  elif [[ "$sub" == "stop-watchdog" ]]; then
    echo 9
  elif [[ "$sub" == "stop-sigterm" ]]; then
    echo 10
  elif [[ "$sub" == "stop-sigkill" ]]; then
    echo 11
  elif [[ "$sub" == "stop-post" ]]; then
    echo 12
  elif [[ "$sub" == "final-watchdog" ]]; then
    echo 13
  elif [[ "$sub" == "final-sigterm" ]]; then
    echo 14
  elif [[ "$sub" == "final-sigkill" ]]; then
    echo 15
  elif [[ "$sub" == "failed" ]]; then
    echo 16
  elif [[ "$sub" == "auto-restart" ]]; then
    echo 17
  elif [[ "$sub" == "cleaning" ]]; then
    echo 18
  # Timer table:
  elif [[ "$sub" == "elapsed" ]]; then
    echo 19
  else
    echo 99
  fi
}

confirm_type() {
  for t in "${SERVICE_TYPES[@]}"
  do
    if [[ "$1" == "$t" ]]; then
      return 0
    fi
  done
  return 1
}

get_raw_data() {
  if confirm_type $1; then
    if [[ "${#SERVICE_PATTERNS[@]}" -eq 0 ]]; then
      echo "$(systemctl list-units "*" --all --plain --type="$1" --no-legend)"
    else
      for p in "${SERVICE_PATTERNS[@]}"
      do
        echo "$(systemctl list-units "$p" --all --plain --type="$1" --no-legend)"
      done
    fi
  else
    echo "The provided unit type is not supported. Supported SERVICE_TYPES: ${SERVICE_TYPES[@]}"
    exit 1
  fi
}

parse_raw_data() {
  while read -ra line
  do
    local name="${line[0]}"
    local load="${line[1]}"
    local active="${line[2]}"
    local sub="${line[3]}"
    local load_code=$(convert_load $load)
    local active_code=$(convert_active $active)
    local sub_code=$(convert_sub $sub)
    echo "systemd_units,host=$(hostname),name=$name,load=$load,active=$active,sub=$sub load_code=$load_code,active_code=$active_code,sub_code=$sub_code" >> "$METRIC_OUTPUT_FILE".tmp
  done < <(get_raw_data $1 | awk '{print $1, $2, $3, $4}')
}

parse_raw_data $1
mv -f "$METRIC_OUTPUT_FILE".tmp "$METRIC_OUTPUT_FILE"

