#!/usr/bin/env bash
# env.sh - Shared definitions for PTT voice transcription scripts
#
# Provides constants, logging, and lock management for push-to-talk
# transcription using whisper.cpp. Sourced by ptt-start.sh and ptt-stop.sh.

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------

# Temp files
TMP=/tmp/whisper_ptt.wav
LOCKFILE=/tmp/whisper_ptt.lock
TIMEFILE=/tmp/whisper_ptt.start

# Timeouts (seconds)
WHISPER_TIMEOUT=30

# Paths (derived from caller's location)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
WHISPER_BIN="$SCRIPT_DIR/../vendor/whisper.cpp/build/bin/whisper-cli"
WHISPER_MODEL="$SCRIPT_DIR/../vendor/whisper.cpp/models/ggml-base.en.bin"

# ------------------------------------------------------------------------------
# Functions
# ------------------------------------------------------------------------------

# Log message to systemd journal with whisper-ptt tag
log() { logger -t whisper-ptt "$1"; }

# Acquire exclusive lock (non-blocking). Returns 1 if already locked.
acquire_lock() {
  exec 9>"$LOCKFILE"
  flock -n 9
}

# Acquire exclusive lock with timeout (blocking). Returns 1 on timeout.
acquire_lock_wait() {
  local timeout=${1:-2}
  exec 9>"$LOCKFILE"
  flock -w "$timeout" 9
}

# Start a timer by writing current time to TIMEFILE
start_timer() {
  date +%s.%N > "$TIMEFILE"
}

# Get duration since timer start (returns "?" if no timer). Cleans up TIMEFILE.
get_duration() {
  if [ -f "$TIMEFILE" ]; then
    local start end
    start=$(cat "$TIMEFILE")
    end=$(date +%s.%N)
    rm -f "$TIMEFILE"
    echo "$end - $start" | bc | xargs printf "%.1f"
  else
    echo "?"
  fi
}

# Get available system memory as human-readable string
get_mem_avail() {
  awk '/MemAvailable/ {printf "%.1fGB", $2/1024/1024}' /proc/meminfo
}

# Get GPU memory usage (returns "N/A" if nvidia-smi unavailable)
get_gpu_mem() {
  nvidia-smi --query-gpu=memory.used,memory.total \
    --format=csv,noheader,nounits 2>/dev/null \
    | awk -F', ' '{printf "%dMB/%dMB", $1, $2}' \
    || echo "N/A"
}
