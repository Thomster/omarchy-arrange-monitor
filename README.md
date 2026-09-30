# omarchy-display-arrange

An [Omarchy](https://omarchy.org/) shell bar widget: brightness slider plus
one-click Left/Top/Right arrangement for a second monitor. A clone of the
stock `omarchy.monitor` widget with a monitor-position picker added.

Arrangement is only offered for the classic laptop-plus-one-external-monitor
pairing, and the current arrangement is derived from live monitor geometry
(not a remembered choice), so it stays honest if the layout changes some
other way.

Arranging only changes positions: both displays keep their current mode,
scale and color-management preset. The rules written to `monitors.lua`
persist the internal display's configured mode, not a temporary one picked
under Display Resolution. `arrange.sh left|top|right --dry-run` prints what
it would do without changing anything.

## Display resolution

Below the brightness slider, a **Display Resolution** section switches the
focused monitor between a few sizes with one click. Defaults are
3840×2160 (scale 1.5), 2560×1440 and 1920×1080 (scale 1). Only sizes the
monitor offers are shown, and the section hides with fewer than two. The
switch keeps the monitor's position and color-management preset (e.g. `dp3`)
and picks the highest refresh rate for that size.

It is **runtime only**: nothing is written to `monitors.lua`, so a Hyprland
config reload or a reboot restores the configured mode.

Change the offered sizes per bar entry in `shell.json`:

```json
{ "id": "omarchy_plus_display-arrange",
  "resolutions": [ { "size": "2560x1600", "scale": 1.25 }, { "size": "1920x1200", "scale": 1 } ] }
```

## Install

```
omarchy plugin add https://github.com/Thomster/omarchy-display-arrange.git
```

## Requirements

- Hyprland (uses `hyprctl` for monitor geometry/positioning)

## How this came to be

This is a personal customization for my own Omarchy setup, built with the
help of [Claude Code](https://claude.com/claude-code) (Anthropic's AI coding
agent). I use it daily on my own machine, but I'm not a professional plugin
developer — please read through the source before installing, especially
anything that touches system or network state, and open an issue if
something looks off.

## License

MIT
