[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12
# Get PSGet
(new-object Net.WebClient).DownloadString("https://github.com/psget/psget/raw/master/PsGet/PsGet.psm1") | Invoke-Expression
# Install Wozzo module
Install-Module -ModuleUrl https://github.com/wozzo/PowershellSetup/zipball/master