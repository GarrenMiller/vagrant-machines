function ProvisionVagrantMachine {
    New-LocalAdmin 
    Install-IIS
    Set-FirewallRules
    Rename-Computer "ws19dev01" -Restart
}
function New-LocalAdmin {
    $password = ConvertTo-SecureString -AsPlainText -Force $env:ADMIN_PASSWORD
    New-LocalUser $env:ADMIN_USER -Password $password -FullName $env:ADMIN_USER
    Add-LocalGroupMember -Group "Administrators" -Member $env:ADMIN_USER
}
function Install-IIS {
    Install-WindowsFeature -name Web-Server -IncludeManagementTools
}
function Set-FirewallRules {
    Set-NetFirewallRule -DisplayGroup "File And Printer Sharing" -Enabled True -Profile Private
}
ProvisionVagrantMachine