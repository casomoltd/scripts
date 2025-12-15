#!/usr/bin/env bash

# Set to /tmp/whisper_ptt.log for debugging
LOG=/dev/null
TMP=/tmp/whisper_ptt.wav
PIDFILE=/tmp/whisper_ptt.pid

# Not recording? Skip.
if [ ! -f "$PIDFILE" ]; then
  echo "$(date '+%H:%M:%S.%3N') STOP skipped" >> "$LOG"
  exit 0
fi

echo "$(date '+%H:%M:%S.%3N') STOP" >> "$LOG"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="$SCRIPT_DIR/../vendor/whisper.cpp/build/bin/whisper-cli"
MODEL="$SCRIPT_DIR/../vendor/whisper.cpp/models/ggml-base.en.bin"

# Stop recording
PID=$(cat "$PIDFILE")
rm -f "$PIDFILE"

if kill -0 "$PID" 2>/dev/null; then
  kill -SIGINT "$PID" 2>/dev/null
  # Wait for arecord to finalize WAV header
  for i in {1..20}; do
    kill -0 "$PID" 2>/dev/null || break
    sleep 0.1
  done
fi

# Sanity check
if [ ! -s "$TMP" ]; then
  exit 0
fi

# Transcribe (keep timestamps to get [BLANK_AUDIO] token, then strip all [...])
RAW=$("$BIN" -m "$MODEL" -f "$TMP" -np 2>/dev/null)
TEXT=$(echo "$RAW" | sed 's/\[[^]]*\]//g' | xargs)

# Type the text
if [ -n "$TEXT" ]; then
  xdotool type --delay 1 --clearmodifiers "$TEXT "
fi
