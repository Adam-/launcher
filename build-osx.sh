#!/bin/bash

set -e

JDK_VER="11.0.4"
JDK_BUILD="11"

if ! [ -f OpenJDK11U-jre_x64_mac_hotspot_${JDK_VER}_${JDK_BUILD}.tar.gz ] ; then
    curl -Lo OpenJDK11U-jre_x64_mac_hotspot_${JDK_VER}_${JDK_BUILD}.tar.gz \
        https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-${JDK_VER}%2B${JDK_BUILD}/OpenJDK11U-jre_x64_mac_hotspot_${JDK_VER}_${JDK_BUILD}.tar.gz
fi

echo "1647fded28d25e562811f7bce2092eb9c21d30608843b04250c023b40604ff26 OpenJDK11U-jre_x64_mac_hotspot_${JDK_VER}_${JDK_BUILD}.tar.gz" | sha256sum -c

# packr requires a "jdk" and pulls the jre from it - so we have to place it inside
# the jdk folder at jre/
if ! [ -d osx-jdk ] ; then
    tar zxf OpenJDK11U-jre_x64_mac_hotspot_${JDK_VER}_${JDK_BUILD}.tar.gz
    mkdir osx-jdk
    mv jdk-11.0.4+11-jre osx-jdk/jre
fi

# Move JRE out of Contents/Home/
pushd osx-jdk/jre
cp -r Contents/Home/* .
popd

if ! [ -f packr.jar ] ; then
    curl -Lo packr.jar https://libgdx.badlogicgames.com/ci/packr/packr.jar
fi

echo "5825a18196a813158e247351e0b43a10c521bf227c931f41e536e61b085f2b80 packr.jar" | sha256sum -c

java -jar packr.jar \
    --platform \
    mac \
    --icon \
    packr/runelite.icns \
    --jdk \
    osx-jdk \
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
    native-osx/RuneLite.app

cp target/filtered-resources/Info.plist native-osx/RuneLite.app/Contents

echo Setting world execute permissions on RuneLite
pushd native-osx/RuneLite.app
chmod g+x,o+x Contents/MacOS/RuneLite
popd

# createdmg exits with an error code on success
# note we use Adam-/create-dmg as upstream does not support UDBZ
createdmg --format UDBZ native-osx/RuneLite.app || true
