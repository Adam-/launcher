#!/bin/bash

set -e

echo Launcher sha256sum
sha256sum build/libs/RuneLite.jar

pushd native
cmake -DCMAKE_TOOLCHAIN_FILE=arm64-linux-gcc.cmake -B build-aarch64 .
cmake --build build-aarch64 --config Release
popd

umask 022

source util.sh

rm -rf build/linux-aarch64
mkdir -p build/linux-aarch64

# Note: Host umask may have checked out this directory with g/o permissions blank
chmod -R u=rwX,go=rX appimage
# ...ditto for the build process
chmod 644 build/libs/RuneLite.jar

cp native/build-aarch64/src/RuneLite build/linux-aarch64/
cp build/libs/RuneLite.jar build/linux-aarch64/
cp packr/linux-aarch64-config.json build/linux-aarch64/config.json
cp build/filtered-resources/runelite.desktop build/linux-aarch64/
cp appimage/runelite.png build/linux-aarch64/
mkdir -p build/linux-aarch64/usr/share/icons/hicolor/128x128/apps/
cp appimage/runelite.png build/linux-aarch64/usr/share/icons/hicolor/128x128/apps/

download_jre LINUX_AARCH64 linux_aarch64_jre.tar.gz build/linux-aarch64/jre

pushd build/linux-aarch64
# Symlink AppRun -> RuneLite
ln -s RuneLite AppRun

# Ensure RuneLite is executable to all users
chmod 755 RuneLite
popd

curl -z appimagetool-x86_64.AppImage -o appimagetool-x86_64.AppImage -L https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
curl -z runtime-aarch64 -o runtime-aarch64 -L https://github.com/AppImage/type2-runtime/releases/download/continuous/runtime-aarch64

chmod +x appimagetool-x86_64.AppImage

./appimagetool-x86_64.AppImage \
	--runtime-file runtime-aarch64 \
	build/linux-aarch64/ \
	RuneLite-aarch64.AppImage
