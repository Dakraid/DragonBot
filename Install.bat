@echo off
REM Installer for SkybotV2

REM Install Luvit
PowerShell -NoProfile -ExecutionPolicy unrestricted -Command "iex ((new-object net.webclient).DownloadString('https://github.com/luvit/lit/raw/master/get-lit.ps1'))"

REM Generate default config
xcopy ".\config.lua.default" ".\config.lua"
xcopy ".\blacklist.lua.default" ".\blacklist.lua"
xcopy ".\userlist.lua.default" ".\userlist.lua"
xcopy ".\factconfig.lua.default" ".\factconfig.lua"