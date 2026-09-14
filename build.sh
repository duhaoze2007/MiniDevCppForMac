#!/bin/bash
# Mini Dev-C++ — build + bundle script (no Xcode required)
set -e
cd "$(dirname "$0")"

APP_NAME="MiniDevCpp"
APP_BUNDLE="Mini Dev-C++.app"

# ── SDK selection ────────────────────────────────────────────────────────────
# From the macOS 26/27 SDK onwards SwiftUI's property wrappers (@State, @Binding,
# @Environment …) are macros whose implementation lives in libSwiftUIMacros.dylib.
# That plugin only ships inside Xcode, so a Command Line Tools-only toolchain
# cannot expand them. When the plugin is missing we build against the newest
# installed SDK whose SwiftUICore declares no macros — the resulting binary still
# runs on the current macOS. Set SDKROOT yourself to override.
if [ -z "$SDKROOT" ]; then
    PLUGIN_DIR="$(xcode-select -p)/usr/lib/swift/host/plugins"
    if [ ! -f "$PLUGIN_DIR/libSwiftUIMacros.dylib" ]; then
        for sdk in $(ls -d /Library/Developer/CommandLineTools/SDKs/MacOSX*.sdk 2>/dev/null \
                     | sed 's#.*/##; s#\.sdk##' | sort -Vr); do
            interface="/Library/Developer/CommandLineTools/SDKs/$sdk.sdk/System/Library/Frameworks/SwiftUICore.framework/Modules/SwiftUICore.swiftmodule/arm64e-apple-macos.swiftinterface"
            [ -f "$interface" ] || continue
            if ! grep -q "macro State" "$interface"; then
                export SDKROOT="/Library/Developer/CommandLineTools/SDKs/$sdk.sdk"
                echo "==> SwiftUI macro plugin missing: building against SDK $sdk"
                break
            fi
        done
    fi
fi

export SDKROOT="${SDKROOT:-$(xcrun --show-sdk-path)}"
echo "==> Using SDK: $SDKROOT"

echo "==> Building (release)…"
swift build -c release

echo "==> Cleaning old bundle…"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"

echo "==> Copying binary…"
cp ".build/release/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

echo "==> Copying Info.plist…"
cp Info.plist "$APP_BUNDLE/Contents/Info.plist"

echo "==> Copying SPM resource bundle (localized menus)…"
RES_BUNDLE=$(find .build -type d -name "${APP_NAME}_${APP_NAME}.bundle" 2>/dev/null | head -1)
if [ -n "$RES_BUNDLE" ]; then
    cp -R "$RES_BUNDLE" "$APP_BUNDLE/Contents/Resources/"
    # localized resources live under Contents/Resources inside the SPM bundle,
    # and SPM lowercases the lproj names — normalize both when copying them into
    # the app bundle, where AppKit looks them up.
    LPROJ_DIR="$RES_BUNDLE/Contents/Resources"
    [ -d "$LPROJ_DIR" ] || LPROJ_DIR="$RES_BUNDLE"
    for lproj in "$LPROJ_DIR"/*.lproj; do
        [ -d "$lproj" ] || continue
        name=$(basename "$lproj")
        case "$name" in
            zh-hans) name="zh-Hans" ;;
            zh-hant) name="zh-Hant" ;;
        esac
        rm -rf "$APP_BUNDLE/Contents/Resources/$name"
        cp -R "$lproj" "$APP_BUNDLE/Contents/Resources/$name"
        echo "    $name/Localizable.strings"
    done
fi

echo "==> Copying icon…"
if [ -f "AppIcon.icns" ]; then
    cp AppIcon.icns "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

echo "==> Signing (ad-hoc)…"
codesign --force --deep --sign - "$APP_BUNDLE" 2>/dev/null || codesign --force --deep --sign - "$APP_BUNDLE"

echo "==> Done: $APP_BUNDLE"
