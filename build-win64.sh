#!/bin/bash

set -e

echo Launcher sha256sum
sha256sum build/libs/RuneLite.jar

cmake -S liblauncher -B liblauncher/build64 -A x64
cmake --build liblauncher/build64 --config Release

pushd native
cmake -B build-x64 -A x64
cmake --build build-x64 --config Release
popd

source util.sh

rm -rf build/win-x64
mkdir -p build/win-x64

cp native/build-x64/src/Release/RuneLite.exe build/win-x64/
cp build/libs/RuneLite.jar build/win-x64/
cp packr/win-x64-config.json build/win-x64/config.json
cp liblauncher/build64/Release/launcher_amd64.dll build/win-x64/

download_jre WIN64 win64_jre.zip build/win-x64/jre

echo RuneLite.exe 64bit sha256sum
sha256sum build/win-x64/RuneLite.exe

dumpbin //HEADERS build/win-x64/RuneLite.exe

# We use the filtered iss file
iscc build/filtered-resources/runelite.iss
