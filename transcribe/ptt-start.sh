#!/usr/bin/env bash
# ptt-start.sh - Start PTT voice recording
#
# Called on hotkey press. Acquires lock, starts recording, and holds lock
# until killed by ptt-stop.sh. Only one recording/transcription can run at
# a time due to the exclusive lock.

source "$(dirname "${BASH_SOURCE[0]}")/env.sh"

if ! acquire_lock; then
  log_info "START skipped (operation in progress)"
  exit 0
fi

# Kill any stray recorder and clean up
pkill -f "arecord.*whisper_ptt.wav" 2>/dev/null
rm -f "$TMP"

start_timer

# Start recording (max 60s safety limit)
arecord -q -f S16_LE -r 16000 -c 1 -t wav -d 60 "$TMP" &
ARECORD_PID=$!

log_info "START pid=$ARECORD_PID"

# Wait for arecord - keeps lock held until ptt-stop kills us
wait $ARECORD_PID
