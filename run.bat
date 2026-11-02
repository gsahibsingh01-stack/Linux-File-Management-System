@echo off
setlocal
cd /d "%~dp0"

echo ======================================================================
echo          APEX STUDENT RECORD MANAGEMENT SYSTEM (LINUX/BASH)
echo ======================================================================

set BASH_PATH=""

if exist "C:\Program Files\Git\bin\bash.exe" (
    set BASH_PATH="C:\Program Files\Git\bin\bash.exe"
) else if exist "C:\Program Files\Git\usr\bin\bash.exe" (
    set BASH_PATH="C:\Program Files\Git\usr\bin\bash.exe"
) else if exist "C:\msys64\usr\bin\bash.exe" (
    set BASH_PATH="C:\msys64\usr\bin\bash.exe"
) else (
    where bash >nul 2>&1
    if %ERRORLEVEL% EQU 0 (
        set BASH_PATH=bash
    )
)

if %BASH_PATH%=="" (
    echo [ERROR] Git Bash or a Linux bash environment was not detected on this system!
    echo Please install Git for Windows or run inside WSL / Linux.
    pause
    exit /b 1
)

echo Launching Apex Student Record Management System...
%BASH_PATH% ./run.sh
pause
