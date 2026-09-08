<#
.SYNOPSIS
    Configure and build uACPI-NT for one Windows release and architecture.

.EXAMPLE
    .\scripts\build.ps1 -Target win7
    .\scripts\build.ps1 -Target win7 -Arch x86
    .\scripts\build.ps1 -Target win11 -Arch arm64 -Config Release
    .\scripts\build.ps1 -Target win10 -VsVersion latest
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('ws03','vista','vistasp1','vistasp2',
                 'win7','win8','winblue','win10','win10_ni','win11')]
    [string] $Target,

    [ValidateSet('x64','x86','arm64')]
    [string] $Arch = 'x64',

    [ValidateSet('Debug','Release')]
    [string] $Config = 'Debug',

    [string] $VsVersion = '2019',

    [switch] $Clean,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $CMakeArgs
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$RepoRoot = Split-Path -Parent $PSScriptRoot

function Get-VisualStudioInstalls {
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    if (-not (Test-Path $vswhere)) {
        throw "vswhere.exe not found. Install Visual Studio with the C++ build tools."
    }

    $json = & $vswhere -products * -prerelease -format json | Out-String
    $all = @($json | ConvertFrom-Json)

    @($all | Where-Object {
        Test-Path (Join-Path $_.installationPath 'VC\Auxiliary\Build\vcvarsall.bat')
    })
}

function Select-VisualStudio {
    param([string] $Preference)

    if ($Preference -and (Test-Path -PathType Container $Preference)) {
        return [pscustomobject]@{ Path = $Preference; Name = 'explicit path'; Version = '' }
    }

    $installs = Get-VisualStudioInstalls
    if ($installs.Count -eq 0) {
        throw "No Visual Studio installation with the C++ build tools was found."
    }

    $newest = $installs |
        Sort-Object { [version]$_.installationVersion } -Descending |
        Select-Object -First 1

    if ($Preference -eq 'latest') {
        $chosen = $newest
    } else {
        $major = switch -Regex ($Preference) {
            '^2019$' { 16; break }
            '^2022$' { 17; break }
            '^2026$' { 18; break }
            '^\d+$'  { [int]$Preference; break }
            default  { -1 }
        }
        if ($major -lt 0) {
            throw "Unrecognised -VsVersion '$Preference'. Use 2019, latest, or an installation path."
        }

        $chosen = $installs |
            Where-Object { ([version]$_.installationVersion).Major -eq $major } |
            Sort-Object { [version]$_.installationVersion } -Descending |
            Select-Object -First 1

        if (-not $chosen) {
            Write-Host "  (no Visual Studio with major version $major is installed; using the newest)" -ForegroundColor DarkGray
            $chosen = $newest
        }
    }

    [pscustomobject]@{
        Path    = $chosen.installationPath
        Name    = $chosen.displayName
        Version = $chosen.installationVersion
    }
}

function Import-MsvcEnvironment {
    param([string] $VsPath, [string] $Architecture)

    $vcvarsall = Join-Path $VsPath 'VC\Auxiliary\Build\vcvarsall.bat'
    if (-not (Test-Path $vcvarsall)) {
        throw "vcvarsall.bat not found under $VsPath"
    }

    $hostArch = if ([Environment]::Is64BitOperatingSystem) { 'x64' } else { 'x86' }
    $vcArch = if ($hostArch -eq $Architecture) { $Architecture } else { "${hostArch}_${Architecture}" }

    Write-Host "  MSVC environment: $vcArch" -ForegroundColor DarkGray

    $output = & "$env:COMSPEC" /s /c "`"$vcvarsall`" $vcArch >nul 2>&1 && set"
    if ($LASTEXITCODE -ne 0) {
        throw "vcvarsall.bat $vcArch failed. Is the $Architecture toolset installed in $VsPath?"
    }

    foreach ($line in $output) {
        if ($line -match '^([^=]+)=(.*)$') {
            Set-Item -Path "env:$($Matches[1])" -Value $Matches[2]
        }
    }
}

$MinimumCMake = [version]'3.24'

function Get-CMakeVersion {
    param([string] $Exe)
    $line = & $Exe --version 2>$null | Select-Object -First 1
    if ($line -match '(\d+)\.(\d+)\.(\d+)') {
        return [version]"$($Matches[1]).$($Matches[2]).$($Matches[3])"
    }
    return $null
}

function Find-CMake {
    $candidates = @()
    foreach ($install in Get-VisualStudioInstalls) {
        $candidates += Join-Path $install.installationPath `
            'Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe'
    }
    $candidates += (Join-Path $env:ProgramFiles 'CMake\bin\cmake.exe')
    $onPath = Get-Command cmake -ErrorAction SilentlyContinue
    if ($onPath) { $candidates += $onPath.Source }

    $best = $null
    foreach ($candidate in ($candidates | Select-Object -Unique)) {
        if (-not (Test-Path $candidate)) { continue }
        $version = Get-CMakeVersion $candidate
        if (-not $version) { continue }
        if ($version -lt $MinimumCMake) {
            Write-Verbose "skipping cmake $version at $candidate (need >= $MinimumCMake)"
            continue
        }
        if (-not $best -or $version -gt $best.Version) {
            $best = [pscustomobject]@{ Path = $candidate; Version = $version }
        }
    }

    if (-not $best) {
        throw ("No CMake >= $MinimumCMake found. Install the 'C++ CMake tools for Windows' " +
               "component from a recent Visual Studio, or CMake itself.")
    }
    return $best
}

function Find-Ninja {
    $candidates = @()
    foreach ($install in Get-VisualStudioInstalls) {
        $candidates += Join-Path $install.installationPath `
            'Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja\ninja.exe'
    }
    $onPath = Get-Command ninja -ErrorAction SilentlyContinue
    if ($onPath) { $candidates += $onPath.Source }

    foreach ($candidate in ($candidates | Select-Object -Unique)) {
        if (Test-Path $candidate) { return $candidate }
    }
    throw "ninja not found. Install the 'C++ CMake tools for Windows' component."
}

Write-Host ""
Write-Host "uACPI-NT: $Target / $Arch / $Config" -ForegroundColor Cyan

$vs = Select-VisualStudio -Preference $VsVersion
Write-Host "  Visual Studio:    $($vs.Name) $($vs.Version)" -ForegroundColor DarkGray
Write-Host "                    $($vs.Path)" -ForegroundColor DarkGray

Import-MsvcEnvironment -VsPath $vs.Path -Architecture $Arch

$cl = Get-Command cl.exe -ErrorAction SilentlyContinue
if (-not $cl) { throw "cl.exe is not on PATH after importing the MSVC environment." }
Write-Host "  compiler:         $($cl.Source)" -ForegroundColor DarkGray

$cmake = Find-CMake
$ninja = Find-Ninja

Write-Host "  cmake (driver):   $($cmake.Path) ($($cmake.Version))" -ForegroundColor DarkGray
Write-Host "  ninja:            $ninja" -ForegroundColor DarkGray

$buildDir = Join-Path $RepoRoot "build\$Target-$Arch-$($Config.ToLower())"

if ($Clean -and (Test-Path $buildDir)) {
    Write-Host "  cleaning $buildDir" -ForegroundColor DarkGray
    Remove-Item -Recurse -Force $buildDir
}

$cache = Join-Path $buildDir 'CMakeCache.txt'
if (Test-Path $cache) {
    $cached = (Select-String -Path $cache -Pattern '^CMAKE_C_COMPILER:' |
               Select-Object -First 1).Line -replace '^[^=]*=', ''
    if ($cached -and ($cached -replace '\\','/') -ne ($cl.Source -replace '\\','/')) {
        Write-Host "  toolchain changed since this tree was configured; reconfiguring" -ForegroundColor Yellow
        Write-Host "    was: $cached" -ForegroundColor DarkGray
        Remove-Item -Recurse -Force $buildDir
    }
}

$configureArgs = @(
    '-S', $RepoRoot
    '-B', $buildDir
    '-G', 'Ninja'
    "-DCMAKE_MAKE_PROGRAM=$ninja"
    "-DCMAKE_BUILD_TYPE=$Config"
    "-DNT_TARGET=$Target"
    "-DWDK_ARCH=$Arch"
)
if ($CMakeArgs) { $configureArgs += $CMakeArgs }

& $cmake.Path @configureArgs
if ($LASTEXITCODE -ne 0) { throw "Configure failed for $Target/$Arch." }

& $cmake.Path --build $buildDir
if ($LASTEXITCODE -ne 0) { throw "Build failed for $Target/$Arch." }

Write-Host ""
Write-Host "Built ${Target}/${Arch}/${Config}:" -ForegroundColor Green
Get-ChildItem -Path (Join-Path $buildDir 'bin') -Filter *.sys -ErrorAction SilentlyContinue |
    ForEach-Object { "  {0,-16} {1,8:N0} bytes" -f $_.Name, $_.Length }
Write-Host ""
