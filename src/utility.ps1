<#
 .Synopsis
  Prompts the user for yes/no confirmation

 .Description
  Displays the message as a prompt for the user expecting a yes/no response

 .Parameter message
  The text to display to the user. Usually takes the form of a yes/no question

 .Parameter yesDescription
  The help message to display for the yes option

  .Parameter noDescription
  The help message to display for the no option

  .Parameter defaultYes
  Sets whether the default option should be yes or not. Defaults to true

 .Example
   # Show a prompt asking if the user likes cheese with a default of yes
   Read-Confirmation "Do you like cheese?"

    # Show a prompt asking if the user likes cheese with a default of no
   Read-Confirmation "Do you like cheese?" -defaultYes=$false
#>
function Read-Confirmation {
    param (
        [Parameter(Mandatory=$true)]
        [string]    
        $message,
        [string]
        $yesDescription,
        [string]
        $noDescription,
        [bool]
        $defaultYes = $true
    )
    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", $yesDescription
    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", noDescription

    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
    
    $default = 0
    if ($defaultYes -ne $true)
    {
        $default = 1
    }

    $result = $host.ui.PromptForChoice($null, $message, $options, $default) 

    return $result -eq 0
}

<#
 .Synopsis
  Reads a list from a file

 .Description
  Reads a list from a file and returns an array

 .Parameter path
  The path to the file to open

  .Parameter header
  The header to label the list

 .Example
   # Returns a list of items with a header of Wibble
   Get-ListItems ".\packages.txt" "Wibble"

   # Returns a list of items with no header
   Get-ListItems ".\packages.txt"
#>
function Get-ListItems {
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $path,
        [string]
        $header = ""
    )

    $items = import-csv $path -Header $header
    return $items
}

<#
 .Synopsis
  Checks the user's profiles to see if there is an Import-Module command for the specified module

 .Description
  Checks the user's profiles to see if there is an Import-Module command for the specified module

 .Parameter module
  The name of the module to look for

 .Example
   # Tests to see if a module called wibble is imported in any of the users profiles
   Test-ModuleInProfiles "wibble"
#>
function Test-ModuleInProfiles {
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $module
    )

    $profiles = @(
        $PROFILE,
        $PROFILE.CurrentUserCurrentHost,
        $PROFILE.CurrentUserAllHosts,
        $PROFILE.AllUsersCurrentHost,
        $PROFILE.AllUsersAllHosts
    )

    foreach ($profile in $profiles) {
        if (!(Test-Path -LiteralPath $profile)) {
            return $false
        }
    
        $match = (@(Get-Content $profile -ErrorAction SilentlyContinue) -match "Import-Module $module").Count -gt 0
        if ($match) { 
            Write-Verbose "$module found in '$profile'"
            return $true
        }
    }

    return $false
}

function Add-ModuleToProfile {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $module,
        [switch]
        $AllHosts,
        [switch]
        $AllUsers,
        [switch]
        $Force
    )
    
    if ($AllUsers -and !(Test-Administrator)) {
        throw 'Adding posh-git to an AllUsers profile requires an elevated host.'
    }

    $profileName = $(if ($AllUsers) { 'AllUsers' } else { 'CurrentUser' }) `
                 + $(if ($AllHosts) { 'AllHosts' } else { 'CurrentHost' })
    Write-Verbose "`$profileName = '$profileName'"

    if (!$Force) {
        if (Test-ModuleInProfiles $module) {
            Write-Warning "Skipping add of $module import to file '$profilePath'."
            Write-Warning "$module appears to already be imported in one of your profile scripts."
            Write-Warning "If you want to force the add, use the -Force parameter."
            return
        }
    }

    $profilePath = $PROFILE.$profileName
    if (!$profilePath) { 
        $profilePath = $PROFILE
    }

    if (!$profilePath) {
        Write-Warning "Skipping add of $module import to profile; no profile found."
        Write-Verbose "`$PROFILE              = '$PROFILE'"
        Write-Verbose "CurrentUserCurrentHost = '$($PROFILE.CurrentUserCurrentHost)'"
        Write-Verbose "CurrentUserAllHosts    = '$($PROFILE.CurrentUserAllHosts)'"
        Write-Verbose "AllUsersCurrentHost    = '$($PROFILE.AllUsersCurrentHost)'"
        Write-Verbose "AllUsersAllHosts       = '$($PROFILE.AllUsersAllHosts)'"
        return
    }

    # If the profile script exists and is signed, then we should not modify it
    if (Test-Path -LiteralPath $profilePath) {
        if (!(Get-Command Get-AuthenticodeSignature -ErrorAction SilentlyContinue))
        {
            Write-Verbose "Platform doesn't support script signing, skipping test for signed profile."
        }
        else {
            $sig = Get-AuthenticodeSignature $profilePath
            if ($null -ne $sig.SignerCertificate) {
                Write-Warning "Skipping add of $module import to profile; '$profilePath' appears to be signed."
                Write-Warning "Add the command 'Import-Module $module' manually to your profile and resign it."
                return
            }
        }
    }

    # TODO: Check if the location of this module file is in the PSModulePath
    $profileContent = "`nImport-Module $module"

    # Make sure the PowerShell profile directory exists
    $profileDir = Split-Path $profilePath -Parent
    if (!(Test-Path -LiteralPath $profileDir)) {
        if ($PSCmdlet.ShouldProcess($profileDir, "Create current user PowerShell profile directory")) {
            New-Item $profileDir -ItemType Directory -Force -Verbose:$VerbosePreference > $null
        }
    }
 
    if ($PSCmdlet.ShouldProcess($profilePath, "Add 'Import-Module $module' to profile")) {
        Add-Content -LiteralPath $profilePath -Value $profileContent -Encoding UTF8
    }
}