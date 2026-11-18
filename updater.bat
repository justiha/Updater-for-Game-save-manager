@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

title Game Save Manager - Updater
color 0B

echo =================================================================
echo                    GAME SAVE MANAGER UPDATER
echo =================================================================
echo.

:: Strip outer quotes safely and default if empty
set "TARGET_SCRIPT=%~1"
if "%TARGET_SCRIPT%"=="" set "TARGET_SCRIPT=Game save manager.bat"

echo [*] Target script: %TARGET_SCRIPT%
echo [*] Fetching latest version from GitHub...

:: Define RAW GitHub URL
set "RAW_URL=https://raw.githubusercontent.com/justiha/Game-Backup-manager/main/Game%%20save%%20manager.bat"
set "TEMP_FILE=update_temp.bat"

:: Download latest version using PowerShell
powershell -Command "Invoke-WebRequest -Uri '%RAW_URL%' -OutFile '%TEMP_FILE%'"

if not exist "%TEMP_FILE%" (
    echo.
    echo [!] ERROR: Failed to download update from GitHub.
    echo Check your internet connection or repository URL.
    goto UPDATE_FAILED
)

:: =================================================================
:: VERSION EXTRACTION & COMPARISON LOGIC
:: =================================================================
set "LOCAL_VER=Unknown"
set "REMOTE_VER=Unknown"

:: Extract local version (reads first line or version tag from current script if available)
if exist "%TARGET_SCRIPT%" (
    for /f "tokens=1,* delims=:" %%a in ('findstr /i "version" "%TARGET_SCRIPT%"') do (
        set "LOCAL_VER=%%a %%b"
        goto GOT_LOCAL
    )
)
:GOT_LOCAL

:: Extract remote version from downloaded temp script
for /f "tokens=1,* delims=:" %%a in ('findstr /i "version" "%TEMP_FILE%"') do (
    set "REMOTE_VER=%%a %%b"
    goto GOT_REMOTE
)
:GOT_REMOTE

echo.
echo -----------------------------------------------------------------
call :COLOR_TEXT "   Installed Version : %LOCAL_VER%" "Green"
call :COLOR_TEXT "   Latest GitHub Ver : %REMOTE_VER%" "Green"
echo -----------------------------------------------------------------

:: =================================================================
:: CHANGELOG EXTRACTION & DISPLAY (Colored Blue via Echo/Color Mix)
:: =================================================================
echo.
call :COLOR_TEXT "   [Whats New in Latest Release]:" "Blue"
call :COLOR_TEXT "   ---------------------------------------------------------------" "Blue"
set "HAS_CHANGELOG="
for /f "tokens=1,* delims=:" %%a in ('findstr /i "CHANGELOG" "%TEMP_FILE%"') do (
    set "LOG_LINE=%%b"
    set "LOG_LINE=!LOG_LINE:~1!"
    call :COLOR_TEXT "     - !LOG_LINE!" "Blue"
    set "HAS_CHANGELOG=YES"
)

if not defined HAS_CHANGELOG (
    call :COLOR_TEXT "     (No changelog notes provided for this version)" "Blue"
)
call :COLOR_TEXT "   ---------------------------------------------------------------" "Blue"
echo.

if "%LOCAL_VER%"=="%REMOTE_VER%" (
    call :COLOR_TEXT "You are already running the latest version! No update needed." "Green"
) else (
    call :COLOR_TEXT "New version available!" "Yellow"
)

:ASK_FORCE_UPDATE
echo.
echo Choose an option:
echo   [1] Update now (Replace existing file)
echo   [2] Add as new .bat file (Keep original)
echo   [3] Cancel / Close updater
echo.
set "choice="
set /p "choice=Select option (1-3): "

if "%choice%"=="1" goto DO_REPLACE
if "%choice%"=="2" goto DO_NEW_FILE
if "%choice%"=="3" goto UPDATE_CANCEL
if /i "%choice%"=="C" goto UPDATE_CANCEL

goto UPDATE_CANCEL

:DO_REPLACE
echo.
echo [*] Applying update by replacing "%TARGET_SCRIPT%"...
timeout /t 1 /nobreak >nul
move /y "%TEMP_FILE%" "%TARGET_SCRIPT%" >nul

if errorlevel 1 (
    echo [!] ERROR: Could not overwrite target file. Make sure it is closed.
    goto UPDATE_FAILED
)

echo.
echo =================================================================
echo [SUCCESS] Update applied successfully! Restarting manager...
echo =================================================================
timeout /t 2 /nobreak >nul
start "" "%TARGET_SCRIPT%"
exit

:DO_NEW_FILE
echo.
set "NEW_NAME=Game save manager_updated.bat"
echo [*] Creating new file: %NEW_NAME%
move /y "%TEMP_FILE%" "%NEW_NAME%" >nul
echo [SUCCESS] New file created in folder!
echo.
pause
exit

:UPDATE_CANCEL
echo.
echo [-] Update cancelled by user. Cleaning up...
if exist "%TEMP_FILE%" del "%TEMP_FILE%"
echo Exiting...
timeout /t 1 /nobreak >nul
exit

:UPDATE_FAILED
echo.
if exist "%TEMP_FILE%" del "%TEMP_FILE%"
echo Press any key to exit updater...
pause >nul
exit

:: =================================================================
:: COLOR HELPER SUBROUTINE
:: =================================================================
:COLOR_TEXT
powershell -Command "Write-Host '%~1' -ForegroundColor %~2"
goto :eof