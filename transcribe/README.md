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

**CPU-only (default):**

```bash
cd vendor/whisper.cpp
cmake -B build
cmake --build build -j$(nproc)
```

**With NVIDIA GPU acceleration (recommended):**

```bash
# Install CUDA toolkit first
sudo apt install nvidia-cuda-toolkit

# Build with CUDA support
cd vendor/whisper.cpp
cmake -B build -DGGML_CUDA=ON
cmake --build build -j$(nproc)
```

Verify:

```bash
./build/bin/whisper-cli --help

# Check GPU is detected (should show your GPU name)
./build/bin/whisper-cli -m models/ggml-base.en.bin -f /tmp/test.wav 2>&1 | grep -i cuda
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

Copy the template to your home directory:

```bash
cp transcribe/xbindkeysrc.template ~/.xbindkeysrc
```

Disable key repeat for the Menu key (required to prevent rapid start/stop):

```bash
xset -r 135
```

Start the daemon (for this session):

```bash
xbindkeys
```

### 4. Autostart

The xbindkeys package installs a system-wide autostart entry at
`/etc/xdg/autostart/xbindkeys.desktop`. This automatically starts xbindkeys
on login if `~/.xbindkeysrc` exists.

To persist the key repeat setting, add to `~/.xprofile`:

```bash
echo 'xset -r 135  # Disable key repeat for Menu key (PTT)' >> ~/.xprofile
```

## Usage

1. Focus target window (terminal, editor, etc.)
2. Hold `Control+Menu` and speak
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
xbindkeys -k

# Kill conflicting daemons
pkill sxhkd
```

**Garbled/repeated output:**
- WAV header corruption from recording not finalizing
- Increase `sleep` value in `ptt-stop.sh` if needed

## Debugging

Logs are written to the systemd journal. View with:

```bash
# View PTT logs
journalctl -t whisper-ptt --since "10 min ago"

# Follow logs in real-time
journalctl -t whisper-ptt -f

# Check for system issues (OOM, crashes)
journalctl -p warning --since "10 min ago"
```

Example log output:
```
whisper-ptt: START pid=12345
whisper-ptt: STOP duration=2.3s size=45K mem=4.2GB gpu=1200MB/8192MB
whisper-ptt: WHISPER exit=0 time=0.8s
whisper-ptt: TYPED chars=42
```

## Known Issues

### CUDA crashes with rapid PTT triggers

If you trigger PTT rapidly (press-release-press before transcription finishes), multiple whisper-cli processes can compete for GPU memory, causing system freezes.

**Symptoms:**
- System freeze requiring hard reboot
- Corrupted/interleaved text in output
- `coredump: whisper-cli: over core_pipe_limit` in logs

**Mitigation (implemented):**
- Lock file prevents concurrent whisper-cli processes
- 30-second timeout kills hung transcriptions
- GPU memory logged for debugging

**Check for past crashes:**
```bash
# Check previous boot for whisper crashes
journalctl -b -1 | grep -i "whisper\|coredump"

# Check if system was under load before crash
journalctl -b -1 -p warning | tail -20
```
