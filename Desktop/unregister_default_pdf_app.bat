@echo off
setlocal
echo ============================================================
echo  Pepper Reader - Remove Default PDF Viewer Registration
echo ============================================================
echo.

reg delete "HKCU\Software\Classes\PepperReader.PDF" /f >nul 2>&1
reg delete "HKCU\Software\Classes\.pdf\OpenWithProgids" /v "PepperReader.PDF" /f >nul 2>&1
reg delete "HKCU\Software\Classes\Applications\ebook_app_desktop.exe" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\OpenWithProgids" /v "PepperReader.PDF" /f >nul 2>&1

echo [DONE] Removed Pepper Reader PDF association.
echo.
pause
