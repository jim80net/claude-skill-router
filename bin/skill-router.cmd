@echo off
setlocal

set "DIR=%~dp0"
set "ROOT=%DIR%.."

rem 1. Prebuilt binary (DLLs auto-resolve from same directory on Windows)
if exist "%DIR%skill-router.exe" (
  "%DIR%skill-router.exe" %*
  exit /b %ERRORLEVEL%
)

rem 2. Binary missing — synchronous download via PowerShell
echo skill-router: binary not found, downloading... 1>&2
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference = 'Stop';" ^
  "$repo = 'jim80net/claude-skill-router';" ^
  "$asset = 'skill-router-win32-x64.zip';" ^
  "$baseUrl = 'https://github.com/' + $repo + '/releases/latest/download';" ^
  "$url = $baseUrl + '/' + $asset;" ^
  "$checksumUrl = $baseUrl + '/checksums.txt';" ^
  "$tmp = Join-Path $env:TEMP ('skill-router-' + [guid]::NewGuid().ToString('N') + '.zip');" ^
  "$extractDir = Join-Path $env:TEMP ('skill-router-extract-' + [guid]::NewGuid().ToString('N'));" ^
  "try {" ^
  "  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;" ^
  "  Invoke-WebRequest -Uri $url -OutFile $tmp -UseBasicParsing -TimeoutSec 12;" ^
  "  try {" ^
  "    $checksumFile = Join-Path $env:TEMP 'skill-router-checksums.txt';" ^
  "    Invoke-WebRequest -Uri $checksumUrl -OutFile $checksumFile -UseBasicParsing -TimeoutSec 5;" ^
  "    $expected = (Get-Content $checksumFile | Where-Object { $_ -match $asset }) -replace '  .*','';" ^
  "    $actual = (Get-FileHash $tmp -Algorithm SHA256).Hash.ToLower();" ^
  "    Remove-Item -Force $checksumFile -ErrorAction SilentlyContinue;" ^
  "    if ($expected -and $actual -ne $expected) {" ^
  "      Write-Error \"Checksum mismatch! Expected $expected, got $actual\";" ^
  "      exit 1;" ^
  "    }" ^
  "    if ($expected) { Write-Host 'Checksum verified.' -ForegroundColor Green }" ^
  "  } catch { Write-Host 'Warning: checksums.txt not available, skipping verification' }" ^
  "  if (Test-Path $extractDir) { Remove-Item -Recurse -Force $extractDir };" ^
  "  Expand-Archive -Path $tmp -DestinationPath $extractDir -Force;" ^
  "  $bin = Join-Path $extractDir 'skill-router.exe';" ^
  "  if (Test-Path $bin) { Move-Item -Force $bin '%DIR%skill-router.exe' };" ^
  "  Get-ChildItem $extractDir -Filter '*.dll' | ForEach-Object { Move-Item -Force $_.FullName '%DIR%' };" ^
  "  Write-Host 'skill-router: installed successfully' -ForegroundColor Green;" ^
  "} catch {" ^
  "  Write-Host \"skill-router: download failed: $_\" -ForegroundColor Red;" ^
  "} finally {" ^
  "  Remove-Item -Force $tmp -ErrorAction SilentlyContinue;" ^
  "  Remove-Item -Recurse -Force $extractDir -ErrorAction SilentlyContinue;" ^
  "}"

rem Re-check after download
if exist "%DIR%skill-router.exe" (
  "%DIR%skill-router.exe" %*
  exit /b %ERRORLEVEL%
)

rem 3. Install failed — clear error with install URL
echo {}
echo skill-router: binary not found. Download from https://github.com/jim80net/claude-skill-router/releases 1>&2
