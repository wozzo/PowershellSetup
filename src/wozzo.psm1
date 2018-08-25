#Requires -RunAsAdministrator

$system =  [Environment]::GetFolderPath("System")

Write-Host "
 __      __                           
/  \    /  \________________________  
\   \/\/   /  _ \___   /\___   /  _ \ 
 \        (  <_> )    /  /    (  <_> )
  \__/\  / \____/_____ \/_____ \____/ 
       \/             \/      \/      
"

Import-Module $PSScriptRoot\utility.ps1
Import-Module $PSScriptRoot\packages.ps1
Import-Module $PSScriptRoot\shortcuts.ps1
Import-Module $PSScriptRoot\setup.ps1

# Useful variables
$hosts = Join-Path -Path $system -ChildPath "drivers\etc\hosts"
Export-ModuleMember -Variable hosts