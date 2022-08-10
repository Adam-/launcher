dir

dir native-win64

rem modify packr exe manifest to enable Windows dpi scaling
resourcehacker ^
    -open native-win64/RuneLite.exe ^
    -save native-win64/RuneLite.exe ^
    -action addoverwrite ^
    -res packr/runelite.manifest ^
    -log CONSOLE ^
    -mask MANIFEST,1,

rem packr on Windows doesn't support icons, so we use resourcehacker to include it
move native-win64/RuneLite.exe native-win64/RuneLite-orig.exe
resourcehacker ^
    -open native-win64/RuneLite-orig.exe ^
    -save native-win64/RuneLite.exe ^
    -action add ^
    -res runelite.ico ^
    -log CONSOLE ^
    -mask ICONGROUP,MAINICON,
