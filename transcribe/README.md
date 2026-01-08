# Push-to-Talk Voice Transcription

Hold hotkey → speak → release → text appears.

## Requirements

```bash
sudo apt install -y build-essential cmake make git alsa-utils xdotool xbindkeys
```

## Setup

### 1. Build whisper.cpp

```bash
cd vendor/whisper.cpp

# CPU only
cmake -B build && cmake --build build -j$(nproc)

# With CUDA (recommended)
sudo apt install nvidia-cuda-toolkit
cmake -B build -DGGML_CUDA=ON && cmake --build build -j$(nproc)
```

### 2. Download models

```bash
cd vendor/whisper.cpp/models
./download-ggml-model.sh base.en
./download-vad-model.sh silero-v6.2.0
```

Whisper options: `tiny.en` (fast) → `base.en` → `small.en` → `medium.en` → `large` (accurate)

VAD (Voice Activity Detection) filters trailing silence to prevent hallucinations like "you" or "Thank you for watching".

### 3. Configure hotkey

```bash
cp transcribe/xbindkeysrc.template ~/.xbindkeysrc
xbindkeys          # Start daemon
```

### 4. Disable key repeat for Menu key

The Menu key (keycode 135) must have auto-repeat disabled to prevent rapid-fire
hotkey events when held. Two methods ensure this persists:

**User-level (X session start):**
```bash
cat >> ~/.xsessionrc << 'EOF'
# Disable key repeat for Menu key (PTT hotkey)
xset -r 135
EOF
```

**System-level (keyboard hotplug):**
```bash
sudo tee /etc/udev/rules.d/99-ptt-keyboard.rules << 'EOF'
ACTION=="add", SUBSYSTEM=="input", ENV{ID_INPUT_KEYBOARD}=="1", RUN+="/usr/bin/xset -r 135"
EOF
sudo udevadm control --reload-rules
```

The udev rule handles keyboard replug; xsessionrc handles login/unlock.

### 5. Autostart

xbindkeys auto-starts via `/etc/xdg/autostart/xbindkeys.desktop`.

## Usage

1. Focus target window
2. Hold `Ctrl+Menu` and speak
3. Release → text typed

## Troubleshooting

**No text appears:**
```bash
ls -la /tmp/whisper_ptt.wav                    # Recording exists?
aplay /tmp/whisper_ptt.wav                     # Mic working?
./vendor/whisper.cpp/build/bin/whisper-cli \
  -m vendor/whisper.cpp/models/ggml-base.en.bin \
  -f /tmp/whisper_ptt.wav                      # Whisper working?
```

**Hotkey not triggering:**
```bash
pgrep xbindkeys    # Running?
xbindkeys -k       # Test key detection
pkill sxhkd        # Kill conflicting daemons
```

**Empty recordings (rapid start/stop in logs):**
```bash
journalctl -t whisper-ptt -p err --since "5 min ago"
xset -r 135        # Immediate fix; see step 4 for persistent setup
```

## Logs

```bash
journalctl -t whisper-ptt --since "10 min ago"    # Recent logs
journalctl -t whisper-ptt -f                       # Follow live
journalctl -t whisper-ptt -p err                   # Errors only
```

Example output:
```
START pid=12345
STOP duration=2.3s size=45K mem=4.2GB gpu=1200MB/8192MB
WHISPER exit=0 time=0.8s
TYPED chars=42
```

Error (empty recording):
```
STOP duration=0.1s size=128B (recording empty - no audio captured)
```

## Known Issues

**CUDA crashes with rapid triggers:** Lock file prevents concurrent whisper processes. 30s timeout kills hung transcriptions.

```bash
journalctl -b -1 | grep -i "whisper\|coredump"    # Check past crashes
```
