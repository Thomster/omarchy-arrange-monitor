#!/bin/bash

# Switches a monitor's resolution for the "My Display" panel's DISPLAY
# RESOLUTION section. Runtime only: nothing is written to monitors.lua, so a
# Hyprland config reload or a reboot restores the configured mode.
#
# Keeps the monitor's current position and color-management preset (e.g.
# "dp3" on a Display P3 panel), and picks the highest refresh rate the
# monitor offers for the requested size.

set -euo pipefail

monitor="${1:-}"
size="${2:-}"
scale="${3:-}"

# All three end up inside a Lua string passed to `hyprctl eval`, so only
# plain values may pass.
if [[ ! $monitor =~ ^[A-Za-z0-9._-]+$ || ! $size =~ ^[0-9]+x[0-9]+$ || ! $scale =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  echo "Usage: resolution.sh MONITOR WIDTHxHEIGHT SCALE" >&2
  exit 1
fi

info=$(hyprctl monitors -j | jq -e -c --arg n "$monitor" '.[] | select(.name == $n)') || {
  echo "Monitor $monitor not found" >&2
  exit 1
}

mode=$(jq -r --arg s "$size" '
  [.availableModes[] | select(startswith($s + "@"))
   | {mode: ., rate: (sub("^[^@]*@"; "") | sub("Hz$"; "") | tonumber)}]
  | max_by(.rate) | .mode // "" | sub("Hz$"; "")
' <<<"$info")
if [[ -z $mode ]]; then
  echo "$monitor doesn't offer $size" >&2
  exit 1
fi

position=$(jq -r '"\(.x)x\(.y)"' <<<"$info")
cm=$(jq -r '.colorManagementPreset // ""' <<<"$info")
cm_arg=""
[[ $cm =~ ^[A-Za-z0-9_-]+$ && $cm != "srgb" ]] && cm_arg=", cm = \"$cm\""

hyprctl eval "hl.monitor({ output = \"$monitor\", mode = \"$mode\", position = \"$position\", scale = $scale$cm_arg })" >/dev/null
