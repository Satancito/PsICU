Import-Module -Name "$PSScriptRoot/submodules/PsCoreFxs/Z-PsCoreFxs.ps1" -Force -NoClobber

# MARK: █ Constants
$__PSICU_GITHUB_URL = "https://github.com/Satancito/PsICU.git"; $null = $__PSICU_GITHUB_URL
$__PSICU_TEMP_DIR = "$(Get-UserHome)/.PsIcu"; $null = $__PSICU_TEMP_DIR
$__PSICU_ICU_VERSION = "76.1" # █> Update on next version
$__PSICU_ICU_DOWNLOAD_SHA1 = "8E3CA391A26F27C843EE03E4B11B220003886D5B"; # █> Update on next version
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

$__PSICU_ICU_PLATFORM_DIST_DIR_NAME_FORMAT = @{
    Emscripten     = "ICU-$__PSICU_ICU_VERSION-Esmcripten-Wasm-{0}" # 0=Configuration
    Android        = "ICU-$__PSICU_ICU_VERSION-Android-Api{0}-{1}-{2}" # 0=ApiLevel / 1=Abi / 2=Configuration
    WindowsDesktop = "ICU-$__PSICU_ICU_VERSION-Windows-Desktop-{0}-{1}" # 0=Architecture / 1=Configuration
    WindowsUWP     = "ICU-$__PSICU_ICU_VERSION-Windows-UWP-{0}-{1}" # 0=Architecture / 1=Configuration
}

# MARK: █ Hosts build configurations
$__PSICU_HOST_BUILD_CONFIGURATIONS = [ordered]@{
    Debug   = [ordered]@{
        Name                = $__PSCOREFXS_DEBUG_CONFIGURATION
        CurrentWorkingDir   = "$__PSICU_ICU_SOURCE_DIR/Bin/Debug/Host"
        ConfigurationOption = @("--enable-debug")
        Options             = @("--enable-static=yes", "--enable-shared=yes")
    }
    Release = [ordered]@{
        Name                = $__PSCOREFXS_RELEASE_CONFIGURATION
        CurrentWorkingDir   = "$__PSICU_ICU_SOURCE_DIR/Bin/Release/Host"
        ConfigurationOption = @()
        Options             = @("--enable-static=yes", "--enable-shared=yes")
    }
}; $null = $__PSICU_HOST_BUILD_CONFIGURATIONS

# MARK: █ Android build configurations
$__PSICU_ANDROID_BUILD_CONFIGURATIONS = [ordered]@{
    "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.NameDebug)"     = [ordered]@{ 
        Name                = $__PSCOREFXS_DEBUG_CONFIGURATION
        AbiName             = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.Name)"
        Abi                 = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.Abi)"
        Triplet             = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.Triplet)"
        Options             = @("--enable-static=yes", "--enable-shared=yes")
        ConfigurationOption = @("--enable-debug")
        CurrentWorkingDir   = "$__PSICU_ICU_SOURCE_DIR/Bin/Debug/Android-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.Name)"
        DistDirName         = $__PSICU_ICU_PLATFORM_DIST_DIR_NAME_FORMAT.Android -f @("{0}", "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.Name)", $__PSCOREFXS_DEBUG_CONFIGURATION)
    }
    "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.NameDebug)"   = [ordered]@{ 
        Name                = $__PSCOREFXS_DEBUG_CONFIGURATION
        AbiName             = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.Name)"
        Abi                 = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.Abi)"
        Triplet             = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.Triplet)"
        Options             = @("--enable-static=yes", "--enable-shared=yes")
        ConfigurationOption = @("--enable-debug")
        CurrentWorkingDir   = "$__PSICU_ICU_SOURCE_DIR/Bin/Debug/Android-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.Name)"
        DistDirName         = $__PSICU_ICU_PLATFORM_DIST_DIR_NAME_FORMAT.Android -f @("{0}", "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.Name)", $__PSCOREFXS_DEBUG_CONFIGURATION)
    }
    "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.NameDebug)"     = [ordered]@{ 
        Name                = $__PSCOREFXS_DEBUG_CONFIGURATION
        AbiName             = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.Name)"
        Abi                 = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.Abi)"
        Triplet             = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.Triplet)"
        Options             = @("--enable-static=yes", "--enable-shared=yes")
        ConfigurationOption = @("--enable-debug")
        CurrentWorkingDir   = "$__PSICU_ICU_SOURCE_DIR/Bin/Debug/Android-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.Name)"
        DistDirName         = $__PSICU_ICU_PLATFORM_DIST_DIR_NAME_FORMAT.Android -f @("{0}", "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.Name)", $__PSCOREFXS_DEBUG_CONFIGURATION)
    }
    "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.NameDebug)"     = [ordered]@{ 
        Name                = $__PSCOREFXS_DEBUG_CONFIGURATION
        AbiName             = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.Name)"
        Abi                 = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.Abi)"
        Triplet             = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.Triplet)"
        Options             = @("--enable-static=yes", "--enable-shared=yes")
        ConfigurationOption = @("--enable-debug")
        CurrentWorkingDir   = "$__PSICU_ICU_SOURCE_DIR/Bin/Debug/Android-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.Name)"
        DistDirName         = $__PSICU_ICU_PLATFORM_DIST_DIR_NAME_FORMAT.Android -f @("{0}", "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.Name)", $__PSCOREFXS_DEBUG_CONFIGURATION)
    }

    "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.NameRelease)"   = [ordered]@{ 
        Name                = $__PSCOREFXS_RELEASE_CONFIGURATION
        AbiName             = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.Name)"
        Abi                 = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.Abi)"
        Triplet             = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.Triplet)"
        Options             = @("--enable-static=yes", "--enable-shared=yes")
        ConfigurationOption = @()
        CurrentWorkingDir   = "$__PSICU_ICU_SOURCE_DIR/Bin/Release/Android-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.Name)"
        DistDirName         = $__PSICU_ICU_PLATFORM_DIST_DIR_NAME_FORMAT.Android -f @("{0}", "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm.Name)", $__PSCOREFXS_RELEASE_CONFIGURATION)
    }
    "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.NameRelease)" = [ordered]@{ 
        Name                = $__PSCOREFXS_RELEASE_CONFIGURATION
        AbiName             = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.Name)"
        Abi                 = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.Abi)"
        Triplet             = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.Triplet)" 
        Options             = @("--enable-static=yes", "--enable-shared=yes")
        ConfigurationOption = @()
        CurrentWorkingDir   = "$__PSICU_ICU_SOURCE_DIR/Bin/Release/Android-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.Name)"
        DistDirName         = $__PSICU_ICU_PLATFORM_DIST_DIR_NAME_FORMAT.Android -f @("{0}", "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.Arm64.Name)", $__PSCOREFXS_RELEASE_CONFIGURATION)
    }
    "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.NameRelease)"   = [ordered]@{ 
        Name                = $__PSCOREFXS_RELEASE_CONFIGURATION
        AbiName             = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.Name)"
        Abi                 = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.Abi)"
        Triplet             = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.Triplet)"
        Options             = @("--enable-static=yes", "--enable-shared=yes")
        ConfigurationOption = @()
        CurrentWorkingDir   = "$__PSICU_ICU_SOURCE_DIR/Bin/Release/Android-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.Name)"
        DistDirName         = $__PSICU_ICU_PLATFORM_DIST_DIR_NAME_FORMAT.Android -f @("{0}", "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X86.Name)", $__PSCOREFXS_RELEASE_CONFIGURATION)
    }
    "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.NameRelease)"   = [ordered]@{ 
        Name                = $__PSCOREFXS_RELEASE_CONFIGURATION
        AbiName             = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.Name)"
        Abi                 = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.Abi)"
        Triplet             = "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.Triplet)"
        Options             = @("--enable-static=yes", "--enable-shared=yes")
        ConfigurationOption = @()
        CurrentWorkingDir   = "$__PSICU_ICU_SOURCE_DIR/Bin/Release/Android-$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.Name)"
        DistDirName         = $__PSICU_ICU_PLATFORM_DIST_DIR_NAME_FORMAT.Android -f @("{0}", "$($__PSCOREFXS_ANDROIDNDK_ANDROID_ABI_CONFIGURATIONS.X64.Name)", $__PSCOREFXS_RELEASE_CONFIGURATION)
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
    if ($IsWindows -and $RemoveWsl.IsPresent) {
        $scriptParameters = @{
            "Script" = (Get-WslPath -Path "$PSCommandPath")
        }
        & wsl pwsh -Command {
            Write-Host "Removing in WSL."
            $params = $args[0]
            Write-Host "Wsl User: " -NoNewline ; & whoami
            Import-Module -Name "$($params.Script)" -Force -NoClobber
            Remove-PsIcu
        } -args $scriptParameters
    }
}
