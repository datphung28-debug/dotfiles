#!/usr/bin/env bash
set -euo pipefail

# Serpantinum keeps its own Matugen config for app theming.  Add a separate,
# Hyprland-only pass so its generated Lua colors update with every wallpaper.
serpantinum_dir="${SERPANTINUM_DIR:-$HOME/.local/share/serpantinum}"
source_file="$serpantinum_dir/src/quickshell/singletons/theme/Matugen.qml"
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
patch_file="$config_dir/serpantinum/patches/matugen-user-config.patch"
hypr_matugen_config="$config_dir/serpantinum/matugen-hyprland.toml"

if [[ ! -f "$source_file" ]]; then
    printf 'Serpantinum source not found: %s\n' "$source_file" >&2
    exit 1
fi
if [[ ! -f "$patch_file" ]]; then
    printf 'Patch file not found: %s\n' "$patch_file" >&2
    exit 1
fi
if [[ ! -f "$hypr_matugen_config" ]]; then
    printf 'Hyprland Matugen config not found: %s\n' "$hypr_matugen_config" >&2
    exit 1
fi

if grep -q 'property string hyprConfigPath' "$source_file"; then
    printf 'Matugen user-config patch is already applied.\n'
else
    patch --forward --directory="$serpantinum_dir" --strip=1 < "$patch_file"
    printf 'Applied Matugen user-config patch.\n'
fi

# Restart the running shell so Quickshell recompiles the patched QML.  A plain
# `serpantinum reload` only reloads colors and keeps the old QML process alive.
# This is harmless when no Serpantinum instance is running.
if command -v serpantinum >/dev/null 2>&1; then
    serpantinum restart >/dev/null 2>&1 || true
fi

# If Serpantinum has a cached wallpaper, regenerate immediately.  Otherwise
# the next wallpaper selection will exercise the patched path.
current_wallpaper="$HOME/.cache/serpantinum/wallpaper/current_wallpaper.png"
if [[ -f "$current_wallpaper" ]] && command -v matugen >/dev/null 2>&1; then
    matugen image "$current_wallpaper" -c "$hypr_matugen_config" >/dev/null 2>&1 || true
    printf 'Regenerated Hyprland colors from the cached wallpaper.\n'
else
    printf 'Done. Choose a wallpaper once to regenerate Hyprland colors.\n'
fi
