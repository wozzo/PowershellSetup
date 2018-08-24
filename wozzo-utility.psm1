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