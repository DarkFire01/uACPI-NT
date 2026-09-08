<#
.SYNOPSIS
    Build uACPI-NT for Windows Vista SP1.

.EXAMPLE
    .\build-vistasp1.ps1
    .\build-vistasp1.ps1 -Arch x86
    .\build-vistasp1.ps1 -Config Release -Clean
#>
[CmdletBinding()]
param(
    [ValidateSet('x64','x86','arm64')]
    [string] $Arch = 'x64',

    [ValidateSet('Debug','Release')]
    [string] $Config = 'Debug',

    [string] $VsVersion = '2019',

    [switch] $Clean,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $CMakeArgs
)

$Forward = @($CMakeArgs | Where-Object { -not [string]::IsNullOrEmpty($_) })

& (Join-Path $PSScriptRoot 'build.ps1') `
    -Target vistasp1 -Arch $Arch -Config $Config -VsVersion $VsVersion -Clean:$Clean @Forward
exit $LASTEXITCODE
