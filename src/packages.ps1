# File locations
$packageListPath = Join-Path $PSScriptRoot packages

$corePackages = Join-Path $packageListPath "core.txt"
$homeOnlyPackages = Join-Path $packageListPath "home-only.txt"
$workOnlyPackages = Join-Path $packageListPath "work-only.txt"
$devOnlyPackages = Join-Path $packageListPath "dev-only.txt"

<#
 .Synopsis
  Gets the names of the packages from a text file

 .Description
  Gets the names of the packages from a text file

 .Parameter path
  The path to the file to open

 .Example
   # Get a list of each line in the text file with a header of Packages
   Get-PackageNames ".\packages.txt"
#>
function Get-PackageNames {
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $path
    )
    $packages = Get-ListItems $path "Packages"
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
    $installDevOnly = Get-IsDevEnvironment
    $installHomeOnly = Get-IsHomeEnvironment
    $installWorkOnly = Get-IsWorkEnvironment

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
