#!/bin/bash
GD="C:/Users/win10pro/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe"
cd "$(dirname "$0")"
timeout 150 "$GD" --path . --fixed-fps 60 -- --scenario=$1 --shot="$PWD/$2" --frames=${3:-40} $4 2>&1 | grep -i "error\|SHOT\|adult.enter\|SCRIPT" | head -20
