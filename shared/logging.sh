#!/usr/bin/env bash
# logging.sh - Logging utilities for systemd journal
#
# Set LOG_TAG before sourcing to customize the journal identifier.
# Falls back to "scripts" if LOG_TAG is not set.
#
# Usage:
#   LOG_TAG="my-service"
#   source "$SHARED_DIR/logging.sh"
#   log_info "Starting up"
#   log_error "Something failed"

LOG_TAG="${LOG_TAG:-scripts}"

log_info() {
    logger -t "$LOG_TAG" "$1"
}

log_warn() {
    logger -p user.warning -t "$LOG_TAG" "$1"
}

log_error() {
    logger -p user.err -t "$LOG_TAG" "$1"
}

log_debug() {
    [[ "${DEBUG:-0}" == "1" ]] && logger -p user.debug -t "$LOG_TAG" "$1"
}
