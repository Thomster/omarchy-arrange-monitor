#!/bin/bash

# Arranges the internal + external display pair for the "My Display" panel's
# ARRANGEMENT section. The internal display is anchored at 0x0; the external
# display is placed left/top/right of it, aligned on the shared midpoint:
#   left/right -> vertical midpoints of both screens line up
#   top        -> horizontal midpoints of both screens line up
# Positions are computed in logical (post-scale) space, since that's the
# space Hyprland arranges monitors in.
#
# Only positions change: both displays keep their current mode, scale and
# color-management preset (e.g. "dp3" on a Display P3 panel). A resolution
# picked in the DISPLAY RESOLUTION section is runtime only, so for the
# internal display the persisted rule uses the mode resolution.sh recorded
# before that switch, not the temporary one.

set -euo pipefail

direction="${1:-}"
dry_run=0
[[ ${2:-} == "--dry-run" ]] && dry_run=1
case "$direction" in
  left | top | right) ;;
  *)
    echo "Usage: arrange.sh left|top|right [--dry-run]" >&2
    exit 1
    ;;
esac

monitors_json=$(hyprctl monitors -j)

internal=$(jq -r '
  [.[] | select(.disabled != true) | select(.name | test("^(eDP|LVDS|DSI)-"))][0].name // ""
' <<<"$monitors_json")

external=$(jq -r --arg internal "$internal" '
  [.[] | select(.disabled != true) | select(.name != $internal)][0].name // ""
' <<<"$monitors_json")

if [[ -z $internal || -z $external ]]; then
  echo "Need one enabled internal display and one enabled external display" >&2
  exit 1
fi

# Names end up inside Lua strings passed to `hyprctl eval`.
for name in "$internal" "$external"; do
  if [[ ! $name =~ ^[A-Za-z0-9._-]+$ ]]; then
    echo "Refusing unsafe monitor name" >&2
    exit 1
  fi
done

# "WIDTHxHEIGHT@RATE" of a display's current mode.
current_mode() {
  jq -r --arg n "$1" '.[] | select(.name == $n) | "\(.width)x\(.height)@\(.refreshRate)"' <<<"$monitors_json" |
    awk -F@ '{ printf "%s@%.3f", $1, $2 }'
}

# `, cm = "..."` for a display with a non-default color-management preset.
cm_arg() {
  local cm
  cm=$(jq -r --arg n "$1" '.[] | select(.name == $n) | .colorManagementPreset // ""' <<<"$monitors_json")
  [[ $cm =~ ^[A-Za-z0-9_-]+$ && $cm != "srgb" ]] && printf ', cm = "%s"' "$cm"
  return 0
}

# hl.monitor rule: name mode position scale cm_arg
monitor_rule() {
  printf 'hl.monitor({ output = "%s", mode = "%s", position = "%s", scale = %s%s })' "$1" "$2" "$3" "$4" "$5"
}

apply_rule() {
  if (( dry_run )); then
    echo "hyprctl eval '$1'"
  else
    hyprctl eval "$1" >/dev/null
  fi
}

read -r int_w int_h int_scale <<<"$(jq -r --arg n "$internal" '
  .[] | select(.name == $n) | "\(.width) \(.height) \(.scale)"
' <<<"$monitors_json")"

read -r ext_w ext_h ext_scale <<<"$(jq -r --arg n "$external" '
  .[] | select(.name == $n) | "\(.width) \(.height) \(.scale)"
' <<<"$monitors_json")"

# Logical (post-scale) sizes, rounded to the nearest pixel.
read -r int_lw int_lh ext_lw ext_lh <<<"$(awk \
  -v iw="$int_w" -v ih="$int_h" -v is="$int_scale" \
  -v ew="$ext_w" -v eh="$ext_h" -v es="$ext_scale" \
  'BEGIN { printf "%d %d %d %d", iw/is+0.5, ih/is+0.5, ew/es+0.5, eh/es+0.5 }')"

round_half() { awk -v v="$1" 'BEGIN { printf "%d", (v >= 0 ? v + 0.5 : v - 0.5) }'; }

case "$direction" in
  left)
    ext_x=$(( -ext_lw ))
    ext_y=$(round_half "$(awk -v ih="$int_lh" -v eh="$ext_lh" 'BEGIN { print (ih - eh) / 2 }')")
    ;;
  right)
    ext_x=$int_lw
    ext_y=$(round_half "$(awk -v ih="$int_lh" -v eh="$ext_lh" 'BEGIN { print (ih - eh) / 2 }')")
    ;;
  top)
    ext_y=$(( -ext_lh ))
    ext_x=$(round_half "$(awk -v iw="$int_lw" -v ew="$ext_lw" 'BEGIN { print (iw - ew) / 2 }')")
    ;;
esac

int_mode=$(current_mode "$internal")
ext_mode=$(current_mode "$external")
int_cm=$(cm_arg "$internal")
ext_cm=$(cm_arg "$external")

apply_rule "$(monitor_rule "$internal" "$int_mode" "0x0" "$int_scale" "$int_cm")"
apply_rule "$(monitor_rule "$external" "$ext_mode" "${ext_x}x${ext_y}" "$ext_scale" "$ext_cm")"

# Persisted internal rule: the mode/scale from before a runtime-only
# resolution switch, if one is active (recorded by resolution.sh).
persist_int_mode=$int_mode
persist_int_scale=$int_scale
override_file="${XDG_RUNTIME_DIR:-/tmp}/omarchy/display-resolution/$internal"
if [[ -f $override_file ]]; then
  read -r orig_mode orig_scale <"$override_file" || true
  if [[ $orig_mode =~ ^[0-9]+x[0-9]+@[0-9.]+$ && $orig_scale =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    persist_int_mode=$orig_mode
    persist_int_scale=$orig_scale
  fi
fi

# Persist across restarts in monitors.lua, inside a clearly marked block so
# re-running this script (or picking a different direction) replaces it
# cleanly instead of piling up stale rules.
monitor_lua="$HOME/.config/hypr/monitors.lua"
begin_marker="-- omarchy-arrangement:begin (managed by the Display menu — edits inside are overwritten)"
end_marker="-- omarchy-arrangement:end"

if (( dry_run )); then
  echo "$begin_marker"
  monitor_rule "$internal" "$persist_int_mode" "0x0" "$persist_int_scale" "$int_cm"; echo
  monitor_rule "$external" "preferred" "${ext_x}x${ext_y}" "$ext_scale" "$ext_cm"; echo
  echo "$end_marker"
elif [[ -f $monitor_lua ]]; then
  tmp=$(mktemp)
  awk -v begin="$begin_marker" -v end="$end_marker" '
    $0 == begin { skipping = 1; next }
    $0 == end   { skipping = 0; next }
    !skipping   { print }
  ' "$monitor_lua" > "$tmp"

  {
    cat "$tmp"
    echo ""
    echo "$begin_marker"
    monitor_rule "$internal" "$persist_int_mode" "0x0" "$persist_int_scale" "$int_cm"; echo
    monitor_rule "$external" "preferred" "${ext_x}x${ext_y}" "$ext_scale" "$ext_cm"; echo
    echo "$end_marker"
  } > "$monitor_lua"
  rm -f "$tmp"
fi
