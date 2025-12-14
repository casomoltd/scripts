# Scripts

A collection of utility scripts for Linux.

## Tools

| Tool | Description |
|------|-------------|
| [transcribe](transcribe/) | Push-to-talk voice dictation using whisper.cpp |

## Structure

```
scripts/
├── transcribe/     # Voice-to-text tools
└── vendor/         # Third-party dependencies (submodules)
```

## Setup

Clone with submodules:

```bash
git clone --recurse-submodules git@github.com:casomoltd/scripts.git
```

See individual tool READMEs for setup instructions.
