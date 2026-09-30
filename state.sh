#!/bin/bash

# Local copy of omarchy-monitor-state, extended to also report each
# display's position (x, y) and scale so the plugin can derive the current
# left/top/right arrangement without an extra hyprctl round-trip.

monitors_json=$(hyprctl monitors all -j)
focused_monitor=$(printf '%s\n' "$monitors_json" | jq -r '[.[] | select(.focused == true)][0].name // ""')

{ omarchy-brightness-display --monitor "$focused_monitor" 2>/dev/null; echo; } | head -n 1

printf '%s\n' "$monitors_json" | jq -r '
  def internal: test("^(eDP|LVDS|DSI)-");
  ([.[] | select(.name | internal)][0].name // ""),
  ([.[] | select((.name | internal) | not)][0].name // ""),
  ([.[] | select((.name | internal) and .disabled != true)][0].name // ""),
  ([.[] | select(.mirrorOf != "none") | if (.name | internal) then .mirrorOf else .name end][0] // "")
'

printf '%s\n' "$focused_monitor"
omarchy-hyprland-monitor-scaling 2>/dev/null || echo

printf '%s\n' "$monitors_json" | jq -c \
  '[.[] | {name, enabled:(.disabled != true), focused:(.focused == true), width, height, x, y, scale, availableModes}]'
