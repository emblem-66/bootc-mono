#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="$HOME/.local/share/appimages"
DESKTOP_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons"

mkdir -p "$INSTALL_DIR" "$DESKTOP_DIR" "$ICON_DIR"

# Get latest release info
LATEST=$(curl -fsSL "https://api.github.com/repos/imputnet/helium-linux/releases/latest")
VERSION=$(echo "$LATEST" | jq -r '.tag_name')
URL=$(echo "$LATEST" | jq -r '.assets[] | select(.name | endswith("x86_64.AppImage")) | .browser_download_url' | grep -v zsync)
FILENAME="helium-${VERSION}-x86_64.AppImage"
APPIMAGE_PATH="$INSTALL_DIR/$FILENAME"
CURRENT_LINK="$INSTALL_DIR/helium.AppImage"

# Check if already on latest
if [[ -L "$CURRENT_LINK" ]] && [[ "$(readlink "$CURRENT_LINK")" == "$APPIMAGE_PATH" ]]; then
    echo "Already on latest: $VERSION"
    exit 0
fi

echo "Downloading Helium $VERSION..."
curl -fsSL "$URL" -o "$APPIMAGE_PATH"
chmod +x "$APPIMAGE_PATH"

# Remove old versions
find "$INSTALL_DIR" -name "helium-*.AppImage" ! -name "$FILENAME" -delete

# Symlink current
ln -sf "$APPIMAGE_PATH" "$CURRENT_LINK"

# Extract icon
"$CURRENT_LINK" --appimage-extract usr/share/icons 2>/dev/null || true
if [[ -f squashfs-root/usr/share/icons/hicolor/256x256/apps/helium.png ]]; then
    cp squashfs-root/usr/share/icons/hicolor/256x256/apps/helium.png "$ICON_DIR/helium.png"
fi
rm -rf squashfs-root

# Desktop entry
cat > "$DESKTOP_DIR/helium.desktop" << EOF
[Desktop Entry]
Name=Helium
Comment=Helium Browser
Exec=$CURRENT_LINK %U
Icon=$ICON_DIR/helium.png
Type=Application
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;
StartupNotify=true
StartupWMClass=Helium
EOF

update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true

echo "Helium $VERSION installed"
