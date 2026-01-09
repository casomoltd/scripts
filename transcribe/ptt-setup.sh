#!/bin/bash
# ptt-setup.sh - Setup/reset PTT after login or keyboard replug
# Clears stale processes and restarts xbindkeys to grab the current keyboard

source "$(dirname "${BASH_SOURCE[0]}")/env.sh"

# Kill stale processes
pkill -f "arecord.*whisper_ptt.wav" 2>/dev/null
killall xbindkeys 2>/dev/null

# Clear stale lock/temp files
rm -f "$LOCKFILE" "$TMP" "$TMP_TEXT"

# Disable key repeat for Menu key (keycode 135) to prevent rapid-fire events
xset -r 135

# Restart xbindkeys to grab keys on the current keyboard device
sleep 0.2
xbindkeys -f "$HOME/.xbindkeysrc"

log_info "PTT setup complete"

# Small delay so systemd can track the process before it exits
sleep 0.3
