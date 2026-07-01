@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..\..") do set "WORKSPACE_ROOT=%%~fI"
if "%REPO_LIST_FILE%"=="" set "REPO_LIST_FILE=%SCRIPT_DIR%repos-v3.txt"
if "%GIT_EXE%"=="" set "GIT_EXE=git"
set "COMMIT_MESSAGE="
set "AUTO_YES=0"

:parse_args
if "%~1"=="" goto args_done
if /I "%~1"=="--message" (
  if "%~2"=="" (
    echo ERROR: --message requires a value
    goto usage
  )
  set "COMMIT_MESSAGE=%~2"
  shift
  shift
  goto parse_args
)
if /I "%~1"=="--repos-file" (
  if "%~2"=="" (
    echo ERROR: --repos-file requires a value
    goto usage
  )
  set "REPO_LIST_FILE=%~2"
  shift
  shift
  goto parse_args
)
if /I "%~1"=="--yes" (
  set "AUTO_YES=1"
  shift
  goto parse_args
)
if /I "%~1"=="-h" goto help
if /I "%~1"=="--help" goto help

echo ERROR: Unknown option: %~1
goto usage

:args_done
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

if "%COMMIT_MESSAGE%"=="" (
  set /p "COMMIT_MESSAGE=Shared commit message: "
)

if "%COMMIT_MESSAGE%"=="" (
  echo ERROR: commit message cannot be empty.
  exit /b 1
)

set "DIRTY_REPOS="
for /f "usebackq tokens=* delims=" %%L in ("%REPO_LIST_FILE%") do (
  set "line=%%L"
  for /f "tokens=1 delims=#" %%A in ("!line!") do set "line=%%A"
  for /f "tokens=* delims= " %%A in ("!line!") do set "line=%%A"
  if not "!line!"=="" (
    set "repo=!line!"
    set "TARGET_DIR=%WORKSPACE_ROOT%\!repo!"
    if exist "!TARGET_DIR!\.git" (
      for /f %%S in ('"%GIT_EXE%" -C "!TARGET_DIR!" status --porcelain ^| find /c /v ""') do set "DIRTY_COUNT=%%S"
      if not "!DIRTY_COUNT!"=="0" (
        set "DIRTY_REPOS=!DIRTY_REPOS! !repo!"
      )
    ) else (
      echo [skip] !repo!: not a git repository at !TARGET_DIR!
    )
  )
)

if "%DIRTY_REPOS%"=="" (
  echo No dirty repositories found.
  exit /b 0
)

echo Workspace root: %WORKSPACE_ROOT%
echo Repo list: %REPO_LIST_FILE%
echo Commit message: %COMMIT_MESSAGE%
echo Repositories to commit and push:
for %%R in (%DIRTY_REPOS%) do echo   - %%R

if not "%AUTO_YES%"=="1" (
  set /p "CONFIRM=Proceed with commit and push? [y/N] "
  if /I not "%CONFIRM%"=="y" if /I not "%CONFIRM%"=="yes" (
    echo Aborted.
    exit /b 1
  )
)

for %%R in (%DIRTY_REPOS%) do (
  set "TARGET_DIR=%WORKSPACE_ROOT%\%%R"
  echo [commit] %%R
  "%GIT_EXE%" -C "!TARGET_DIR!" add -A
  if errorlevel 1 exit /b 1
  "%GIT_EXE%" -C "!TARGET_DIR!" commit -m "%COMMIT_MESSAGE%"
  if errorlevel 1 exit /b 1
  echo [push] %%R
  "%GIT_EXE%" -C "!TARGET_DIR!" push
  if errorlevel 1 exit /b 1
)

echo Done.
exit /b 0

:usage
echo Usage: commit-push-v3.bat [options]
echo.
echo Options:
echo   --message ^<message^>  Shared commit message. If omitted, you will be prompted.
echo   --repos-file ^<path^>  Override repository list file.
echo   --yes                Skip confirmation prompt.
echo   -h, --help           Show this help.
exit /b 1

:help
echo Usage: commit-push-v3.bat [options]
echo.
echo Options:
echo   --message ^<message^>  Shared commit message. If omitted, you will be prompted.
echo   --repos-file ^<path^>  Override repository list file.
echo   --yes                Skip confirmation prompt.
echo   -h, --help           Show this help.
exit /b 0