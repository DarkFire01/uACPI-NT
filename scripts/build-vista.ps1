<#
.SYNOPSIS
    Build uACPI-NT for Windows Vista.

.EXAMPLE
    .\build-vista.ps1
    .\build-vista.ps1 -Arch x86
    .\build-vista.ps1 -Config Release -Clean
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
    -Target vista -Arch $Arch -Config $Config -VsVersion $VsVersion -Clean:$Clean @Forward
exit $LASTEXITCODE
