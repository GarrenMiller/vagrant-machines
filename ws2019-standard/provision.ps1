function ProvisionVagrantMachine {
    New-LocalAdmin 
    Grant-LogonAsService
    Install-IIS
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
function Grant-LogonAsService {
    $username = $env:ADMIN_USER
    $computerName = HOSTNAME.EXE
    Invoke-Command -ComputerName $computerName -Script {
    param([string] $username)
    $tempPath = [System.IO.Path]::GetTempPath()
    $import = Join-Path -Path $tempPath -ChildPath "import.inf"
    if(Test-Path $import) { Remove-Item -Path $import -Force }
    $export = Join-Path -Path $tempPath -ChildPath "export.inf"
    if(Test-Path $export) { Remove-Item -Path $export -Force }
    $secedt = Join-Path -Path $tempPath -ChildPath "secedt.sdb"
    if(Test-Path $secedt) { Remove-Item -Path $secedt -Force }
    try {
        Write-Host ("Granting SeServiceLogonRight to user account: {0} on host: {1}." -f $username, $computerName)
        $sid = ((New-Object System.Security.Principal.NTAccount($username)).Translate([System.Security.Principal.SecurityIdentifier])).Value
        secedit /export /cfg $export
        $sids = (Select-String $export -Pattern "SeServiceLogonRight").Line
        foreach ($line in @("[Unicode]", "Unicode=yes", "[System Access]", "[Event Audit]", "[Registry Values]", "[Version]", "signature=`"`$CHICAGO$`"", "Revision=1", "[Profile Description]", "Description=GrantLogOnAsAService security template", "[Privilege Rights]", "$sids,*$sid")){
        Add-Content $import $line
        }
        secedit /import /db $secedt /cfg $import
        secedit /configure /db $secedt
        gpupdate /force
        Remove-Item -Path $import -Force
        Remove-Item -Path $export -Force
        Remove-Item -Path $secedt -Force
    } catch {
        Write-Host ("Failed to grant SeServiceLogonRight to user account: {0} on host: {1}." -f $username, $computerName)
        $error[0]
    }
    } -ArgumentList $username
}
ProvisionVagrantMachine