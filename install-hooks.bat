@echo off
setlocal

set "REPO=%~dp0"
set "REPO=%REPO:~0,-1%"

git -C "%REPO%" rev-parse --git-dir >nul 2>&1
if errorlevel 1 (
    echo Error: Not a git repository. Please run git init first.
    pause & exit /b 1
)

set "PS=%TEMP%\install-hooks-%RANDOM%.ps1"

echo Set-Location '%REPO%'                                                   > "%PS%"
echo $d = '.githooks'                                                        >> "%PS%"
echo New-Item -ItemType Directory -Force -Path $d ^| Out-Null               >> "%PS%"
echo $n = [char]10                                                           >> "%PS%"
echo $pc = @(                                                                >> "%PS%"
echo   '#!/bin/sh', '',                                                      >> "%PS%"
echo   'VERSION_FILE="version.txt"', '',                                     >> "%PS%"
echo   'version=$(cat $VERSION_FILE)', '',                                   >> "%PS%"
echo   'major=$(echo "$version" ^| cut -d. -f1)',                            >> "%PS%"
echo   'minor=$(echo "$version" ^| cut -d. -f2)',                            >> "%PS%"
echo   'patch=$(echo "$version" ^| cut -d. -f3)', '',                        >> "%PS%"
echo   'patch=$((patch+1))', '',                                             >> "%PS%"
echo   'new_version="$major.$minor.$patch"', '',                             >> "%PS%"
echo   'echo $new_version ^> $VERSION_FILE', '',                             >> "%PS%"
echo   'git add $VERSION_FILE', '',                                          >> "%PS%"
echo   'echo "Version updated to $new_version"', '',                         >> "%PS%"
echo   'exit 0', ''                                                          >> "%PS%"
echo )                                                                       >> "%PS%"
echo [IO.File]::WriteAllText("$d/pre-commit",($pc -join $n),(New-Object Text.UTF8Encoding $false)) >> "%PS%"
echo $pm = @(                                                                >> "%PS%"
echo   '#!/bin/sh', '',                                                      >> "%PS%"
echo   'MSG_FILE=$1',                                                        >> "%PS%"
echo   'COMMIT_SOURCE=$2',                                                   >> "%PS%"
echo   'if [ "$COMMIT_SOURCE" = "merge" ] ^|^| [ "$COMMIT_SOURCE" = "commit" ]; then', >> "%PS%"
echo   '  exit 0', 'fi', '',                                                 >> "%PS%"
echo   'VERSION=$(cat version.txt)', '',                                     >> "%PS%"
echo   'sed -i.bak "1s/^^/[v$VERSION] /" "$MSG_FILE"',                      >> "%PS%"
echo   'rm "$MSG_FILE.bak"', ''                                              >> "%PS%"
echo )                                                                       >> "%PS%"
echo [IO.File]::WriteAllText("$d/prepare-commit-msg",($pm -join $n),(New-Object Text.UTF8Encoding $false)) >> "%PS%"
echo if (-not (Test-Path 'version.txt')) {                                   >> "%PS%"
echo   [IO.File]::WriteAllText('version.txt','1.0.0',(New-Object Text.UTF8Encoding $false)) >> "%PS%"
echo }                                                                       >> "%PS%"
echo git config core.hooksPath .githooks                                     >> "%PS%"
echo $gb = (Get-Command git).Source -replace 'git\.exe$','bash.exe'         >> "%PS%"
echo if (-not (Test-Path $gb)) { $gb = $gb -replace '\\cmd\\','\\bin\\' }   >> "%PS%"
echo ^& $gb -c "chmod +x .githooks/pre-commit .githooks/prepare-commit-msg" >> "%PS%"
echo Write-Host 'Git hooks installed!' -ForegroundColor Green                >> "%PS%"

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS%"
set ERR=%ERRORLEVEL%
del "%PS%" 2>nul

if %ERR% neq 0 (
    echo Setup failed. Make sure Git for Windows is installed.
    pause & exit /b 1
)

echo.
echo Done! Every commit will now auto-increment the version.
pause
