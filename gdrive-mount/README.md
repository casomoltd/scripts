# Google Drive Mount with rclone

Mount Google Drive as a FUSE filesystem on Ubuntu Linux using rclone.

## Prerequisites

```bash
sudo apt update
sudo apt install -y rclone fuse
```

## Setup

### 1. Configure rclone

Run the interactive configuration:

```bash
rclone config
```

Create a remote named `gdrive`:

1. Select `n` for new remote
2. Name it `gdrive`
3. Storage type: `18` (Google Drive)
4. `client_id`: Leave blank (press Enter) - uses rclone's internal key, fine for personal use
5. `client_secret`: Leave blank (press Enter)
6. `scope`: `1` (drive) - full read/write access
7. `service_account_file`: Leave blank (press Enter) - not needed for personal use
8. Advanced config: `n`
9. Auto config: `y` - opens browser for OAuth login
10. Configure as team drive: `n` (unless using Google Workspace shared drive)

Config is stored at: `~/.config/rclone/rclone.conf`

### 2. Install systemd service

Symlink to keep in sync with repo:

```bash
mkdir -p ~/.config/systemd/user
ln -sf /path/to/scripts/gdrive-mount/rclone-gdrive.service ~/.config/systemd/user/

systemctl --user daemon-reload
systemctl --user enable rclone-gdrive.service
systemctl --user start rclone-gdrive.service
```

### 3. Enable persistent sessions

For the mount to survive logouts:

```bash
loginctl enable-linger $USER
```

## Usage

```bash
# Start/stop/restart
systemctl --user start rclone-gdrive.service
systemctl --user stop rclone-gdrive.service
systemctl --user restart rclone-gdrive.service

# Check status
systemctl --user status rclone-gdrive.service

# View logs
journalctl --user -u rclone-gdrive.service -f
```

## Configuration

Edit `rclone-gdrive.service` directly, then reload:

```bash
systemctl --user daemon-reload
systemctl --user restart rclone-gdrive.service
```

Examples:

```ini
# Mount a subfolder
ExecStart=/usr/bin/rclone mount gdrive:Mynah/LeadMagnets %h/leadmagnets ...

# Read-only mount
ExecStart=/usr/bin/rclone mount gdrive: %h/gdrive --read-only ...

# Increase cache size
--vfs-cache-max-size 10G
--buffer-size 256M
```

## Troubleshooting

### Mount fails immediately

Check if rclone remote is configured:

```bash
rclone listremotes
rclone lsd gdrive:
```

### Permission denied

Ensure FUSE is available for your user:

```bash
groups | grep -q fuse || sudo usermod -aG fuse $USER
```

Then log out and back in.

### Transport endpoint is not connected

The mount crashed. Force unmount and remount:

```bash
fusermount -uz ~/gdrive
systemctl --user restart rclone-gdrive.service
```

### OAuth token expired

Re-authenticate:

```bash
rclone config reconnect gdrive:
```

### Check rclone logs

```bash
# Add verbose logging to service
ExecStart=/usr/bin/rclone mount gdrive: %h/gdrive -v ...

# View logs
journalctl --user -u rclone-gdrive.service -f
```

## Safety Notes

**Do NOT store on Google Drive mount:**
- SQLite databases (no POSIX locking)
- Git repos with concurrent writes
- Any app requiring file locking

**Best practices:**
- Use for document storage and sharing
- Copy files locally for heavy processing
- Treat as shared source of truth, not local storage

## Recovering Deleted Files

Deleted files go to Google Drive trash and can be recovered for 30 days.

### Via web interface (easiest)

1. Go to https://drive.google.com/drive/trash
2. Select the files to restore
3. Click "Restore" (or right-click → Restore)

Files return to their original location.

### Via rclone

```bash
# List files in trash
rclone ls gdrive: --drive-trashed-only

# Restore is not directly supported by rclone - use web interface
```

### Permanent deletion (use with caution)

```bash
# Empty entire trash (IRREVERSIBLE)
rclone cleanup gdrive:

# Delete without using trash (DANGEROUS - skips trash entirely)
rclone delete gdrive:path --drive-use-trash=false
```

### Google Workspace (business accounts)

Admins can recover files for 25 additional days after trash is emptied via the Admin Console.
