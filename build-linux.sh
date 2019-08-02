#!/bin/bash

set -e

JDK_VER="11.0.4"
JDK_BUILD="11"

# https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.4%2B11/OpenJDK11U-jre_x64_linux_hotspot_11.0.4_11.tar.gz
if ! [ -f OpenJDK11U-jre_x64_linux_hotspot_${JDK_VER}_${JDK_BUILD}.tar.gz ] ; then
    curl -Lo OpenJDK11U-jre_x64_linux_hotspot_${JDK_VER}_${JDK_BUILD}.tar.gz \
        https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-${JDK_VER}%2B${JDK_BUILD}/OpenJDK11U-jre_x64_linux_hotspot_${JDK_VER}_${JDK_BUILD}.tar.gz
fi

echo "70d2cc675155476f1d8516a7ae6729d44681e4fad5a6fc8dfa65cab36a67b7e0 OpenJDK11U-jre_x64_linux_hotspot_${JDK_VER}_${JDK_BUILD}.tar.gz" | sha256sum -c

# packr requires a "jdk" and pulls the jre from it - so we have to place it inside
# the jdk folder at jre/
if ! [ -d linux-jdk ] ; then
    tar zxf OpenJDK11U-jre_x64_linux_hotspot_${JDK_VER}_${JDK_BUILD}.tar.gz
    mkdir linux-jdk
    mv jdk-11.0.4+11-jre linux-jdk/jre
fi

if ! [ -f packr.jar ] ; then
    curl -Lo packr.jar https://libgdx.badlogicgames.com/ci/packr/packr.jar
fi

echo "5825a18196a813158e247351e0b43a10c521bf227c931f41e536e61b085f2b80 packr.jar" | sha256sum -c

java -jar packr.jar \
    --platform \
    linux64 \
    --jdk \
    linux-jdk \
    --executable \
    RuneLite \
    --classpath \
    target/RuneLite.jar \
    --mainclass \
    net.runelite.launcher.Launcher \
    --vmargs \
    Drunelite.launcher.nojvm=true \
    Xmx512m \
    Xss2m \
    XX:CompileThreshold=1500 \
    Djna.nosys=true \
    --output \
    native-linux/RuneLite.AppDir/ \
    --resources \
    target/filtered-resources/runelite.desktop \
    appimage/runelite.png

pushd native-linux/RuneLite.AppDir
mkdir -p jre/lib/amd64/server/
ln -s ../../server/libjvm.so jre/lib/amd64/server/ # packr looks for libjvm at this hardcoded path
popd

# Symlink AppRun -> RuneLite
pushd native-linux/RuneLite.AppDir/
ln -s RuneLite AppRun
popd

./appimagetool-x86_64.AppImage \
	native-linux/RuneLite.AppDir/ \
	native-linux/RuneLite.AppImage
