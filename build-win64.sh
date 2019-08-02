#!/bin/bash

set -e

JDK_VER="11.0.4"
JDK_BUILD="11"

if ! [ -f OpenJDK11U-jre_x64_windows_hotspot_${JDK_VER}_${JDK_BUILD}.zip ] ; then
    curl -Lo OpenJDK11U-jre_x64_windows_hotspot_${JDK_VER}_${JDK_BUILD}.zip \
        https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-${JDK_VER}%2B${JDK_BUILD}/OpenJDK11U-jre_x64_windows_hotspot_${JDK_BUILD}_${JDK_BUILD}.zip
fi

echo "be88c679fd24194bee71237f92f7a2a71c88f71a853a56a7c05742b0e158c1be OpenJDK11U-jre_x64_windows_hotspot_${JDK_VER}_${JDK_BUILD}.zip" | sha256sum -c

# packr requires a "jdk" and pulls the jre from it - so we have to place it inside
# the jdk folder at jre/
if ! [ -d win64-jdk ] ; then
    unzip OpenJDK11U-jre_x64_windows_hotspot_${JDK_VER}_${JDK_BUILD}.zip
    mkdir win64-jdk
    mv jdk-11.0.4+11-jre win64-jdk/jre
fi

if ! [ -f packr.jar ] ; then
    curl -Lo packr.jar https://libgdx.badlogicgames.com/ci/packr/packr.jar
fi

echo "5825a18196a813158e247351e0b43a10c521bf227c931f41e536e61b085f2b80 packr.jar" | sha256sum -c

java -jar packr.jar \
    --platform \
    windows64 \
    --jdk \
    win64-jdk \
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
    native-win64

# packr on Windows doesn't support icons, so we use resourcehacker to include it

resourcehacker \
    -open native-win64/RuneLite.exe \
    -save native-win64/RuneLite.exe \
    -action add \
    -res runelite.ico \
    -mask ICONGROUP,MAINICON,

# XXX here we update the manifest for DPI scaling - is that required still?

# We use the filtered iss file
iscc target/filtered-resources/runelite.iss