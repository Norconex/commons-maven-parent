@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..\..") do set "WORKSPACE_ROOT=%%~fI"

set "SKIP_TESTS=1"
set "WHAT_IF=0"
if "%MVN_EXE%"=="" set "MVN_EXE=mvn"
set "RELEASE_REPOS=https://repo1.maven.org/maven2 https://repo.maven.apache.org/maven2"
set "SNAPSHOT_REPOS=https://central.sonatype.com/repository/maven-snapshots"

set "MODULES=commons-maven-parent committer-core importer collector-core collector-http collector-filesystem committer-googlecloudsearch committer-elasticsearch committer-cloudsearch committer-solr committer-idol committer-azuresearch committer-neo4j committer-sql"

:parse_args
if "%~1"=="" goto args_done
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
if /i "%MVN_EXE%"=="mvn" (
  rem Resolve to the fully-qualified path (with extension) up front. This is
  rem required for correctness, not just cleanliness: cmd.exe skips PATHEXT
  rem extension resolution for quoted command names, so a later
  rem call "%MVN_EXE%" ... with the bare name "mvn" silently fails to find
  rem mvn.cmd. A resolved, extension-qualified path is safe to quote.
  set "MVN_RESOLVED="
  for /f "usebackq delims=" %%P in (`where mvn 2^>nul`) do if not defined MVN_RESOLVED set "MVN_RESOLVED=%%P"
  if not defined MVN_RESOLVED (
    echo ERROR: mvn is required but was not found in PATH.
    echo Hint: set MVN_EXE to full path, e.g. C:\apps\apache-maven-3.9.9\bin\mvn.cmd
    exit /b 1
  )
  set "MVN_EXE=!MVN_RESOLVED!"
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
set "CHANGED_COMMONS_MAVEN_PARENT=0"
set "CHANGED_COMMITTER_CORE=0"
set "CHANGED_IMPORTER=0"
set "CHANGED_COLLECTOR_CORE=0"
set "CHANGED_COLLECTOR_HTTP=0"
set "CHANGED_COLLECTOR_FILESYSTEM=0"
set "CHANGED_COMMITTER_GOOGLECLOUDSEARCH=0"
set "CHANGED_COMMITTER_ELASTICSEARCH=0"
set "CHANGED_COMMITTER_CLOUDSEARCH=0"
set "CHANGED_COMMITTER_SOLR=0"
set "CHANGED_COMMITTER_IDOL=0"
set "CHANGED_COMMITTER_AZURESEARCH=0"
set "CHANGED_COMMITTER_NEO4J=0"
set "CHANGED_COMMITTER_SQL=0"
set "SUMMARY_FILE=%TEMP%\deploy-v3-changed-summary-%RANDOM%.txt"
del "%SUMMARY_FILE%" >nul 2>nul

echo.
echo Change detection summary:

for %%M in (%MODULES%) do (
  call :detect_module %%M
  if errorlevel 1 exit /b 1
)

if "%CHANGED_COMMONS_MAVEN_PARENT%"=="1" (
  set "CHANGED_COMMITTER_CORE=1"
  set "CHANGED_IMPORTER=1"
  set "CHANGED_COLLECTOR_CORE=1"
  set "CHANGED_COLLECTOR_HTTP=1"
  set "CHANGED_COLLECTOR_FILESYSTEM=1"
  set "CHANGED_COMMITTER_GOOGLECLOUDSEARCH=1"
  set "CHANGED_COMMITTER_ELASTICSEARCH=1"
  set "CHANGED_COMMITTER_CLOUDSEARCH=1"
  set "CHANGED_COMMITTER_SOLR=1"
  set "CHANGED_COMMITTER_IDOL=1"
  set "CHANGED_COMMITTER_AZURESEARCH=1"
  set "CHANGED_COMMITTER_NEO4J=1"
  set "CHANGED_COMMITTER_SQL=1"
)
if "%CHANGED_COMMITTER_CORE%"=="1" (
  set "CHANGED_IMPORTER=1"
  set "CHANGED_COLLECTOR_CORE=1"
  set "CHANGED_COLLECTOR_HTTP=1"
  set "CHANGED_COLLECTOR_FILESYSTEM=1"
  set "CHANGED_COMMITTER_GOOGLECLOUDSEARCH=1"
  set "CHANGED_COMMITTER_ELASTICSEARCH=1"
  set "CHANGED_COMMITTER_CLOUDSEARCH=1"
  set "CHANGED_COMMITTER_SOLR=1"
  set "CHANGED_COMMITTER_IDOL=1"
  set "CHANGED_COMMITTER_AZURESEARCH=1"
  set "CHANGED_COMMITTER_NEO4J=1"
  set "CHANGED_COMMITTER_SQL=1"
)
if "%CHANGED_IMPORTER%"=="1" (
  set "CHANGED_COLLECTOR_CORE=1"
  set "CHANGED_COLLECTOR_HTTP=1"
  set "CHANGED_COLLECTOR_FILESYSTEM=1"
  set "CHANGED_COMMITTER_GOOGLECLOUDSEARCH=1"
)
if "%CHANGED_COLLECTOR_CORE%"=="1" (
  set "CHANGED_COLLECTOR_HTTP=1"
  set "CHANGED_COLLECTOR_FILESYSTEM=1"
)

set "CHANGED_MODULES="
for %%M in (%MODULES%) do (
  if /I "%%M"=="commons-maven-parent" if "%CHANGED_COMMONS_MAVEN_PARENT%"=="1" set "CHANGED_MODULES=!CHANGED_MODULES! %%M"
  if /I "%%M"=="committer-core" if "%CHANGED_COMMITTER_CORE%"=="1" set "CHANGED_MODULES=!CHANGED_MODULES! %%M"
  if /I "%%M"=="importer" if "%CHANGED_IMPORTER%"=="1" set "CHANGED_MODULES=!CHANGED_MODULES! %%M"
  if /I "%%M"=="collector-core" if "%CHANGED_COLLECTOR_CORE%"=="1" set "CHANGED_MODULES=!CHANGED_MODULES! %%M"
  if /I "%%M"=="collector-http" if "%CHANGED_COLLECTOR_HTTP%"=="1" set "CHANGED_MODULES=!CHANGED_MODULES! %%M"
  if /I "%%M"=="collector-filesystem" if "%CHANGED_COLLECTOR_FILESYSTEM%"=="1" set "CHANGED_MODULES=!CHANGED_MODULES! %%M"
  if /I "%%M"=="committer-googlecloudsearch" if "%CHANGED_COMMITTER_GOOGLECLOUDSEARCH%"=="1" set "CHANGED_MODULES=!CHANGED_MODULES! %%M"
  if /I "%%M"=="committer-elasticsearch" if "%CHANGED_COMMITTER_ELASTICSEARCH%"=="1" set "CHANGED_MODULES=!CHANGED_MODULES! %%M"
  if /I "%%M"=="committer-cloudsearch" if "%CHANGED_COMMITTER_CLOUDSEARCH%"=="1" set "CHANGED_MODULES=!CHANGED_MODULES! %%M"
  if /I "%%M"=="committer-solr" if "%CHANGED_COMMITTER_SOLR%"=="1" set "CHANGED_MODULES=!CHANGED_MODULES! %%M"
  if /I "%%M"=="committer-idol" if "%CHANGED_COMMITTER_IDOL%"=="1" set "CHANGED_MODULES=!CHANGED_MODULES! %%M"
  if /I "%%M"=="committer-azuresearch" if "%CHANGED_COMMITTER_AZURESEARCH%"=="1" set "CHANGED_MODULES=!CHANGED_MODULES! %%M"
  if /I "%%M"=="committer-neo4j" if "%CHANGED_COMMITTER_NEO4J%"=="1" set "CHANGED_MODULES=!CHANGED_MODULES! %%M"
  if /I "%%M"=="committer-sql" if "%CHANGED_COMMITTER_SQL%"=="1" set "CHANGED_MODULES=!CHANGED_MODULES! %%M"
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
call :mvn_eval "%POM%" project.groupId GROUP_ID
if errorlevel 1 exit /b 1
call :mvn_eval "%POM%" project.artifactId ARTIFACT_ID
if errorlevel 1 exit /b 1
call :mvn_eval "%POM%" project.version LOCAL_VERSION
if errorlevel 1 exit /b 1

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
    for /f "tokens=3 delims=<>" %%V in ('findstr /R /C:"<release>.*</release>" "!META_FILE!"') do set "LATEST_RELEASE=%%V"
  )
  del "!META_FILE!" >nul 2>nul
  if not "!LATEST_RELEASE!"=="" goto metadata_found
)

:metadata_found
set "CHANGED=0"
set "REASON="
set "TAG="

if not "!LATEST_RELEASE!"=="" goto release_based_detection

rem No release exists yet under this groupId/artifactId (expected for a
rem SNAPSHOT-only project). Fall back to comparing local commit history
rem against the last deployed SNAPSHOT's timestamp instead of
rem unconditionally treating the module as changed.
set "SNAPSHOT_LASTUPDATED="
for %%R in (%SNAPSHOT_REPOS%) do (
  set "SNAP_META_FILE=%TEMP%\deploy-v3-snap-meta-%RANDOM%.xml"
  curl -fsSL "%%R/%GROUP_PATH%/%ARTIFACT_ID%/maven-metadata.xml" -o "!SNAP_META_FILE!" >nul 2>nul
  if not errorlevel 1 (
    for /f "tokens=3 delims=<>" %%V in ('findstr /R /C:"<lastUpdated>.*</lastUpdated>" "!SNAP_META_FILE!"') do set "SNAPSHOT_LASTUPDATED=%%V"
  )
  del "!SNAP_META_FILE!" >nul 2>nul
  if not "!SNAPSHOT_LASTUPDATED!"=="" goto snapshot_metadata_found
)

:snapshot_metadata_found
if "!SNAPSHOT_LASTUPDATED!"=="" (
  set "CHANGED=1"
  set "REASON=No release or snapshot metadata"
) else (
  for /f %%D in ('git -C "%WORKSPACE_ROOT%\%MODULE%" status --porcelain ^| find /c /v ""') do set "DIRTY=%%D"
  if not "!DIRTY!"=="0" (
    set "CHANGED=1"
    set "REASON=Working tree dirty"
  ) else (
    for /f "usebackq" %%E in (`git -C "%WORKSPACE_ROOT%\%MODULE%" log -1 --format^=%%ct`) do set "LAST_COMMIT_EPOCH=%%E"
    set "SNAPSHOT_EPOCH="
    call :date_to_epoch "!SNAPSHOT_LASTUPDATED!" SNAPSHOT_EPOCH
    if "!SNAPSHOT_EPOCH!"=="" (
      set "CHANGED=1"
      set "REASON=Could not parse snapshot lastUpdated timestamp"
    ) else if !LAST_COMMIT_EPOCH! GTR !SNAPSHOT_EPOCH! (
      set "CHANGED=1"
      set "REASON=Changed since last snapshot deploy"
    ) else (
      set "REASON=No changes since last snapshot deploy"
    )
  )
)
goto detect_done

:release_based_detection
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

:detect_done
if "!CHANGED!"=="1" set "CHANGED_MODULES=%CHANGED_MODULES% %MODULE%"
if "!CHANGED!"=="1" call :mark_changed "%MODULE%"
echo %MODULE% ^| %ARTIFACT_ID% ^| %LOCAL_VERSION% ^| !LATEST_RELEASE! ^| !CHANGED! ^| !REASON!
exit /b 0

:mark_changed
set "M=%~1"
if /I "%M%"=="commons-maven-parent" set "CHANGED_COMMONS_MAVEN_PARENT=1"
if /I "%M%"=="committer-core" set "CHANGED_COMMITTER_CORE=1"
if /I "%M%"=="importer" set "CHANGED_IMPORTER=1"
if /I "%M%"=="collector-core" set "CHANGED_COLLECTOR_CORE=1"
if /I "%M%"=="collector-http" set "CHANGED_COLLECTOR_HTTP=1"
if /I "%M%"=="collector-filesystem" set "CHANGED_COLLECTOR_FILESYSTEM=1"
if /I "%M%"=="committer-googlecloudsearch" set "CHANGED_COMMITTER_GOOGLECLOUDSEARCH=1"
if /I "%M%"=="committer-elasticsearch" set "CHANGED_COMMITTER_ELASTICSEARCH=1"
if /I "%M%"=="committer-cloudsearch" set "CHANGED_COMMITTER_CLOUDSEARCH=1"
if /I "%M%"=="committer-solr" set "CHANGED_COMMITTER_SOLR=1"
if /I "%M%"=="committer-idol" set "CHANGED_COMMITTER_IDOL=1"
if /I "%M%"=="committer-azuresearch" set "CHANGED_COMMITTER_AZURESEARCH=1"
if /I "%M%"=="committer-neo4j" set "CHANGED_COMMITTER_NEO4J=1"
if /I "%M%"=="committer-sql" set "CHANGED_COMMITTER_SQL=1"
exit /b 0

:mvn_eval
set "MVN_POM=%~1"
set "MVN_EXPR=%~2"
set "MVN_OUTVAR=%~3"
set "MVN_TMP=%TEMP%\deploy-v3-eval-%RANDOM%.txt"
call "%MVN_EXE%" -q -f "%MVN_POM%" -DforceStdout help:evaluate -Dexpression=%MVN_EXPR% > "%MVN_TMP%" 2>nul
if errorlevel 1 (
  del "%MVN_TMP%" >nul 2>nul
  echo ERROR: Maven evaluation failed for expression %MVN_EXPR% on %MVN_POM%
  exit /b 1
)
set "MVN_VALUE="
for /f "usebackq delims=" %%L in ("%MVN_TMP%") do (
  if not "%%L"=="" set "MVN_VALUE=%%L"
)
del "%MVN_TMP%" >nul 2>nul
if "%MVN_VALUE%"=="" (
  echo ERROR: Empty Maven evaluation result for expression %MVN_EXPR% on %MVN_POM%
  exit /b 1
)
set "%MVN_OUTVAR%=%MVN_VALUE%"
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

rem Converts a yyyyMMddHHmmss UTC timestamp (Maven metadata's <lastUpdated>
rem format) to Unix epoch seconds, using the days_from_civil algorithm
rem (Howard Hinnant, public domain). Pure batch arithmetic, no external
rem process, so it works the same on any Windows machine regardless of
rem whether PowerShell is available.
rem %1 = yyyyMMddHHmmss string, %2 = name of variable to receive the result.
:date_to_epoch
setlocal EnableDelayedExpansion
set "DT=%~1"
if "%DT%"=="" (
  endlocal
  set "%~2="
  exit /b 0
)
rem The "1<value> - 10^n" trick avoids batch's octal misinterpretation of
rem zero-padded numbers (e.g. "08" would otherwise error as an invalid
rem octal digit).
set /a "YY=1%DT:~0,4% - 10000"
set /a "MO=1%DT:~4,2% - 100"
set /a "DD=1%DT:~6,2% - 100"
set /a "HH=1%DT:~8,2% - 100"
set /a "MI=1%DT:~10,2% - 100"
set /a "SS=1%DT:~12,2% - 100"
if !MO! LEQ 2 (
  set /a "YY=YY-1"
  set /a "MADJ=MO+9"
) else (
  set /a "MADJ=MO-3"
)
set /a "ERA=YY/400"
set /a "YOE=YY-ERA*400"
set /a "DOY=(153*MADJ+2)/5+DD-1"
set /a "DOE=YOE*365+YOE/4-YOE/100+DOY"
set /a "DAYS=ERA*146097+DOE-719468"
set /a "EPOCH=DAYS*86400+HH*3600+MI*60+SS"
endlocal & set "%~2=%EPOCH%"
exit /b 0

:usage
echo Usage: deploy-v3-changed.bat [options]
echo.
echo Options:
echo   --run-tests            Run tests during deploy ^(default skips tests^).
echo   --what-if              Show what would be deployed without deploying.
echo   --mvn-exe ^<path^>      Maven executable path.
echo   --release-repo ^<url^>  Release metadata repository URL.
echo   -h, --help             Show this help.
exit /b 1
