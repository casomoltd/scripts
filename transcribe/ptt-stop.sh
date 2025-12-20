#!/usr/bin/env bash
# ptt-stop.sh - Stop recording and transcribe
#
# Called on hotkey release. Stops arecord, acquires lock, transcribes audio
# with whisper.cpp, and types the result into the focused window.

source "$(dirname "${BASH_SOURCE[0]}")/env.sh"

# Stop any recording (harmless if not running)
pkill -f "arecord.*whisper_ptt.wav" 2>/dev/null

# Wait for arecord to finalize WAV header
sleep 0.2

# Acquire lock (waits if ptt-start is still cleaning up)
if ! acquire_lock; then
  acquire_lock_wait 2 || {
    log "STOP skipped (lock timeout)"
    exit 0
  }
fi

DURATION=$(get_duration)

# Check for valid audio
if [ ! -s "$TMP" ]; then
  log "STOP duration=${DURATION}s (no audio file)"
  exit 0
fi

# Get actual file size in bytes
SIZE_BYTES=$(stat -c%s "$TMP" 2>/dev/null || echo 0)
SIZE=$(du -h "$TMP" | cut -f1)

# WAV header is 44 bytes; at 16kHz 16-bit mono, meaningful audio needs more
# Anything under ~1000 bytes is basically empty (header + minimal data)
if [ "$SIZE_BYTES" -lt 1000 ]; then
  log_err "STOP duration=${DURATION}s size=${SIZE_BYTES}B (recording empty - no audio captured)"
  rm -f "$TMP"
  exit 0
fi
log "STOP duration=${DURATION}s size=${SIZE} mem=$(get_mem_avail) gpu=$(get_gpu_mem)"

# Transcribe with timeout
WHISPER_START=$(date +%s.%N)
RAW=$(timeout "$WHISPER_TIMEOUT" "$WHISPER_BIN" \
  -m "$WHISPER_MODEL" -f "$TMP" -np 2>/dev/null)
WHISPER_EXIT=$?
WHISPER_TIME=$(echo "$(date +%s.%N) - $WHISPER_START" | bc | xargs printf "%.1f")

if [ $WHISPER_EXIT -eq 124 ]; then
  log "WHISPER timeout after ${WHISPER_TIMEOUT}s"
  exit 1
elif [ $WHISPER_EXIT -ne 0 ]; then
  log "WHISPER exit=${WHISPER_EXIT} time=${WHISPER_TIME}s (failed)"
  exit 1
fi

log "WHISPER exit=0 time=${WHISPER_TIME}s"

# Strip timestamp brackets and clean up whitespace
TEXT=$(echo "$RAW" | sed 's/\[[^]]*\]//g' | xargs)

if [ -n "$TEXT" ]; then
  xdotool type --delay 1 --clearmodifiers "$TEXT "
  log "TYPED chars=${#TEXT}"
else
  log "TYPED chars=0 (empty)"
fi
