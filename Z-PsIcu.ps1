Import-Module -Name "$PSScriptRoot/submodules/PsCoreFxs/Z-PsCoreFxs.ps1" -Force -NoClobber

# MARK: █ Constants
$__PSICU_GITHUB_URL = "https://github.com/Satancito/PsICU.git"; $null = $__PSICU_GITHUB_URL
$__PSICU_TEMP_DIR = "$(Get-UserHome)/.PsIcu"; $null = $__PSICU_TEMP_DIR
$__PSICU_ICU_VERSION = "75.1" #Update on next version
$__PSICU_ICU_DOWNLOAD_SHA1 = "46619717D43E9C0D028C89EE5D9AE9263C87256E"; # Update on next version
$__PSICU_ICU_DOWNLOAD_URL = "https://github.com/unicode-org/icu/archive/refs/tags/release-$($__PSICU_ICU_VERSION.Replace(".", "-")).zip"; $null = $__PSICU_ICU_DOWNLOAD_URL
$__PSICU_ICU_DOWNLOAD_NAME = "icu-release-$($__PSICU_ICU_VERSION.Replace(".", "-")).zip"
$__PSICU_ICU_DOWNLOAD_FILENAME = "$__PSICU_TEMP_DIR/$__PSICU_ICU_DOWNLOAD_NAME"; $null = $__PSICU_ICU_DOWNLOAD_FILENAME
$__PSICU_ICU_SOURCE_DIR = "$__PSICU_TEMP_DIR/$([System.IO.Path]::GetFileNameWithoutExtension($__PSICU_ICU_DOWNLOAD_NAME))/icu4c/source"; $null = $__PSICU_ICU_SOURCE_DIR
$__PSICU_ICU_ROOT_DIR = "$__PSICU_TEMP_DIR/$([System.IO.Path]::GetFileNameWithoutExtension($__PSICU_ICU_DOWNLOAD_NAME))"; $null = $__PSICU_ICU_ROOT_DIR

function Get-IcuAndroidHostLdFlags {
    if ($IsLinux) {
        return "-Wl,--gc-sections"
    }
    if ($IsMacOS) {
        return "-Wl,-dead_strip"
    }
}

$__PSICU_HOST_BUILD_CONFIGURATIONS = [ordered]@{
    Debug   = [ordered]@{
        Name                   = "Debug"
        CurrentWorkingDir      = "$__PSICU_ICU_SOURCE_DIR/Bin/Debug/Host"
        ConfigurationOption         = @("--enable-debug")
        Options = @("--enable-static=yes", "--enable-shared=yes")
    }
    Release = [ordered]@{
        Name                   = "Release"
        CurrentWorkingDir      = "$__PSICU_ICU_SOURCE_DIR/Bin/Release/Host"
        ConfigurationOption         = @()
        Options = @("--enable-static=yes", "--enable-shared=yes")

    }
}; $null = $__PSICU_HOST_BUILD_CONFIGURATIONS

# MARK: █ Android build configurations
$__PSICU_ANDROID_BUILD_CONFIGURATIONS = [ordered]@{
    "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.Name)-Debug"     = @{ 
        Name              = "Debug"
        AbiName           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.Name)"
        Abi               = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.Abi)"
        Triplet           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.Triplet)"
        Options           = @("--enable-static=yes", "--enable-shared=yes")
        ConfigurationOption    = @("--enable-debug")
        CurrentWorkingDir = "$__PSICU_ICU_SOURCE_DIR/Bin/Debug/Android-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.Name)"
        DistDirName       = "ICU-$__PSICU_ICU_VERSION-Android-Api{0}-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.Name)-Debug"     
    }
    "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.Name)-Debug"   = @{ 
        Name              = "Debug"
        AbiName           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.Name)"
        Abi               = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.Abi)"
        Triplet           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.Triplet)"
        Options           = @("--enable-static=yes", "--enable-shared=yes")
        ConfigurationOption    = @("--enable-debug")
        CurrentWorkingDir = "$__PSICU_ICU_SOURCE_DIR/Bin/Debug/Android-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.Name)"
        DistDirName       = "ICU-$__PSICU_ICU_VERSION-Android-Api{0}-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.Name)-Debug"     
    }
    "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.Name)-Debug"     = @{ 
        Name              = "Debug"
        AbiName           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.Name)"
        Abi               = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.Abi)"
        Triplet           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.Triplet)"
        Options           = @("--enable-static=yes", "--enable-shared=yes")
        ConfigurationOption    = @("--enable-debug")
        CurrentWorkingDir = "$__PSICU_ICU_SOURCE_DIR/Bin/Debug/Android-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.Name)"
        DistDirName       = "ICU-$__PSICU_ICU_VERSION-Android-Api{0}-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.Name)-Debug"   
    }
    "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.Name)-Debug"     = @{ 
        Name              = "Debug"
        AbiName           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.Name)"
        Abi               = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.Abi)"
        Triplet           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.Triplet)"
        Options           = @("--enable-static=yes", "--enable-shared=yes")
        ConfigurationOption    = @("--enable-debug")
        CurrentWorkingDir = "$__PSICU_ICU_SOURCE_DIR/Bin/Debug/Android-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.Name)"
        DistDirName       = "ICU-$__PSICU_ICU_VERSION-Android-Api{0}-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.Name)-Debug"   
    }

    "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.Name)-Release"   = @{ 
        Name              = "Release"
        AbiName           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.Name)"
        Abi               = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.Abi)"
        Triplet           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.Triplet)"
        Options           = @("--enable-static=yes", "--enable-shared=yes")
        ConfigurationOption    = @()
        CurrentWorkingDir = "$__PSICU_ICU_SOURCE_DIR/Bin/Release/Android-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.Name)"
        DistDirName       = "ICU-$__PSICU_ICU_VERSION-Android-Api{0}-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.Name)-Release"
    }
    "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.Name)-Release" = @{ 
        Name              = "Release"
        AbiName           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.Name)"
        Abi               = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.Abi)"
        Triplet           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.Triplet)" 
        Options           = @("--enable-static=yes", "--enable-shared=yes")
        ConfigurationOption    = @()
        CurrentWorkingDir = "$__PSICU_ICU_SOURCE_DIR/Bin/Release/Android-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.Name)"
        DistDirName       = "ICU-$__PSICU_ICU_VERSION-Android-Api{0}-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.Name)-Release" 
    }
    "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.Name)-Release"   = @{ 
        Name              = "Release"
        AbiName           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.Name)"
        Abi               = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.Abi)"
        Triplet           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.Triplet)"
        Options           = @("--enable-static=yes", "--enable-shared=yes")
        ConfigurationOption    = @()
        CurrentWorkingDir = "$__PSICU_ICU_SOURCE_DIR/Bin/Release/Android-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.Name)"
        DistDirName       = "ICU-$__PSICU_ICU_VERSION-Android-Api{0}-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.Name)-Release" 
    }
    "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.Name)-Release"   = @{ 
        Name              = "Release"
        AbiName           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.Name)"
        Abi               = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.Abi)"
        Triplet           = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.Triplet)"
        Options           = @("--enable-static=yes", "--enable-shared=yes")
        ConfigurationOption    = @()
        CurrentWorkingDir = "$__PSICU_ICU_SOURCE_DIR/Bin/Release/Android-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.Name)"
        DistDirName       = "ICU-$__PSICU_ICU_VERSION-Android-Api{0}-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.Name)-Release"  
    }
}; $null = $__PSICU_ANDROID_BUILD_CONFIGURATIONS

# MARK: █ Functions

function Get-IcuAndroidHostPlatform {
    if ($IsLinux) {
        return "Linux"
    }
    if ($IsMacOS) {
        return "MacOSX/GCC"
    }
}
function Get-IcuSources {
    [CmdletBinding()]
    param (
        [Parameter()]
        [switch]
        $Force
    )
    Invoke-HttpDownload -Url "$__PSICU_ICU_DOWNLOAD_URL" -DestinationPath "$__PSICU_TEMP_DIR"  -Name "$__PSICU_ICU_DOWNLOAD_NAME" -Force:$Force -HashAlgorithm "SHA1" -Hash "$__PSICU_ICU_DOWNLOAD_SHA1"
    $rootDirExists = $(Test-Path -Path "$($__PSICU_ICU_ROOT_DIR)" -PathType Container)
    if (!$rootDirExists -or $Force.IsPresent) {
        Expand-ZipArchive -Path "$($__PSICU_ICU_DOWNLOAD_FILENAME)" -DestinationPath "$__PSICU_TEMP_DIR"
    }
}

function Remove-PsIcu {
    [CmdletBinding()]
    param (
        [Parameter()]
        [switch]
        $RemoveWsl
    )
    Write-InfoBlue "Removing PsIcu"
    Write-Host "$__PSICU_TEMP_DIR"
    Remove-Item -Path "$__PSICU_TEMP_DIR" -Force -Recurse -ErrorAction Ignore
    if($IsWindows -and $RemoveWsl.IsPresent)
    {
        $scriptParameters = @{
            "Script" = (Get-WslPath -Path "$PSCommandPath")
        }
        Write-Host "Removing in WSL."
        & wsl pwsh -Command {
            $params = $args[0]
            Write-Host "Wsl User: " -NoNewline ; & whoami
            Import-Module -Name "$($params.Script)" -Force -NoClobber
            Remove-PsIcu
        } -args $scriptParameters
    }
}



