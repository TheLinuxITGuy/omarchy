#!/bin/bash

set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
source "$ROOT/test/shell.d/base-test.sh"

fail() {
  echo "cursor-style-test: FAIL: $1${2:+: $2}" >&2
  exit 1
}

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

mkdir -p "$tmp_dir/bin" "$tmp_dir/home/.config/hypr" "$tmp_dir/home/.config/gtk-3.0"

cat >"$tmp_dir/bin/hyprctl" <<'EOF'
#!/bin/bash
printf '%s\n' "$*" >>"$HYPRCTL_LOG"
echo ok
EOF
chmod +x "$tmp_dir/bin/hyprctl"

cat >"$tmp_dir/bin/gsettings" <<'EOF'
#!/bin/bash
printf '%s\n' "$*" >>"$GSETTINGS_LOG"
if [[ ${1:-} == "get" ]]; then
  printf "'%s'\n" "${3:-}"
fi
EOF
chmod +x "$tmp_dir/bin/gsettings"

cat >"$tmp_dir/bin/omarchy-notification-send" <<'EOF'
#!/bin/bash
printf '%s\n' "$*" >>"$NOTIFY_LOG"
EOF
chmod +x "$tmp_dir/bin/omarchy-notification-send"

cat >"$tmp_dir/bin/omarchy-hook" <<'EOF'
#!/bin/bash
printf '%s\n' "$*" >>"$HOOK_LOG"
EOF
chmod +x "$tmp_dir/bin/omarchy-hook"

cat >"$tmp_dir/bin/omarchy-menu-input" <<'EOF'
#!/bin/bash
if [[ -z ${MENU_INPUT_VALUE+x} ]]; then
  exit 1
fi
printf '%s' "$MENU_INPUT_VALUE"
EOF
chmod +x "$tmp_dir/bin/omarchy-menu-input"

export PATH="$tmp_dir/bin:$ROOT/bin:$PATH"
export HOME="$tmp_dir/home"
export DBUS_SESSION_BUS_ADDRESS="test"
export HYPRCTL_LOG="$tmp_dir/hyprctl"
export GSETTINGS_LOG="$tmp_dir/gsettings"
export NOTIFY_LOG="$tmp_dir/notify"
export HOOK_LOG="$tmp_dir/hook"
unset HYPRCURSOR_SIZE XCURSOR_SIZE

mkdir -p "$tmp_dir/home/.local/share/icons/Fake-Dark/cursors"
export XDG_DATA_HOME="$tmp_dir/home/.local/share"

[[ $(omarchy-cursor-size-list | tr '\n' ' ') == "16 20 24 28 32 36 40 44 48 56 64 " ]] ||
  fail "cursor size list emits standard sizes" "$(omarchy-cursor-size-list | tr '\n' ' ')"
pass "cursor size list emits standard sizes"

omarchy-cursor-list | rg -qx 'Fake-Dark' ||
  fail "cursor list finds the fake theme in HOME icons"
pass "cursor list finds the fake theme in HOME icons"

cat >"$HOME/.config/hypr/hyprland.lua" <<'EOF'
hl.env("XCURSOR_THEME", "Fake-Dark")
hl.env("HYPRCURSOR_THEME", "Fake-Dark")
hl.env("XCURSOR_SIZE", "64")
hl.env("HYPRCURSOR_SIZE", "64")
EOF

[[ $(omarchy-cursor-size-current) == "64" ]] ||
  fail "cursor size current reads the Hyprland config"
pass "cursor size current reads the Hyprland config"

[[ $(omarchy-cursor-current) == "Fake-Dark" ]] ||
  fail "cursor theme current reads the Hyprland config"
pass "cursor theme current reads the Hyprland config"

omarchy-cursor-size-set 32

[[ $(tail -n 1 "$HYPRCTL_LOG") == "setcursor Fake-Dark 32" ]] ||
  fail "cursor size applies the theme at the requested size" "$(tail -n 1 "$HYPRCTL_LOG")"
pass "cursor size applies the theme at the requested size"

rg -q 'XCURSOR_SIZE", "32"' "$HOME/.config/hypr/hyprland.lua" &&
  rg -q 'HYPRCURSOR_SIZE", "32"' "$HOME/.config/hypr/hyprland.lua" ||
  fail "cursor size persists both env variables"
pass "cursor size persists both env variables"

if omarchy-cursor-size-set 0; then
  fail "cursor size rejects zero"
fi
pass "cursor size rejects zero"

if omarchy-cursor-size-set abc; then
  fail "cursor size rejects non-numeric sizes"
fi
pass "cursor size rejects non-numeric sizes"

MENU_INPUT_VALUE=55 omarchy-cursor-size-custom

[[ $(tail -n 1 "$HYPRCTL_LOG") == "setcursor Fake-Dark 55" ]] ||
  fail "custom size applies the typed value" "$(tail -n 1 "$HYPRCTL_LOG")"
pass "custom size applies the typed value"

omarchy-cursor-set Fake-Dark

[[ $(tail -n 1 "$HYPRCTL_LOG") == "setcursor Fake-Dark 55" ]] ||
  fail "cursor theme applies the theme" "$(tail -n 1 "$HYPRCTL_LOG")"
pass "cursor theme applies the theme"

tail -n 1 "$HOOK_LOG" | rg -q 'cursor-set Fake-Dark' ||
  fail "cursor theme runs the theme hook"
pass "cursor theme runs the theme hook"

if omarchy-cursor-set 'Bad"Name' 2>/dev/null; then
  fail "cursor theme rejects invalid theme names"
fi
pass "cursor theme rejects invalid theme names"

if omarchy-cursor-set Not-Installed 2>/dev/null; then
  fail "cursor theme rejects unknown themes"
fi
pass "cursor theme rejects unknown themes"

rg -q 'toggle omarchy.cursor-style' "$ROOT/bin/omarchy-cursor-open" ||
  fail "cursor open launcher toggles the first-party overlay"
pass "cursor open launcher toggles the first-party overlay"

jq -r '.entryPoints.overlay' "$ROOT/shell/plugins/cursor-style/manifest.json" | rg -qx 'CursorStyle.qml' ||
  fail "manifest points the overlay at CursorStyle.qml"
pass "manifest points the overlay at CursorStyle.qml"

rg -q '"style.cursor":.*"Change Cursor"' "$ROOT/default/omarchy/omarchy-menu.jsonc" ||
  fail "menu exposes Change Cursor under Style"
rg -q '"style.cursor".*"omarchy-cursor-open"' "$ROOT/default/omarchy/omarchy-menu.jsonc" ||
  fail "menu opens the cursor picker through omarchy-cursor-open"
pass "menu exposes Change Cursor under Style"

echo "all tests passed"
