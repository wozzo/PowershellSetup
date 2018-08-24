Import-Module .\wozzo-utility.psm1
Import-Module .\wozzo-setup.psm1

$system =  [Environment]::GetFolderPath("System")

# Useful variables
$hosts = Join-Path -Path $system -ChildPath "drivers\etc\hosts"
Export-ModuleMember -Variable hosts

# Handy Functions
function Start-VSCode { 
    &"C:\Program Files\Microsoft VS Code\code.exe" $args 
}
Export-ModuleMember -Function Start-VSCode

# Handy Aliases
Set-Alias build .\build.ps1
Export-ModuleMember -Alias build

Set-Alias vsc Start-VSCode
Export-ModuleMember -Alias vsc