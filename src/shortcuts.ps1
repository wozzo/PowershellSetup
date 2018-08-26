<#
 .Synopsis
  Starts Visual Studio Code

 .Description
  Starts Visual Studio Code - Checks for local user install then machine install

 .Example
   # Start Visual Studio Code
   Start-VSCode

   # Start Visual Studio Code opening the file specified
   Start-VSCode C:\temp\test.txt
#>
function Start-VSCode {
    $paths = @(
        (Join-Path ([Environment]::GetFolderPath("LocalApplicationData")) "Programs"),
        [Environment]::GetFolderPath("ProgramFiles")
    )
    
    foreach ($path in $paths) {
        $vscPath = Join-Path $path "Microsoft VS Code\code.exe"
        if (Test-Path $vscPath) {
            &"$vscPath" $args
            return
        }
    }
    Write-Warning "Unable to find VSCode on this computer"
}
Set-Alias vsc Start-VSCode

<#
 .Synopsis
  Pins a chocolatey package

 .Description
  Pins a chocolatey package so that it is skipped during upgrades. Adds it to the list of packages to be pinned on install

 .Parameter package
  Name of the package to pin

 .Example
   # Pins the package and adds it to the pinned packages list
   Add-PackagePin
#>
function Add-PackagePin {
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $package
    )
    choco pin add -n=$package
    Add-PackagePinToFile $package
}
Set-Alias pin Add-PackagePin

Set-Alias build .\build.ps1
Set-Alias cake .\build.ps1