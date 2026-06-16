@echo off
cd /d "%~dp0.."
if not exist "report_assets\screenshots" mkdir "report_assets\screenshots"

echo Capturing screenshots via Flutter golden tests...
flutter test test/report_screenshots_test.dart --update-goldens --reporter expanded
if errorlevel 1 exit /b 1

cd scripts
call npm install >nul 2>&1
node generate_report.js
node export_pdf.js

echo.
echo Report files created:
echo   ..\CEN306_OMAR_Chat_Project_Report.docx
echo   ..\CEN306_OMAR_Chat_Project_Report.pdf
