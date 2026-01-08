#!/bin/bash
# ptt-setup.sh - One-time setup for PTT on X11 session start
# Disable key repeat for Menu key to prevent rapid-fire hotkey events

xset -r 135

# Small delay so systemd can track the process before it exits
sleep 0.5
