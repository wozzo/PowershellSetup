Import-Module .\wozzo-utility.psm1

# Names of the User Environment Variables that control this environments packages
$setupEnvironmentVarName = "WozzoEnvironment"
$devEnvironmentVarName = "WozzoDev"
$homeEnvironmentVarName = "WozzoHome"
$workEnvironmentVarName = "WozzoWork"

# File locations
$corePackages = "core.txt"
$homeOnlyPackages = "home-only.txt"
$workOnlyPackages = "work-only.txt"
$devOnlyPackages = "dev-only.txt"

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
    [System.Environment]::SetEnvironmentVariable($devEnvironmentVarName, $devEnvironment, "User")
    [System.Environment]::SetEnvironmentVariable($homeEnvironmentVarName, $homeEnvironment, "User")
    [System.Environment]::SetEnvironmentVariable($workEnvironmentVarName, $workEnvironment, "User")
}
Export-ModuleMember -Function Set-WozzoEnvironment

<#
 .Synopsis
  Gets the names of the packages from a text file

 .Description
  Gets the names of the packages from a text file

 .Parameter path
  The path to the file to open

 .Example
   # Show a prompt asking if the user likes cheese with a default of yes
   Get-PackageNames ".\packages.txt"
#>
function Get-PackageNames {
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $path
    )

    $packages = import-csv $path -Header "Packages"
    return $packages
}

<#
 .Synopsis
  Gets the list of packages to be managed by chocolatey

 .Description
  Uses environment variables to determine what packages to manage with chocolatey

 .Example
   # Get a list of packages to be managed by chocolatey
   Get-PackagesForChocolatey
#>
function Get-PackagesForChocolatey {
    $installDevOnly = [System.Environment]::GetEnvironmentVariable($devEnvironmentVarName, "User")
    $installHomeOnly = [System.Environment]::GetEnvironmentVariable($homeEnvironmentVarName, "User")
    $installWorkOnly = [System.Environment]::GetEnvironmentVariable($workEnvironmentVarName, "User")

    $packages = Get-PackageNames $corePackages
    if ($installDevOnly -eq $true) {
        $packages = $packages + (Get-PackageNames $devOnlyPackages)
    }
    if ($installHomeOnly -eq $true) {
        $packages = $packages + (Get-PackageNames $homeOnlyPackages)
    }
    if ($installWorkOnly -eq $true) {
        $packages = $packages + (Get-PackageNames $workOnlyPackages)
    }
    
    return $packages
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
    foreach ($package in $packages)
    {
        choco install $package -y
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

    Setup-WozzoEnvironment
    Install-Chocolatey
    Install-ChocolateyPackages
}

<#
 .Synopsis
  Use chocolatey to update the packages for this environment

 .Description
  Use chocolatey to update the packages for this environment

 .Example
   # Update the packages for this environment using chocolatey
   Update-ChocolateyPackages
#>
function Update-ChocolateyPackages {
    choco upgrade chocolatey

    $packages = Get-PackagesForChocolatey
    foreach ($package in $packages)
    {
        choco upgrade $package -y
    }
}
Export-ModuleMember -Function Update-ChocolateyPackages

<#
 .Synopsis
  Add a package to a list of those managed by chocolatey

 .Description
  Add a package to a list of those managed by chocolatey. Default adds to core, but switches control adding to other environments

  .Parameter packageName
  Name of the chocolatey package to add to the list

  .Parameter devOnly
  Add the package to the dev only list

  .Parameter homeOnly
  Add the package to the home only list

  .Parameter workOnly
  Add the package to the work only list

 .Example
   # Add the google chrome package to a list of those managed by chocolatey
   Add-Package googlechrome 

   # Add the google chrome package to the dev only list for those managed by chocolatey
   Add-Package googlechrome -devOnly
#>
function Add-Package {
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $packageName,
        [switch]
        $devOnly,
        [switch]
        $homeOnly,
        [switch]
        $workOnly
    )

    $packageText = "`n$packageName"

    if ($devOnly -eq $true)
    {
        Add-Content $devOnlyPackages $packageText
        return
    }

    if ($homeOnly -eq $true)
    {
        Add-Content $homeOnlyPackages $packageText
        return
    }

    if ($workOnly -eq $true)
    {
        Add-Content $workOnlyPackages $packageText
        return
    }

    Add-Content $corePackages $packageText
}
Export-ModuleMember -Function Add-Package


# Check if chocolatey is installed
if (Get-Command choco.exe -ErrorAction SilentlyContinue) {
} else {
    # Install Chocolatey
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

# Check if first run has been run
if ([System.Environment]::GetEnvironmentVariable($setupEnvironmentVarName, "User") -ne $true) {
    Install-FirstRun
}