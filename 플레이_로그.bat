@echo off
rem If the game closes by itself, run this one - it keeps the console open and saves play_log.txt
"C:\Users\User\Downloads\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64.exe" --path "%~dp0." > "%~dp0play_log.txt" 2>&1
echo.
echo Game exited. Log saved to play_log.txt
pause
