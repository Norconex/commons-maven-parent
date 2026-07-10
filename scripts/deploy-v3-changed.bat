@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..\..") do set "WORKSPACE_ROOT=%%~fI"

set "INCLUDE_SQL=0"
set "SKIP_TESTS=1"
set "WHAT_IF=0"
if "%MVN_EXE%"=="" set "MVN_EXE=mvn"
set "RELEASE_REPOS=https://repo1.maven.org/maven2 https://repo.maven.apache.org/maven2 https://oss.sonatype.org/content/repositories/releases"

set "MODULES=commons-maven-parent committer-core importer collector-core collector-http collector-filesystem committer-googlecloudsearch committer-elasticsearch"

:parse_args
if "%~1"=="" goto args_done
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
if /I "%~1"=="--what-if" (
  set "WHAT_IF=1"
  shift
  goto parse_args
)
if /I "%~1"=="--mvn-exe" (
  if "%~2"=="" (
    echo ERROR: --mvn-exe requires a value
    goto usage
  )
  set "MVN_EXE=%~2"
  shift
  shift
  goto parse_args
)
if /I "%~1"=="--release-repo" (
  if "%~2"=="" (
    echo ERROR: --release-repo requires a value
    goto usage
  )
  set "RELEASE_REPOS=%~2"
  shift
  shift
  goto parse_args
)
if /I "%~1"=="-h" goto usage
if /I "%~1"=="--help" goto usage

echo ERROR: Unknown option: %~1
goto usage

:args_done
if "%INCLUDE_SQL%"=="1" set "MODULES=%MODULES% committer-sql"

if /i "%MVN_EXE%"=="mvn" (
  mvn -v >nul 2>nul
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

git --version >nul 2>nul
if errorlevel 1 (
  echo ERROR: git is required but was not found in PATH.
  exit /b 1
)

curl --version >nul 2>nul
if errorlevel 1 (
  echo ERROR: curl is required but was not found in PATH.
  exit /b 1
)

set "CHANGED_MODULES="
set "SUMMARY_FILE=%TEMP%\deploy-v3-changed-summary-%RANDOM%.txt"
del "%SUMMARY_FILE%" >nul 2>nul

echo.
echo Change detection summary:

for %%M in (%MODULES%) do (
  call :detect_module %%M
  if errorlevel 1 exit /b 1
)

if "%CHANGED_MODULES%"=="" (
  echo.
  echo No modules detected as changed since latest release metadata. Nothing to deploy.
  exit /b 0
)

echo.
echo Modules selected for deploy ^(dependency order^):
for %%M in (%CHANGED_MODULES%) do echo  - %%M

if "%WHAT_IF%"=="1" (
  echo.
  echo What-if mode enabled. No deploy commands were run.
  exit /b 0
)

set "MVN_FLAGS=-Dgpg.skip=true -Dmaven.javadoc.skip=true"
if "%SKIP_TESTS%"=="1" (
  set "MVN_FLAGS=%MVN_FLAGS% -Dmaven.test.skip=true"
) else (
  set "MVN_FLAGS=%MVN_FLAGS% -DskipTests=false"
)

for %%M in (%CHANGED_MODULES%) do (
  echo.
  echo [deploy] %%M
  call "%MVN_EXE%" -f "%WORKSPACE_ROOT%\%%M\pom.xml" %MVN_FLAGS% deploy
  if errorlevel 1 exit /b 1
)

echo.
echo Deploy completed successfully for changed modules.
exit /b 0

:detect_module
set "MODULE=%~1"
set "POM=%WORKSPACE_ROOT%\%MODULE%\pom.xml"
if not exist "%POM%" (
  echo ERROR: Missing module pom.xml: %POM%
  exit /b 1
)

set "GROUP_ID="
set "ARTIFACT_ID="
set "LOCAL_VERSION="
for /f "usebackq delims=" %%I in (`"%MVN_EXE%" -q -f "%POM%" -DforceStdout help:evaluate -Dexpression^=project.groupId`) do set "GROUP_ID=%%I"
for /f "usebackq delims=" %%I in (`"%MVN_EXE%" -q -f "%POM%" -DforceStdout help:evaluate -Dexpression^=project.artifactId`) do set "ARTIFACT_ID=%%I"
for /f "usebackq delims=" %%I in (`"%MVN_EXE%" -q -f "%POM%" -DforceStdout help:evaluate -Dexpression^=project.version`) do set "LOCAL_VERSION=%%I"

if "%GROUP_ID%"=="" (
  echo ERROR: Could not resolve project.groupId for %MODULE%
  exit /b 1
)
if "%ARTIFACT_ID%"=="" (
  echo ERROR: Could not resolve project.artifactId for %MODULE%
  exit /b 1
)

set "GROUP_PATH=%GROUP_ID:.=/%"
set "LATEST_RELEASE="
for %%R in (%RELEASE_REPOS%) do (
  set "META_FILE=%TEMP%\deploy-v3-meta-%RANDOM%.xml"
  curl -fsSL "%%R/%GROUP_PATH%/%ARTIFACT_ID%/maven-metadata.xml" -o "!META_FILE!" >nul 2>nul
  if not errorlevel 1 (
    for /f "tokens=2 delims=<>"> %%V in ('findstr /R /C:"<release>.*</release>" "!META_FILE!"') do set "LATEST_RELEASE=%%V"
  )
  del "!META_FILE!" >nul 2>nul
  if not "!LATEST_RELEASE!"=="" goto metadata_found
)

:metadata_found
set "CHANGED=0"
set "REASON="
set "TAG="

if "!LATEST_RELEASE!"=="" (
  set "CHANGED=1"
  set "REASON=No release metadata"
) else (
  call :resolve_tag "%WORKSPACE_ROOT%\%MODULE%" "%ARTIFACT_ID%" "%MODULE%" "!LATEST_RELEASE!"
  if not "!TAG!"=="" (
    git -C "%WORKSPACE_ROOT%\%MODULE%" diff --quiet "!TAG!..HEAD" -- .
    if errorlevel 1 (
      set "CHANGED=1"
      set "REASON=Changed since tag !TAG!"
    ) else (
      set "REASON=No changes since tag !TAG!"
    )
  ) else (
    set "LOCAL_BASE=!LOCAL_VERSION:-SNAPSHOT=!"
    if /I not "!LOCAL_BASE!"=="!LATEST_RELEASE!" (
      set "CHANGED=1"
      set "REASON=Version differs from release !LATEST_RELEASE!"
    ) else (
      for /f %%D in ('git -C "%WORKSPACE_ROOT%\%MODULE%" status --porcelain ^| find /c /v ""') do set "DIRTY=%%D"
      if not "!DIRTY!"=="0" (
        set "CHANGED=1"
        set "REASON=Working tree dirty"
      ) else (
        set "REASON=No matching tag and same version"
      )
    )
  )
)

if "!CHANGED!"=="1" set "CHANGED_MODULES=%CHANGED_MODULES% %MODULE%"
echo %MODULE% ^| %ARTIFACT_ID% ^| %LOCAL_VERSION% ^| !LATEST_RELEASE! ^| !CHANGED! ^| !REASON!
exit /b 0

:resolve_tag
set "TAG="
set "REPO_PATH=%~1"
set "ART=%~2"
set "MOD=%~3"
set "REL=%~4"

for %%T in ("v%REL%" "%REL%" "%ART%-%REL%" "%MOD%-%REL%") do (
  git -C "%REPO_PATH%" rev-parse -q --verify "refs/tags/%%~T" >nul 2>nul
  if not errorlevel 1 (
    set "TAG=%%~T"
    exit /b 0
  )
)
exit /b 0

:usage
echo Usage: deploy-v3-changed.bat [options]
echo.
echo Options:
echo   --include-sql          Include committer-sql in change detection/deploy.
echo   --run-tests            Run tests during deploy ^(default skips tests^).
echo   --what-if              Show what would be deployed without deploying.
echo   --mvn-exe ^<path^>      Maven executable path.
echo   --release-repo ^<url^>  Release metadata repository URL.
echo   -h, --help             Show this help.
exit /b 1
