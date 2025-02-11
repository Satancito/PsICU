[CmdletBinding()]
param (
    [Parameter(ParameterSetName = "Build_Lib")]
    [string]
    $AndroidAPI = [string]::Empty,

    [Parameter(ParameterSetName = "Build_Lib")]
    [string]
    $DestinationDir = [string]::Empty,

    [Parameter(ParameterSetName = "Build_Lib")]
    [string]
    $DistDirSuffix = [string]::Empty,

    [Parameter(ParameterSetName = "Build_Lib")]
    [switch]
    $ForceDownloadNDK,

    [Parameter(ParameterSetName = "Build_Lib")]
    [switch]
    $ForceDownloadICU,

    [Parameter(ParameterSetName = "Build_Lib")]
    [string[]]
    $IcuConfigureOptions = @() ,

    [Parameter(Mandatory = $true, ParameterSetName = "Remove_Temp")]
    [switch]
    $Clean
)

Import-Module -Name "$PSScriptRoot/Z-PsIcu.ps1" -Force -NoClobber

function Test-WindowsDependencyTools {
    Write-Host
    Write-InfoBlue "PsIcu - Android - Test Windows dependency tools..."
    Assert-7ZipExecutable
    Assert-WslExecutable
}

function Test-DependencyTools {
    Write-InfoBlue "PsIcu - Android - Test dependency tools..."
    Write-Host
    Assert-MakeExecutable
    Assert-UnzipExecutable
}


function Build-IcuLibrary {
    $AndroidAPI = $AndroidAPI = Get-ValidAndroidNDKApi -Api $AndroidAPI -Latest -Assert
    
    $DestinationDir = [string]::IsNullOrWhiteSpace($DestinationDir) ? "$(Get-CppLibsDir)" : $DestinationDir
    if ($IsWindows) {
        Test-WindowsDependencyTools
        $scriptParameters = @{
            Script           = (Get-WslPath -Path "$PSCommandPath")
            AndroidAPI       = $AndroidAPI
            DestinationDir   = (Get-WslPath -Path "$DestinationDir")
            DistDirSuffix    = $DistDirSuffix
            ForceDownloadNDK = $ForceDownloadNDK.IsPresent
            ForceDownloadICU = $ForceDownloadICU.IsPresent
        }
        Write-Warning "Incompatible platform: Windows. Using WSL."
        & wsl pwsh -Command {
            $params = $args[0]
            Write-Host "Wsl User: " -NoNewline ; & whoami
            & "$($params.Script)" `
                -AndroidAPI $params.AndroidAPI `
                -DestinationDir $params.DestinationDir `
                -DistDirSuffix $params.DistDirSuffix `
                -ForceDownloadNDK:$params.ForceDownloadNDK `
                -ForceDownloadICU:$params.ForceDownloadICU
    
        } -args $scriptParameters
        return
    }
    
    $DistDirSuffix = [string]::IsNullOrWhiteSpace($DistDirSuffix) ? [string]::Empty : "-$($DistDirSuffix)"

    Test-DependencyTools
    Install-AndroidNDK -Force:$ForceDownloadNDK
    Get-IcuSources -Force:$ForceDownloadICU

    $preprocessorFlags = "-ffunction-sections -fdata-sections -fvisibility=hidden -fno-short-wchar -fno-short-enums -DU_USING_ICU_NAMESPACE=1 -DU_HAVE_NL_LANGINFO_CODESET=0 -D__STDC_INT64__ -DU_TIMEZONE=0 -DUCONFIG_NO_LEGACY_CONVERSION=1 -DU_CHARSET_IS_UTF8=1"
    $ldFlags = "$(Get-IcuAndroidHostLdFlags)"
    $__PSICU_HOST_BUILD_CONFIGURATIONS.Keys | ForEach-Object {
        $configuration = $__PSICU_HOST_BUILD_CONFIGURATIONS["$_"]
        try {
            Write-Host
            Write-InfoBlue "█ PsIcu - Building host lib - Configuration: $($configuration.Name) - Host Platform: $(Get-IcuAndroidHostPlatform)"
            Write-Host
            $env:CFLAGS = "-fPIC"
            $env:CXXFLAGS = "-fPIC"
            $env:CPPFLAGS = "$preprocessorFlags"
            $env:LDFLAGS = "$ldFlags"
            New-Item -Path "$($configuration.CurrentWorkingDir)" -ItemType Directory -Force | Out-Null
            Push-Location "$($configuration.CurrentWorkingDir)"
            $prefix = "$($configuration.CurrentWorkingDir)/Dist"
            $null = Test-ExternalCommand -Command "sh `"$__PSICU_ICU_SOURCE_DIR/runConfigureICU`" $($configuration.ConfigurationOption) `"$(Get-IcuAndroidHostPlatform)`" --prefix=`"$prefix`" $($configuration.Options) $IcuConfigureOptions" -ThrowOnFailure -NoAssertion
            $null = Test-ExternalCommand -Command "`"$__PSCOREFXS_MAKE_EXE`" -j16" -ThrowOnFailure -NoAssertion
            Remove-Item -Path "$prefix" -Force -Recurse -ErrorAction Ignore
            $null = Test-ExternalCommand -Command "`"$__PSCOREFXS_MAKE_EXE`" install" -ThrowOnFailure -NoAssertion
        }
        finally {
            Pop-Location
        } 
    }

    $ndkProps = $__PSCOREFXS_ANDROID_NDK_OS_VARIANTS["$(Get-OsName -Minimal)"]

    $ldFlags = "-ldl -Wl,--gc-sections"
    $__PSICU_ANDROID_BUILD_CONFIGURATIONS.Keys | ForEach-Object {
        $configuration = $__PSICU_ANDROID_BUILD_CONFIGURATIONS["$_"]
        $hostConfiguration = $__PSICU_HOST_BUILD_CONFIGURATIONS["$($configuration.Name)"]
        $target = "$($configuration.Triplet)"
        $toolchainsDir = "$($ndkProps.ToolchainsDir)"

        $env:TARGET = $target
        $env:API = $AndroidAPI
        $env:AR = "$toolchainsDir/bin/llvm-ar"
        $env:CC = "$toolchainsDir/bin/$target$AndroidAPI-clang"
        $env:AS = $CC 
        $env:CXX = "$toolchainsDir/bin/$target$AndroidAPI-clang++"
        $env:LD = "$toolchainsDir/bin/ld"
        $env:RANLIB = "$toolchainsDir/bin/llvm-ranlib"
        $env:STRIP = "$toolchainsDir/bin/llvm-strip"
        $env:CPPFLAGS = $preprocessorFlags
        $env:LDFLAGS = $ldFlags
        $env:CFLAGS = "-fPIC"
        $env:CXXFLAGS = "-fPIC"

        try {
            $prefix = "$DestinationDir/$($configuration.DistDirName -f $AndroidAPI)$DistDirSuffix"
            Write-Host
            Write-InfoBlue "█ PsIcu - Building `"$prefix`""
            Write-Host
            New-Item -Path "$($configuration.CurrentWorkingDir)" -ItemType Directory -Force | Out-Null
            Push-Location "$($configuration.CurrentWorkingDir)"
            $null = Test-ExternalCommand -Command "sh `"$__PSICU_ICU_SOURCE_DIR/configure`" --host=`"$target`" --with-cross-build=`"$($hostConfiguration.CurrentWorkingDir)`" $($configuration.ConfigurationOption) --prefix=`"$prefix`" $($configuration.Options) $IcuConfigureOptions " -ThrowOnFailure -NoAssertion
            $null = Test-ExternalCommand -Command "make -j16" -ThrowOnFailure -NoAssertion
            Remove-Item -Path "$prefix" -Force -Recurse -ErrorAction Ignore
            $null = Test-ExternalCommand -Command "`"$__PSCOREFXS_MAKE_EXE`" install" -ThrowOnFailure -NoAssertion
        }
        finally {
            Pop-Location
            Remove-Item -Path "$($configuration.CurrentWorkingDir)" -Force -Recurse -ErrorAction Ignore
        }
    }   
    
    $__PSICU_HOST_BUILD_CONFIGURATIONS.Keys | ForEach-Object {
        $configuration = $__PSICU_HOST_BUILD_CONFIGURATIONS["$_"]
        Remove-Item -Path "$($configuration.CurrentWorkingDir)" -Force -Recurse -ErrorAction Ignore
    }
}


if ($Clean.IsPresent) {
    Remove-PsIcu -RemoveWsl
    exit
}

Build-IcuLibrary