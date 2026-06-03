@echo off
setlocal
cd /d "%~dp0..\.."
dotnet build "Custom Software\CalendarDB\CalendarDB.csproj"
if errorlevel 1 (
    pause
    exit /b 1
)
start "" "Custom Software\CalendarDB\bin\Debug\net9.0-windows\CalendarDB.exe"
