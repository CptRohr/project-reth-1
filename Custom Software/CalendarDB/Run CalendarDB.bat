@echo off
setlocal
cd /d "%~dp0..\.."
:: Call the executable directly using its full path
"C:\Program Files\dotnet\dotnet.exe" build "Custom Software\CalendarDB\CalendarDB.csproj"
if errorlevel 1 (
    pause
    exit /b 1
)
start "" "Custom Software\CalendarDB\bin\Debug\net9.0-windows\CalendarDB.exe"
