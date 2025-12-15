#!/usr/bin/env bash

# Set to /tmp/whisper_ptt.log for debugging
LOG=/dev/null
TMP=/tmp/whisper_ptt.wav
PIDFILE=/tmp/whisper_ptt.pid

# Already recording? Skip.
if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE" 2>/dev/null)" 2>/dev/null; then
  echo "$(date '+%H:%M:%S.%3N') START skipped" >> "$LOG"
  exit 0
fi

echo "$(date '+%H:%M:%S.%3N') START" >> "$LOG"

# Kill any stray recorder
pkill -f "arecord.*whisper_ptt.wav" 2>/dev/null

rm -f "$TMP"

# Start recording (max 60s safety limit)
arecord -q -f S16_LE -r 16000 -c 1 -t wav -d 60 "$TMP" &
echo $! > "$PIDFILE"
