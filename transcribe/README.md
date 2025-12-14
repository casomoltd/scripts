# Push-to-Talk Voice Transcription

Local speech-to-text with hotkey-triggered recording and text injection into the focused window.

Hold hotkey → speak → release → text appears.

## Requirements

```bash
sudo apt install -y \
  build-essential \
  cmake \
  make \
  git \
  alsa-utils \
  xdotool \
  xbindkeys
```

- `build-essential`, `cmake`, `make` - build whisper.cpp
- `alsa-utils` - provides `arecord` for audio capture
- `xdotool` - injects text as keyboard input
- `xbindkeys` - reliable press/release hotkeys (sxhkd does NOT work for PTT)

## Setup

### 1. Build whisper.cpp

```bash
cd vendor/whisper.cpp
cmake -B build
cmake --build build -j$(nproc)
```

Verify:

```bash
./build/bin/whisper-cli --help
```

### 2. Download a model

```bash
cd vendor/whisper.cpp/models
./download-ggml-model.sh base.en
```

This downloads `ggml-base.en.bin` (~140 MB).

Other options: `tiny.en`, `small.en`, `medium.en`, `large` (smaller = faster, larger = more accurate).

Verify:

```bash
ls -lh ggml-base.en.bin
```

### 3. Configure hotkey

Create `~/.xbindkeysrc`:

```
# PTT START
"bash /full/path/to/scripts/transcribe/ptt-start.sh"
  Control+space

# PTT STOP
"bash /full/path/to/scripts/transcribe/ptt-stop.sh"
  release+Control+space
```

Start the daemon:

```bash
xbindkeys
```

### 4. Persist across reboots

Create `~/.config/autostart/xbindkeys.desktop`:

```ini
[Desktop Entry]
Type=Application
Name=xbindkeys
Exec=xbindkeys
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
```

Note: `Ctrl+Space` may conflict with input methods (IBus/Fcitx) or IDE autocomplete. Rebind those if needed.

## Usage

1. Focus target window (terminal, editor, etc.)
2. Hold `Ctrl+Space` and speak
3. Release to transcribe and inject text

## Troubleshooting

**No text appears:**
```bash
# Check recording exists
ls -la /tmp/whisper_ptt.wav

# Test whisper manually
./vendor/whisper.cpp/build/bin/whisper-cli \
  -m vendor/whisper.cpp/models/ggml-base.en.bin \
  -f /tmp/whisper_ptt.wav

# Play back audio to verify mic works
aplay /tmp/whisper_ptt.wav
```

**Hotkey not triggering:**
```bash
# Check xbindkeys is running
pgrep xbindkeys

# Test in foreground (shows trigger events)
xbindkeys -n

# Kill conflicting daemons
pkill sxhkd
```

**Garbled/repeated output:**
- WAV header corruption from recording not finalizing
- Increase `sleep` value in `ptt-stop.sh` if needed
