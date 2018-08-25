function Start-VSCode { 
    &"C:\Program Files\Microsoft VS Code\code.exe" $args 
}
Export-ModuleMember -Function Start-VSCode

Set-Alias build .\build.ps1
Export-ModuleMember -Alias build

Set-Alias vsc Start-VSCode
Export-ModuleMember -Alias vsc