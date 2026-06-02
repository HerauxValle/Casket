#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_PY="$SCRIPT_DIR/main.py"
OBI_LINK="/usr/local/bin/obi"
UDEV_RULES_DIR="/etc/udev/rules.d"
UDEV_RULES_FILE="$UDEV_RULES_DIR/99-obi-loop.rules"
UDEV_RULE='SUBSYSTEM=="block", KERNEL=="loop*", ENV{ID_FS_TYPE}=="crypto_LUKS", ENV{UDISKS_IGNORE}="1"'

# ------------------------------------------------------------------ #

require_root() {
    if [ "$EUID" -ne 0 ]; then
        exec sudo bash "$0" "$@"
    fi
}

is_obi_installed() {
    [ -L "$OBI_LINK" ] && [ "$(readlink -f "$OBI_LINK")" = "$(readlink -f "$MAIN_PY")" ]
}

# ------------------------------------------------------------------ #

do_udev() {
    if [ ! -d "$UDEV_RULES_DIR" ]; then
        echo "  [!] $UDEV_RULES_DIR not found — skipping udev rule"
        return
    fi
    if [ -f "$UDEV_RULES_FILE" ] && grep -qF "$UDEV_RULE" "$UDEV_RULES_FILE"; then
        echo "  [i] udev rule already present"
        return
    fi
    # prepend rule so it fires before other rules
    if [ -f "$UDEV_RULES_FILE" ]; then
        tmp=$(mktemp)
        { echo "$UDEV_RULE"; cat "$UDEV_RULES_FILE"; } > "$tmp"
        mv "$tmp" "$UDEV_RULES_FILE"
    else
        echo "$UDEV_RULE" > "$UDEV_RULES_FILE"
    fi
    udevadm control --reload-rules 2>/dev/null
    echo "  [✓] udev rule installed: $UDEV_RULES_FILE"
}

do_udev_remove() {
    if [ ! -f "$UDEV_RULES_FILE" ]; then return; fi
    grep -vF "$UDEV_RULE" "$UDEV_RULES_FILE" > "$UDEV_RULES_FILE.tmp"
    if [ -s "$UDEV_RULES_FILE.tmp" ]; then
        mv "$UDEV_RULES_FILE.tmp" "$UDEV_RULES_FILE"
    else
        rm -f "$UDEV_RULES_FILE" "$UDEV_RULES_FILE.tmp"
    fi
    udevadm control --reload-rules 2>/dev/null
    echo "  [✓] udev rule removed"
}

do_install() {
    if is_obi_installed; then
        echo "already installed — nothing to do"
        return
    fi
    chmod +x "$MAIN_PY"
    if [ -L "$OBI_LINK" ] || [ -f "$OBI_LINK" ]; then
        rm "$OBI_LINK"
        echo "  [i] removed old $OBI_LINK"
    fi
    ln -s "$MAIN_PY" "$OBI_LINK"
    echo "  [✓] linked: $OBI_LINK -> $MAIN_PY"
    do_udev
    echo ""
    echo "installed. usage:"
    echo "  obi <vault> open"
    echo "  obi <vault> close"
    echo "  obi list"
}

do_uninstall() {
    if [ -L "$OBI_LINK" ]; then
        rm "$OBI_LINK"
        echo "  [✓] removed $OBI_LINK"
    else
        echo "nothing to uninstall"
    fi
    do_udev_remove
    echo "uninstalled."
}

# ------------------------------------------------------------------ #

case "${1:-}" in
    --uninstall)
        require_root "$@"
        do_uninstall
        ;;
    --install|"")
        require_root "$@"
        do_install
        ;;
    --reinstall)
        require_root "$@"
        do_uninstall
        echo ""
        do_install
        ;;
    *)
        echo "usage: ./install.sh [--install | --reinstall | --uninstall]"
        exit 1
        ;;
esac