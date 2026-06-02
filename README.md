# Casket

Encrypted vault manager for Linux. Each vault is a single `.img` file — a standard LUKS2 container with a btrfs filesystem inside. Open it and it becomes a folder. Close it and everything is encrypted at rest.

## Install

```bash
git clone https://github.com/HerauxValle/Casket.git
cd Casket
./install.sh           # install (symlinks cas to /usr/local/bin + udev rule)
./install.sh --reinstall
./install.sh --uninstall
```

## Usage

```bash
cas myvault create              # create a new vault (prompts for size + passphrase)
cas myvault open                # unlock and mount
cas myvault close               # unmount and lock
cas myvault toggle              # open if closed, close if open
cas list                        # show all vaults nearby
cas all close                   # close every open vault
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
cas myvault passwd              # change passphrase
cas myvault resize 4G           # grow or shrink
cas myvault 2fa on              # enable 2FA (passphrase + keyfile)
cas myvault 2fa off             # disable 2FA
cas myvault encryption off      # auto-unlock without passphrase prompt
cas myvault backup create snap  # btrfs snapshot inside the vault
cas myvault backup list
cas myvault backup restore snap
cas myvault info
cas myvault delete
cas myvault rename newname
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
