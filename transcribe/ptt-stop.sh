#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$SCRIPT_DIR/../vendor/whisper.cpp"
BIN="$ROOT/build/bin/whisper-cli"
MODEL="$ROOT/models/ggml-base.en.bin"
TMP=/tmp/whisper_ptt.wav
PIDFILE=/tmp/whisper_ptt.pid

# Stop recording cleanly
if [ -f "$PIDFILE" ]; then
  PID=$(cat "$PIDFILE")
  rm -f "$PIDFILE"

  # Send SIGINT and wait for arecord to finalize WAV header
  if kill -0 "$PID" 2>/dev/null; then
    kill -SIGINT "$PID" 2>/dev/null
    # Wait for process to actually terminate (up to 2s)
    for i in {1..20}; do
      kill -0 "$PID" 2>/dev/null || break
      sleep 0.1
    done
  fi
fi

# Give ALSA extra time to flush
sleep 0.3

# Sanity check: file exists and is non-empty
if [ ! -s "$TMP" ]; then
  exit 0
fi

# Transcribe: -nt removes timestamps, -np removes progress
# stderr has all the model loading info, stdout has the text
RAW=$("$BIN" -m "$MODEL" -f "$TMP" -nt -np 2>/dev/null)

# Clean up: trim whitespace, collapse multiple spaces
TEXT=$(echo "$RAW" | tr '\n' ' ' | sed 's/  */ /g; s/^ *//; s/ *$//')

# Only type if we got actual text
if [ -n "$TEXT" ]; then
  xdotool type --delay 1 --clearmodifiers "$TEXT "
fi
