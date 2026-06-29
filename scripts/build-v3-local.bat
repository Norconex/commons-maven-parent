@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..\..") do set "WORKSPACE_ROOT=%%~fI"

set "SET_VERSION="
set "INCLUDE_SQL=0"
set "SKIP_TESTS=1"
if "%MVN_EXE%"=="" set "MVN_EXE=mvn"
if "%GIT_EXE%"=="" set "GIT_EXE=git"

:parse_args
if "%~1"=="" goto args_done
if /I "%~1"=="--set-version" (
  if "%~2"=="" (
    echo ERROR: --set-version requires a value
    goto usage
  )
  set "SET_VERSION=%~2"
  shift
  shift
  goto parse_args
)
if /I "%~1"=="--include-sql" (
  set "INCLUDE_SQL=1"
  shift
  goto parse_args
)
if /I "%~1"=="--run-tests" (
  set "SKIP_TESTS=0"
  shift
  goto parse_args
)
if /I "%~1"=="-h" goto usage
if /I "%~1"=="--help" goto usage

echo ERROR: Unknown option: %~1
goto usage

:args_done
if /i "%MVN_EXE%"=="mvn" (
  where mvn >nul 2>nul
  if errorlevel 1 (
    echo ERROR: mvn is required but was not found in PATH.
    echo Hint: set MVN_EXE to full path, e.g. C:\apps\apache-maven-3.9.9\bin\mvn.cmd
    exit /b 1
  )
) else (
  if not exist "%MVN_EXE%" (
    echo ERROR: configured MVN_EXE not found: %MVN_EXE%
    exit /b 1
  )
)

set "MODULES=commons-maven-parent committer-core importer collector-core collector-http collector-filesystem committer-googlecloudsearch committer-elasticsearch"
if "%INCLUDE_SQL%"=="1" set "MODULES=%MODULES% committer-sql"

for %%M in (%MODULES%) do (
  if not exist "%WORKSPACE_ROOT%\%%M\pom.xml" (
    echo ERROR: Missing module or pom.xml: %WORKSPACE_ROOT%\%%M
    exit /b 1
  )
)

if not "%SET_VERSION%"=="" (
  for %%M in (%MODULES%) do (
    if exist "%WORKSPACE_ROOT%\%%M\.git" (
      for /f %%S in ('"%GIT_EXE%" -C "%WORKSPACE_ROOT%\%%M" status --porcelain ^| find /c /v ""') do set "DIRTY=%%S"
      if not "!DIRTY!"=="0" (
        echo ERROR: Working tree is not clean: %%M
        echo        Commit/stash changes first, or run without --set-version.
        exit /b 1
      )
    )
  )

  echo Applying version override: %SET_VERSION%
  for %%M in (%MODULES%) do (
    call "%MVN_EXE%" -q -f "%WORKSPACE_ROOT%\%%M\pom.xml" versions:set -DnewVersion=%SET_VERSION% -DgenerateBackupPoms=false
    if errorlevel 1 exit /b 1
  )

  for %%M in (committer-core importer collector-core collector-http collector-filesystem committer-googlecloudsearch committer-elasticsearch) do (
    findstr /C:"<artifactId>norconex-collector-parent</artifactId>" "%WORKSPACE_ROOT%\%%M\pom.xml" >nul
    if not errorlevel 1 (
      call "%MVN_EXE%" -q -f "%WORKSPACE_ROOT%\%%M\pom.xml" versions:update-parent -DparentVersion=[%SET_VERSION%] -DallowSnapshots=true -DgenerateBackupPoms=false
      if errorlevel 1 exit /b 1
    )
  )

  call :set_property_if_present collector-core norconex-importer.version
  call :set_property_if_present collector-core norconex-committer-core.version
  call :set_property_if_present collector-http norconex-collector-core.version
  call :set_property_if_present collector-http norconex-importer.version
  call :set_property_if_present collector-http norconex-committer-core.version
  call :set_property_if_present collector-filesystem norconex-collector-core.version
  call :set_property_if_present collector-filesystem norconex-importer.version
  call :set_property_if_present collector-filesystem norconex-committer-core.version
  call :set_property_if_present committer-googlecloudsearch norconex-importer.version
  call :set_property_if_present committer-googlecloudsearch norconex-committer-core.version
  call :set_property_if_present committer-elasticsearch norconex-committer-core.version
)

set "MVN_FLAGS=-Dgpg.skip=true -Dmaven.javadoc.skip=true"
if "%SKIP_TESTS%"=="1" (
  set "MVN_FLAGS=%MVN_FLAGS% -Dmaven.test.skip=true"
) else (
  set "MVN_FLAGS=%MVN_FLAGS% -DskipTests=false"
)

echo Building modules in order...
for %%M in (%MODULES%) do (
  echo [build] %%M
  call "%MVN_EXE%" -f "%WORKSPACE_ROOT%\%%M\pom.xml" %MVN_FLAGS% install
  if errorlevel 1 exit /b 1
)

echo Build completed successfully.
if not "%SET_VERSION%"=="" echo Version override mode changed pom.xml files to: %SET_VERSION%
exit /b 0

:set_property_if_present
set "MOD=%~1"
set "PROP=%~2"
findstr /C:"<%PROP%>" "%WORKSPACE_ROOT%\%MOD%\pom.xml" >nul
if errorlevel 1 goto :eof
call "%MVN_EXE%" -q -f "%WORKSPACE_ROOT%\%MOD%\pom.xml" versions:set-property -Dproperty=%PROP% -DnewVersion=%SET_VERSION% -DgenerateBackupPoms=false
if errorlevel 1 exit /b 1
goto :eof

:usage
echo Usage: build-v3-local.bat [options]
echo.
echo Options:
echo   --set-version ^<version^>  Rewrite module versions/properties before build.
echo                            This modifies pom.xml files in your working tree.
echo   --include-sql           Include committer-sql in the build.
echo   --run-tests             Run tests ^(default is -DskipTests^).
echo   -h, --help              Show this help.
exit /b 1
