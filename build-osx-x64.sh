#!/bin/bash

set -e

SIGNING_IDENTITY="Developer ID Application"

source .jdk-versions.sh

rm -rf build/macos-x64
mkdir -p build/macos-x64

if ! [ -f mac64_jre.tar.gz ] ; then
    curl -Lo mac64_jre.tar.gz $MAC_AMD64_LINK
fi

echo "$MAC_AMD64_CHKSUM  mac64_jre.tar.gz" | shasum -c

mkdir -p build/macos-x64/Contents/{MacOS,Resources}

cp native/build-x64/src/RuneLite build/macos-x64/Contents/MacOS/
cp packr/macos-x64-config.json build/macos-x64/Contents/MacOS/
cp target/filtered-resources/Info.plist build/macos-x64/Contents/
cp packr/runelite.icns build/macos-x64/Contents/Resources/

tar zxf mac64_jre.tar.gz
mkdir build/macos-x64/jre/
mv jdk-$MAC_AMD64_VERSION-jre/Contents/Home/* build/macos-x64/jre/

echo Setting world execute permissions on RuneLite
pushd build/macos-x64
chmod g+x,o+x Contents/MacOS/RuneLite
popd

codesign -f -s "${SIGNING_IDENTITY}" --entitlements osx/signing.entitlements --options runtime build/macos-x64 || true

# create-dmg exits with an error code due to no code signing, but is still okay
# note we use Adam-/create-dmg as upstream does not support UDBZ
create-dmg --format UDBZ build/macos-x64 build/macos-x64 || true

mv build/macos-x64/RuneLite\ *.dmg RuneLite-x64.dmg

if ! hdiutil imageinfo RuneLite-x64.dmg | grep -q "Format: UDBZ" ; then
    echo "Format of resulting dmg was not UDBZ, make sure your create-dmg has support for --format"
    exit 1
fi

# Notarize app
if xcrun notarytool submit RuneLite-x64.dmg --wait --keychain-profile "AC_PASSWORD" ; then
    xcrun stapler staple RuneLite-x64.dmg
fi
