#requires -Version 5.1
<#
Copy this script into your mpv folder and run:
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\update-mpv.ps1
Close mpv before updating. Existing matching files are overwritten.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$targetDir = $PSScriptRoot
$workDir = $null
$oldTls = [Net.ServicePointManager]::SecurityProtocol

try {
    [Net.ServicePointManager]::SecurityProtocol = $oldTls -bor [Net.SecurityProtocolType]::Tls12
    if (-not $targetDir) { throw 'Save this script into the mpv folder before running it.' }

    # Use GitHub's latest release, never a hard-coded date or asset URL.
    $headers = @{ 'User-Agent' = 'mpv-portable-updater'; Accept = 'application/vnd.github+json' }
    Write-Host 'Checking the latest mpv release...'
    $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/zhongfly/mpv-winbuild/releases/latest' -Headers $headers -TimeoutSec 60
    $assets = @($release.assets | Where-Object { $_.name -match '^mpv-x86_64-v3-.+\.7z$' })
    if ($assets.Count -ne 1) {
        throw "Expected exactly one mpv-x86_64-v3 archive in release $($release.tag_name); found $($assets.Count)."
    }
    $asset = $assets[0]

    # All downloads and extraction happen in a unique temporary directory first.
    $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
    $workDir = Join-Path $tempRoot ('mpv-update-' + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $workDir | Out-Null
    $archive = Join-Path $workDir 'mpv.7z'
    $staging = Join-Path $workDir 'unpacked'

    $sevenZip = $null
    foreach ($name in @('7z.exe', '7za.exe', '7zr.exe')) {
        $command = Get-Command $name -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($command) { $sevenZip = $command.Source; break }
    }
    if (-not $sevenZip) {
        foreach ($root in @($env:ProgramFiles, ${env:ProgramFiles(x86)})) {
            if ($root) {
                $candidate = Join-Path $root '7-Zip\7z.exe'
                if (Test-Path -LiteralPath $candidate -PathType Leaf) { $sevenZip = $candidate; break }
            }
        }
    }
    if (-not $sevenZip) {
        Write-Host 'Downloading the official standalone 7-Zip extractor...'
        $sevenZip = Join-Path $workDir '7zr.exe'
        Invoke-WebRequest -UseBasicParsing -Uri 'https://www.7-zip.org/a/7zr.exe' -OutFile $sevenZip -TimeoutSec 180
    }

    Write-Host "Downloading $($asset.name)..."
    Invoke-WebRequest -UseBasicParsing -Uri $asset.browser_download_url -Headers $headers -OutFile $archive -TimeoutSec 1800
    if ((Get-Item -LiteralPath $archive).Length -ne [long]$asset.size) {
        throw 'The downloaded archive size does not match the release asset.'
    }
    if ($asset.digest -match '^sha256:([a-fA-F0-9]{64})$') {
        $expectedHash = $Matches[1]
        if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash -ne $expectedHash) {
            throw 'The downloaded archive failed SHA-256 verification.'
        }
    }

    Write-Host 'Extracting...'
    & $sevenZip x $archive "-o$staging" -y -aoa | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "7-Zip extraction failed (exit code $LASTEXITCODE)." }
    $sourceDir = $staging
    if (-not (Test-Path -LiteralPath (Join-Path $sourceDir 'mpv.exe') -PathType Leaf)) {
        $players = @(Get-ChildItem -LiteralPath $staging -Filter mpv.exe -File -Recurse)
        if ($players.Count -ne 1) { throw 'The archive does not contain an unambiguous mpv.exe.' }
        $sourceDir = $players[0].DirectoryName
    }

    # Do not remove unrelated files (for example, portable_config).
    Write-Host "Updating files in $targetDir ..."
    Get-ChildItem -LiteralPath $sourceDir -Force | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $targetDir -Recurse -Force
    }
    Write-Host "mpv updated successfully: $($release.tag_name)" -ForegroundColor Green
}
catch {
    Write-Warning 'Update failed. If mpv is running, close it and rerun this script. A copy failure may leave a partial update; rerun to finish.'
    throw
}
finally {
    [Net.ServicePointManager]::SecurityProtocol = $oldTls
    if ($workDir -and (Test-Path -LiteralPath $workDir)) {
        # Validate the absolute deletion target before recursive cleanup.
        $resolvedWork = [IO.Path]::GetFullPath($workDir)
        $resolvedTemp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
        if ($resolvedWork.StartsWith($resolvedTemp, [StringComparison]::OrdinalIgnoreCase) -and
            ([IO.Path]::GetFileName($resolvedWork) -match '^mpv-update-[a-f0-9]{32}$')) {
            Remove-Item -LiteralPath $resolvedWork -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
