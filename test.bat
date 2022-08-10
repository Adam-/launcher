# modify packr exe manifest to enable Windows dpi scaling
resourcehacker \
    -open native-win64/RuneLite.exe \
    -save native-win64/RuneLite.exe \
    -action addoverwrite \
    -res packr/runelite.manifest \
    -log rh.log \
    -mask MANIFEST,1,

echo rh log manifest start
cat rh.log
rm -f rh.log

# packr on Windows doesn't support icons, so we use resourcehacker to include it

mv native-win64/RuneLite.exe native-win64/RuneLite-orig.exe
resourcehacker \
    -open native-win64/RuneLite-orig.exe \
    -save native-win64/RuneLite.exe \
    -action add \
    -res runelite.ico \
    -log rh.log \
    -mask ICONGROUP,MAINICON,

echo RH LOG START
cat rh.log