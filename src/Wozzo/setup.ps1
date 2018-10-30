# Names of the User Environment Variables that control this environments packages
$setupEnvironmentVarName = "WozzoEnvironment"
$devEnvironmentVarName = "WozzoDev"
$homeEnvironmentVarName = "WozzoHome"
$workEnvironmentVarName = "WozzoWork"

function Get-IsDevEnvironment {
    $result = [System.Environment]::GetEnvironmentVariable($devEnvironmentVarName, "User")
    return $result -eq $true
}

function Set-IsDevEnvironment {
    param (
        [bool]
        $value
    )
    [System.Environment]::SetEnvironmentVariable($devEnvironmentVarName, $value, "User")
}

function Get-IsHomeEnvironment {
    $result = [System.Environment]::GetEnvironmentVariable($homeEnvironmentVarName, "User")
    return $result -eq $true
}
function Set-IsHomeEnvironment {
    param (
        [bool]
        $value
    )
    [System.Environment]::SetEnvironmentVariable($homeEnvironmentVarName, $value, "User")
}

function Get-IsWorkEnvironment {
    $result = [System.Environment]::GetEnvironmentVariable($workEnvironmentVarName, "User")
    return $result -eq $true
}

function Set-IsWorkEnvironment {
    param (
        [bool]
        $value
    )
    [System.Environment]::SetEnvironmentVariable($workEnvironmentVarName, $value, "User")
}

function Get-IsChocolateyInstalled {
    if (Get-Command choco.exe -ErrorAction SilentlyContinue) {
        return $true
    }
    return $false
}

<#
 .Synopsis
  Sets up environment variables for selecting packages to install

 .Description
  Sets user environment variables with a Wozzo prefix for determining if this machine is a dev/work/home machine

 .Example
   # Prompts the user and sets the relevant environment variable
   Set-WozzoEnvironment
#>
function Set-WozzoEnvironment {
    $devEnvironment = Read-Confirmation "Will this machine be used for software development?"
    $homeEnvironment = Read-Confirmation "Will this machine be used in a home environment?"
    $workEnvironment = Read-Confirmation "Will this machine be used in a work environment?"

    [System.Environment]::SetEnvironmentVariable($setupEnvironmentVarName, $true, "User")
    Set-IsDevEnvironment $devEnvironment
    Set-IsHomeEnvironment $homeEnvironment
    Set-IsWorkEnvironment $workEnvironment
}

<#
 .Synopsis
  Use chocolatey to install the packages for this environment

 .Description
  Use chocolatey to install the packages for this environment

 .Example
   # Install the packages for this environment using chocolatey
   Install-ChocolateyPackages
#>
function Install-ChocolateyPackages {
    $packages = Get-PackagesForChocolatey
    Write-Host "Found $($packages.Length) packages to install"
    $packagesToPin = Get-PackagesToPin
    foreach ($package in $packages) {
        $package = $package.Packages
        Write-Host "Installing $package"
        choco install $package -y

        if ($packagesToPin.Contains($package)) {
            Add-PackagePin $package
        }
    }
}

<#
 .Synopsis
  Set up the machine for first use

 .Description
  Set up the machine for first use. Sets environment variables and installs packages

 .Example
   # Set up the environment for first use
   Install-FirstRun
#>
function Install-FirstRun {
    # Scripts downloaded must be signed by a trusted publisher before they can be run
    Set-ExecutionPolicy RemoteSigned

    Set-WozzoEnvironment
    
    $installPackages = Read-Confirmation "Would you like to install the packages for this environment now?"
    if ($installPackages) {
        Install-ChocolateyPackages
    } else {
        Write-Host "You can trigger the install by running the 'Install-ChocolateyPackages' command"
    }
}

# Check if chocolatey is installed
if ((Get-IsChocolateyInstalled) -ne $true) {
    Write-Host "Chocolatey is not installed. Starting install now"
    # Install Chocolatey
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    Write-Host "Chocolatey has been installed"

    if ((Get-IsChocolateyInstalled) -ne $true) {
        Write-Host "Chocolatey has been installed but is not available in the shell. Restart Powershell and try to import this module again"
        return
    }
}

# Check if first run has been run
if ([System.Environment]::GetEnvironmentVariable($setupEnvironmentVarName, "User") -ne $true) {
    Write-Host "Environment variables not set. Starting first run install of environment"
    Install-FirstRun
}