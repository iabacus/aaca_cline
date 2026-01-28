@echo off
setlocal enabledelayedexpansion

call npm run protos
call npm run protos-go

if not exist dist-standalone\extension mkdir dist-standalone\extension
copy package.json dist-standalone\extension

REM Extract version information
for /f "delims=" %%i in ('node -p "require('./package.json').version"') do set CORE_VERSION=%%i
for /f "delims=" %%i in ('node -p "require('./cli/package.json').version"') do set CLI_VERSION=%%i
for /f "delims=" %%i in ('git rev-parse --short HEAD 2^>nul') do set COMMIT=%%i
if "%COMMIT%"=="" set COMMIT=unknown
for /f "delims=" %%i in ('powershell -Command "Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ' -AsUTC"') do set DATE=%%i
set BUILT_BY=%USERNAME%

set LDFLAGS=-X 'github.com/cline/cli/pkg/cli/global.Version=%CORE_VERSION%' -X 'github.com/cline/cli/pkg/cli/global.CliVersion=%CLI_VERSION%' -X 'github.com/cline/cli/pkg/cli/global.Commit=%COMMIT%' -X 'github.com/cline/cli/pkg/cli/global.Date=%DATE%' -X 'github.com/cline/cli/pkg/cli/global.BuiltBy=%BUILT_BY%'

cd cli

echo Building for Windows...

set GO111MODULE=on
go build -ldflags "%LDFLAGS%" -o bin\cline.exe .\cmd\cline
echo   ✓ bin\cline.exe built

go build -ldflags "%LDFLAGS%" -o bin\cline-host.exe .\cmd\cline-host
echo   ✓ bin\cline-host.exe built

echo.
echo Build complete for Windows!

cd ..
if not exist dist-standalone\bin mkdir dist-standalone\bin
copy cli\bin\cline.exe dist-standalone\bin\cline.exe
copy cli\bin\cline.exe dist-standalone\bin\cline-windows-amd64.exe
copy cli\bin\cline-host.exe dist-standalone\bin\cline-host.exe
copy cli\bin\cline-host.exe dist-standalone\bin\cline-host-windows-amd64.exe
echo Copied binaries to dist-standalone\bin\
