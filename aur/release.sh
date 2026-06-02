#!/bin/bash
set -e

AUR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CASKET_DIR="$(dirname "$AUR_DIR")"
PKGBUILD="$AUR_DIR/PKGBUILD"
GPA_SCRIPT="$(find "$HOME" -maxdepth 4 -name "gitpushall.py" 2>/dev/null | head -1)"

read -rp "version (e.g. 1.0.4): " VERSION
VERSION="${VERSION#v}"  # strip leading v if typed

if [ -z "$VERSION" ]; then
    echo "[x] version required"
    exit 1
fi

# push to GitHub with changelog editor
python3 "$GPA_SCRIPT" "casket:v${VERSION}:changelog"

# fetch tarball hash from GitHub
REPO=$(grep '^url=' "$PKGBUILD" | cut -d'=' -f2)
echo "  [i] fetching sha256 for v${VERSION} ..."
SHA=$(curl -sL "${REPO}/archive/v${VERSION}.tar.gz" | sha256sum | awk '{print $1}')

if [ -z "$SHA" ]; then
    echo "  [x] failed to fetch tarball"
    exit 1
fi

echo "  [i] sha256: $SHA"

# update PKGBUILD
sed -i "s/^pkgver=.*/pkgver=${VERSION}/" "$PKGBUILD"
sed -i "s/^sha256sums=.*/sha256sums=('${SHA}')/" "$PKGBUILD"

# push to AUR
cd "$AUR_DIR"
makepkg --printsrcinfo > .SRCINFO
git add PKGBUILD .SRCINFO
git commit -m "update to v${VERSION}"
git push origin master

echo "  [✓] released v${VERSION} to GitHub + AUR"
