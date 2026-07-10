param(
    [switch]$IncludeSql,
    [switch]$RunTests,
    [switch]$WhatIf,
    [string]$MvnExe = "mvn",
    [string[]]$ReleaseRepos = @(
        "https://repo1.maven.org/maven2",
        "https://repo.maven.apache.org/maven2",
        "https://oss.sonatype.org/content/repositories/releases"
    )
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$workspaceRoot = (Resolve-Path (Join-Path $scriptDir "..\..")).Path

$orderedModules = @(
    "commons-maven-parent",
    "committer-core",
    "importer",
    "collector-core",
    "collector-http",
    "collector-filesystem",
    "committer-googlecloudsearch",
    "committer-elasticsearch"
)
if ($IncludeSql) {
    $orderedModules += "committer-sql"
}

function Get-PomTextValue {
    param(
        [xml]$Xml,
        [System.Xml.XmlNamespaceManager]$Ns,
        [string]$Xpath
    )
    $node = $Xml.SelectSingleNode($Xpath, $Ns)
    if ($null -eq $node) {
        return $null
    }
    return $node.InnerText.Trim()
}

function Get-ProjectInfo {
    param([string]$PomPath)

    [xml]$pom = Get-Content -Raw -Path $PomPath
    $ns = New-Object System.Xml.XmlNamespaceManager($pom.NameTable)
    $ns.AddNamespace("m", "http://maven.apache.org/POM/4.0.0")

    $artifactId = Get-PomTextValue -Xml $pom -Ns $ns -Xpath "/m:project/m:artifactId"
    $groupId = Get-PomTextValue -Xml $pom -Ns $ns -Xpath "/m:project/m:groupId"
    if ([string]::IsNullOrWhiteSpace($groupId)) {
        $groupId = Get-PomTextValue -Xml $pom -Ns $ns -Xpath "/m:project/m:parent/m:groupId"
    }

    $version = Get-PomTextValue -Xml $pom -Ns $ns -Xpath "/m:project/m:version"
    if ([string]::IsNullOrWhiteSpace($version)) {
        $version = Get-PomTextValue -Xml $pom -Ns $ns -Xpath "/m:project/m:parent/m:version"
    }

    if ([string]::IsNullOrWhiteSpace($artifactId) -or [string]::IsNullOrWhiteSpace($groupId)) {
        throw "Could not resolve artifact coordinates from $PomPath"
    }

    return [PSCustomObject]@{
        ArtifactId = $artifactId
        GroupId = $groupId
        Version = $version
    }
}

function Get-LatestCentralRelease {
    param(
        [string]$GroupId,
        [string]$ArtifactId
    )

    $groupPath = $GroupId -replace "\.", "/"
    foreach ($repo in $ReleaseRepos) {
        $repoBase = $repo.TrimEnd('/')
        $metadataUrl = "$repoBase/$groupPath/$ArtifactId/maven-metadata.xml"
        try {
            [xml]$metadata = Invoke-RestMethod -Uri $metadataUrl -TimeoutSec 20
            $release = $metadata.metadata.versioning.release
            if (-not [string]::IsNullOrWhiteSpace($release)) {
                return $release.Trim()
            }
        } catch {
            Write-Verbose "Metadata lookup failed for $GroupId`:$ArtifactId at $metadataUrl"
        }
    }
    Write-Warning "Could not fetch Maven metadata for $GroupId`:$ArtifactId from configured release repositories."
    return $null
}

function Resolve-ReleaseTag {
    param(
        [string]$RepoPath,
        [string]$Module,
        [string]$ArtifactId,
        [string]$ReleaseVersion
    )

    $candidates = @(
        "v$ReleaseVersion",
        $ReleaseVersion,
        "$ArtifactId-$ReleaseVersion",
        "$Module-$ReleaseVersion"
    )

    foreach ($tag in $candidates) {
        & git -C $RepoPath rev-parse -q --verify "refs/tags/$tag" *> $null
        if ($LASTEXITCODE -eq 0) {
            return $tag
        }
    }
    return $null
}

function HasChangesSinceTag {
    param(
        [string]$RepoPath,
        [string]$Tag
    )

    & git -C $RepoPath diff --quiet "$Tag..HEAD" -- .
    return ($LASTEXITCODE -ne 0)
}

if ($MvnExe -eq "mvn") {
    $cmd = Get-Command mvn,mvn.cmd -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $cmd) {
        throw "Maven not found in PATH. Provide -MvnExe with full path to mvn.cmd."
    }
    $MvnExe = $cmd.Source
} elseif (-not (Test-Path $MvnExe)) {
    throw "Configured Maven executable does not exist: $MvnExe"
}

$moduleInfo = @()
foreach ($module in $orderedModules) {
    $modulePath = Join-Path $workspaceRoot $module
    $pomPath = Join-Path $modulePath "pom.xml"

    if (-not (Test-Path $pomPath)) {
        throw "Missing module pom: $pomPath"
    }

    $proj = Get-ProjectInfo -PomPath $pomPath
    $latestRelease = Get-LatestCentralRelease -GroupId $proj.GroupId -ArtifactId $proj.ArtifactId

    $changed = $false
    $reason = ""
    $tag = $null

    if ($null -eq $latestRelease) {
        $changed = $true
        $reason = "No Central release metadata"
    } else {
        $tag = Resolve-ReleaseTag -RepoPath $modulePath -Module $module -ArtifactId $proj.ArtifactId -ReleaseVersion $latestRelease
        if ($null -ne $tag) {
            $changed = HasChangesSinceTag -RepoPath $modulePath -Tag $tag
            $reason = if ($changed) { "Changed since tag $tag" } else { "No changes since tag $tag" }
        } else {
            $localBase = $proj.Version -replace "-SNAPSHOT$", ""
            if ($localBase -ne $latestRelease) {
                $changed = $true
                $reason = "Version differs from Central release ($latestRelease)"
            } else {
                $statusOutput = (& git -C $modulePath status --porcelain | Out-String).Trim()
                $dirty = ($LASTEXITCODE -eq 0) -and -not [string]::IsNullOrWhiteSpace($statusOutput)
                $changed = $dirty
                $reason = if ($dirty) { "Working tree dirty" } else { "No matching tag and same version" }
            }
        }
    }

    $moduleInfo += [PSCustomObject]@{
        Module = $module
        Path = $modulePath
        Pom = $pomPath
        GroupId = $proj.GroupId
        ArtifactId = $proj.ArtifactId
        LocalVersion = $proj.Version
        LatestCentralRelease = $latestRelease
        ReleaseTag = $tag
        Changed = $changed
        Reason = $reason
    }
}

Write-Host ""
Write-Host "Change detection summary:"
$moduleInfo | Select-Object Module, ArtifactId, LocalVersion, LatestCentralRelease, Changed, Reason | Format-Table -AutoSize

$toDeploy = $moduleInfo | Where-Object { $_.Changed }
if (-not $toDeploy) {
    Write-Host ""
    Write-Host "No modules detected as changed since latest Central release. Nothing to deploy."
    exit 0
}

$mvnFlags = @(
    "-Dgpg.skip=true",
    "-Dmaven.javadoc.skip=true"
)
if ($RunTests) {
    $mvnFlags += "-DskipTests=false"
} else {
    $mvnFlags += "-Dmaven.test.skip=true"
}

Write-Host ""
Write-Host "Modules selected for deploy (dependency order):"
$toDeploy | Select-Object -ExpandProperty Module | ForEach-Object { Write-Host " - $_" }

if ($WhatIf) {
    Write-Host ""
    Write-Host "WhatIf mode enabled. No build/deploy commands were run."
    exit 0
}

foreach ($m in $toDeploy) {
    Write-Host ""
    Write-Host "[deploy] $($m.Module)"
    & $MvnExe -f $m.Pom @mvnFlags deploy
    if ($LASTEXITCODE -ne 0) {
        throw "Deploy failed for module: $($m.Module)"
    }
}

Write-Host ""
Write-Host "Deploy completed successfully for changed modules."
