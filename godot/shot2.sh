#!/bin/bash
# usage: shot2.sh scenario out.png frames [HOFF]
GD="C:/Users/win10pro/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe"
cd "$(dirname "$0")"
mkdir -p assets/ui/raw
NOHUD=1 HOFF=${4:-0} CAMD=$CAMD PITCH=$PITCH YAW=$YAW DOFD=$DOFD FOV=$FOV timeout 200 "$GD" --path . --resolution 1920x1080 --fixed-fps 60 -- --scenario=$1 --shot="$PWD/assets/ui/raw/$2" --frames=${3:-60} 2>&1 | grep -i "error\|SHOT\|SCRIPT" | head
