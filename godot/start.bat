@echo off
set "GODOT=%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe"
if not exist "%GODOT%" set "GODOT=godot"
if not exist "%~dp0.godot" (
  echo Importing assets for the first time, please wait...
  "%GODOT%" --headless --path "%~dp0." --import
)
start "" "%GODOT%" --path "%~dp0."
