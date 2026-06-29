@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..\..") do set "WORKSPACE_ROOT=%%~fI"
if "%REPO_LIST_FILE%"=="" set "REPO_LIST_FILE=%SCRIPT_DIR%repos-v3.txt"
if "%GITHUB_ORG%"=="" set "GITHUB_ORG=Norconex"
if "%GIT_REMOTE_BASE%"=="" set "GIT_REMOTE_BASE=https://github.com/%GITHUB_ORG%"
if "%GIT_EXE%"=="" set "GIT_EXE=git"

if /i "%GIT_EXE%"=="git" (
  where git >nul 2>nul
  if errorlevel 1 (
    echo ERROR: git is required but was not found in PATH.
    echo Hint: set GIT_EXE to full path, e.g. C:\Program Files\Git\cmd\git.exe
    exit /b 1
  )
) else (
  if not exist "%GIT_EXE%" (
    echo ERROR: configured GIT_EXE not found: %GIT_EXE%
    exit /b 1
  )
)

if not exist "%REPO_LIST_FILE%" (
  echo ERROR: repo list file not found: %REPO_LIST_FILE%
  exit /b 1
)

echo Workspace root: %WORKSPACE_ROOT%
echo Repo list: %REPO_LIST_FILE%

for /f "usebackq tokens=* delims=" %%L in ("%REPO_LIST_FILE%") do (
  set "line=%%L"
  for /f "tokens=* delims= " %%A in ("!line!") do set "line=%%A"
  if not "!line!"=="" if not "!line:~0,1!"=="#" (
    set "repo=!line!"
    set "TARGET_DIR=%WORKSPACE_ROOT%\!repo!"
    set "REMOTE_URL=%GIT_REMOTE_BASE%/!repo!.git"

    if exist "!TARGET_DIR!\.git" (
      echo [sync] !repo!
      "%GIT_EXE%" -C "!TARGET_DIR!" fetch --all --prune
    ) else (
      if exist "!TARGET_DIR!" (
        echo [skip] !repo!: path exists but is not a git repo ^(!TARGET_DIR!^)
      ) else (
        echo [clone] !repo!
        "%GIT_EXE%" clone "!REMOTE_URL!" "!TARGET_DIR!"
      )
    )
  )
)

echo Done.
exit /b 0
