# ObiLock

Encrypted vault manager for Linux. Each vault is a single `.img` file — a standard LUKS2 container with a btrfs filesystem inside. Open it and it becomes a folder. Close it and everything is encrypted at rest.

## Install

```bash
git clone https://github.com/HerauxValle/ObiLock.git
cd ObiLock
./install.sh           # install (symlinks obi to /usr/local/bin + udev rule)
./install.sh --reinstall
./install.sh --uninstall
```

## Usage

```bash
obi myvault create              # create a new vault (prompts for size + passphrase)
obi myvault open                # unlock and mount
obi myvault close               # unmount and lock
obi myvault toggle              # open if closed, close if open
obi list                        # show all vaults nearby
obi all close                   # close every open vault
```

### Options

```
--size 2G          vault size (create)
--strength hard    KDF strength: light / medium / hard / extreme
--pass "..."       passphrase (prompted if omitted; leave empty to generate one)
--keyfile path     keyfile for 2FA vaults
--path dir         look for vaults here instead of auto-searching
--no-log           suppress all output
--no-confirm       skip confirmation prompts (delete, shrink, restore)
```

### Other commands

```bash
obi myvault passwd              # change passphrase
obi myvault resize 4G           # grow or shrink
obi myvault 2fa on              # enable 2FA (passphrase + keyfile)
obi myvault 2fa off             # disable 2FA
obi myvault encryption off      # auto-unlock without passphrase prompt
obi myvault backup create snap  # btrfs snapshot inside the vault
obi myvault backup list
obi myvault backup restore snap
obi myvault info
obi myvault delete
obi myvault rename newname
```

## How it works

- **Encryption**: LUKS2 via `cryptsetup`, argon2id KDF
- **Filesystem**: btrfs (supports snapshots, online resize)
- **2FA**: LUKS passphrase becomes `SHA256(passphrase + keyfile_bytes)`
- **Metadata**: small JSON blob appended after the LUKS container (ignored by cryptsetup)
- **Dolphin/udisks**: btrfs label set on open so the vault appears in file managers

Vaults are fully recoverable without this script using standard `cryptsetup` + `losetup` + `mount`.

## Requirements

`cryptsetup`, `btrfs-progs`, `udisks2`, `udevadm`

## License

MIT
