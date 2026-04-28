#!/bin/bash
set -e
cd "$(dirname "$0")"

echo "Kompiliere …"
swiftc -framework Cocoa BadBerlin.swift -o BadBerlin

echo "Erstelle BadBerlin.app …"
APP=BadBerlin.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"

cp BadBerlin "$APP/Contents/MacOS/BadBerlin"

cat > "$APP/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>   <string>BadBerlin</string>
    <key>CFBundleIdentifier</key>   <string>de.badberlin.menubar</string>
    <key>CFBundleName</key>         <string>Bad Berlin</string>
    <key>CFBundleVersion</key>      <string>2.0</string>
    <key>CFBundleIconFile</key>     <string></string>
    <key>LSUIElement</key>          <true/>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key><true/>
    </dict>
</dict>
</plist>
PLIST

echo ""
echo "✓ BadBerlin.app fertig."
echo "  Öffnen:              open BadBerlin.app"
echo "  Autostart hinzufügen: Systemeinstellungen → Allgemein → Anmeldeobjekte → + → BadBerlin.app"
