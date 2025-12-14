#!/usr/bin/env bash

TMP=/tmp/whisper_ptt.wav
PIDFILE=/tmp/whisper_ptt.pid

# kill any stray recorder
pkill -f "arecord.*whisper_ptt.wav" 2>/dev/null
sleep 0.1

rm -f "$TMP"

# start recording (max 60s safety limit)
# -q = quiet, -c 1 = mono, -t wav ensures proper header
arecord -q -f S16_LE -r 16000 -c 1 -t wav -d 60 "$TMP" &
echo $! > "$PIDFILE"
