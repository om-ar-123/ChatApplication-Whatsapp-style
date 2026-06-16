@echo off
REM Creates submission zip: pubspec.yaml + lib/ only
cd /d "%~dp0.."
set OUT=OMAR_Chat_SourceCode.zip
if exist "%OUT%" del "%OUT%"

powershell -NoProfile -Command ^
  "$root = Get-Location; $tmp = Join-Path $env:TEMP ('omar_src_' + [guid]::NewGuid().ToString()); New-Item -ItemType Directory -Path $tmp | Out-Null; Copy-Item (Join-Path $root 'pubspec.yaml') $tmp; Copy-Item (Join-Path $root 'lib') (Join-Path $tmp 'lib') -Recurse; Compress-Archive -Path (Join-Path $tmp '*') -DestinationPath (Join-Path $root '%OUT%') -Force; Remove-Item $tmp -Recurse -Force; Write-Host 'Created' (Join-Path $root '%OUT%')"

echo Contents: pubspec.yaml and lib/ folder only.
