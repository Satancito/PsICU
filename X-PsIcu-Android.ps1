[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $AndroidAPI,

    [string]
    $DestinationDir = [string]::Empty,

    [switch]
    $ForceDownloadNDK,

    [switch]
    $ForceDownloadICU
)

Import-Module -Name "$PSScriptRoot/Z-PsIcu.ps1" -Force -NoClobber
if([string]::IsNullOrWhiteSpace($AndroidAPI))
{
    $AndroidAPI = [AndroidND]
}