@echo off
setlocal
echo ============================================================
echo  Pepper Reader - Register as Default PDF Viewer for Windows
echo ============================================================
echo.

set "SCRIPT_DIR=%~dp0"
set "EXE_PATH=%SCRIPT_DIR%ebook_app_desktop.exe"

if not exist "%EXE_PATH%" (
    set "EXE_PATH=%SCRIPT_DIR%build\windows\x64\runner\Release\ebook_app_desktop.exe"
)

if not exist "%EXE_PATH%" (
    echo [ERROR] Could not find ebook_app_desktop.exe in current directory or Release folder!
    echo Looked for: %EXE_PATH%
    pause
    exit /b 1
)

echo Registering: %EXE_PATH%
echo Setting file associations for current user in HKCU...

:: 1. Register ProgID
reg add "HKCU\Software\Classes\PepperReader.PDF" /ve /t REG_SZ /d "PDF Document (Pepper Reader)" /f >nul
reg add "HKCU\Software\Classes\PepperReader.PDF\DefaultIcon" /ve /t REG_SZ /d "\"%EXE_PATH%\",0" /f >nul
reg add "HKCU\Software\Classes\PepperReader.PDF\shell\open\command" /ve /t REG_SZ /d "\"%EXE_PATH%\" \"%%1\"" /f >nul

:: 2. Associate .pdf extension
reg add "HKCU\Software\Classes\.pdf" /ve /t REG_SZ /d "PepperReader.PDF" /f >nul
reg add "HKCU\Software\Classes\.pdf\OpenWithProgids" /v "PepperReader.PDF" /t REG_NONE /f >nul

:: 3. Register under Applications
reg add "HKCU\Software\Classes\Applications\ebook_app_desktop.exe\shell\open\command" /ve /t REG_SZ /d "\"%EXE_PATH%\" \"%%1\"" /f >nul

:: 4. Add to OpenWithList
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\OpenWithProgids" /v "PepperReader.PDF" /t REG_NONE /f >nul

echo.
echo [SUCCESS] Pepper Reader is now registered to open all PDF documents!
echo Double-clicking any .pdf file will now open it directly in Pepper Reader.
echo.
pause
