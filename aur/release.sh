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

# fetch tarball hash from GitHub (retry until non-empty tarball is available)
REPO=$(grep '^url=' "$PKGBUILD" | cut -d'=' -f2)
TARBALL_URL="${REPO}/archive/v${VERSION}.tar.gz"
EMPTY_HASH="e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
SHA=""

echo "  [i] fetching sha256 for v${VERSION} ..."
for i in {1..10}; do
    SHA=$(curl -sL "$TARBALL_URL" | sha256sum | awk '{print $1}')
    if [ -n "$SHA" ] && [ "$SHA" != "$EMPTY_HASH" ]; then
        break
    fi
    echo "  [i] tarball not ready yet, retrying in 3s ($i/10)..."
    sleep 3
done

if [ -z "$SHA" ] || [ "$SHA" = "$EMPTY_HASH" ]; then
    echo "  [x] failed to fetch tarball after retries"
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
