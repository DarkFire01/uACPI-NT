<#
.SYNOPSIS
    Build uACPI-NT across every NTDDI target and architecture.

.EXAMPLE
    .\build-all.ps1
    .\build-all.ps1 -Arch all
    .\build-all.ps1 -Arch x64,x86 -Config Release
    .\build-all.ps1 -Targets win7,win10,win11 -Arch all
#>
[CmdletBinding()]
param(
    [string[]] $Arch = @('x64'),

    [ValidateSet('Debug','Release')]
    [string] $Config = 'Debug',

    [string] $VsVersion = '2019',

    [switch] $Clean,

    [string[]] $Targets = @('ws03','vista','vistasp1','vistasp2',
                            'win7','win8','winblue','win10','win10_ni','win11')
)

$ErrorActionPreference = 'Continue'

$ArchList = @($Arch)
if ($ArchList.Count -eq 1 -and $ArchList[0] -eq 'all') {
    $ArchList = @('x64','x86','arm64')
}
foreach ($candidate in $ArchList) {
    if ($candidate -notin @('x64','x86','arm64')) {
        throw "Unknown architecture '$candidate'. Use x64, x86, arm64, or 'all'."
    }
}

$build = Join-Path $PSScriptRoot 'build.ps1'
$results = @()

foreach ($currentArch in $ArchList) {
    foreach ($target in $Targets) {
        $started = Get-Date

        $argv = @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $build
            '-Target', $target, '-Arch', $currentArch, '-Config', $Config
            '-VsVersion', $VsVersion
        )
        if ($Clean) { $argv += '-Clean' }

        & powershell.exe @argv
        $ok = ($LASTEXITCODE -eq 0)

        $results += [pscustomobject]@{
            Target  = $target
            Arch    = $currentArch
            Result  = if ($ok) { 'ok' } else { 'FAILED' }
            Seconds = [int]((Get-Date) - $started).TotalSeconds
        }
    }
}

Write-Host ""
Write-Host "Summary ($Config, VS $VsVersion)" -ForegroundColor Cyan

# One row per target, one column per architecture.
$table = foreach ($group in ($results | Group-Object Target)) {
    $row = [ordered]@{ Target = $group.Name }
    foreach ($currentArch in $ArchList) {
        $hit = $group.Group | Where-Object { $_.Arch -eq $currentArch }
        $row[$currentArch] = if ($hit) { $hit.Result } else { '-' }
    }
    [pscustomobject]$row
}
$table | Format-Table -AutoSize

$failed = @($results | Where-Object { $_.Result -ne 'ok' }).Count
if ($failed -eq 0) {
    Write-Host "All $($results.Count) combinations built." -ForegroundColor Green
} else {
    Write-Host "$failed of $($results.Count) combinations failed." -ForegroundColor Red
    $results | Where-Object { $_.Result -ne 'ok' } |
        ForEach-Object { "  $($_.Target)/$($_.Arch)" }
}
exit $failed
