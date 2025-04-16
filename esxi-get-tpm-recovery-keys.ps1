<#
.SYNOPSIS
    Retrieve TPM Recovery Keys for ESXi via vCenter

.DESCRIPTION
    Recovery Keys are printed to a textfile.

.NOTES
    Author        Yannick Gerber, yannick.gerber at soultec.ch
    Change Log    V1.00, 11/01/2025 - Initial version
#>




$vCenterServer = Read-Host "Enter vCenter Server host name (DNS with FQDN or IP address)"
$vCenterUser = Read-Host "Enter your user name (DOMAIN\User or user@domain.com)"
$vCenterUserPassword = Read-Host "Enter your password (this will be converted to a secure string)" -AsSecureString:$true
$Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $vCenterUser,$vCenterUserPassword

# Connect to the vCenter Server with collected credentials
Connect-VIServer -Server $vCenterServer -Credential $Credentials | Out-Null
Write-Host "Connected to your vCenter server $vCenterServer" -ForegroundColor Green


$VMHosts = Get-VMHost | Sort-Object
$VMHostKeys = @()
foreach ($VMHost in $VMHosts) {
    $esxcli = Get-EsxCli -VMHost $VMHost -V2
    try {
        $encryption = $esxcli.system.settings.encryption.get.Invoke()
        if ($encryption.Mode -eq "TPM")
        {
            $key = $esxcli.system.settings.encryption.recovery.list.Invoke()
            $hostKey = [pscustomobject]@{
                Host = $VMHost.Name
                EncryptionMode = $encryption.Mode
                RequireExecutablesOnlyFromInstalledVIBs = $encryption.RequireExecutablesOnlyFromInstalledVIBs
                RequireSecureBoot = $encryption.RequireSecureBoot
                RecoveryID = $key.RecoveryID
                RecoveryKey = $key.Key
            }
            $VMHostKeys += $hostKey
        }
        else
        {
            $hostKey = [pscustomobject]@{
                Host = $VMHost.Name
                EncryptionMode = $encryption.Mode
                RequireExecutablesOnlyFromInstalledVIBs = $encryption.RequireExecutablesOnlyFromInstalledVIBs
                RequireSecureBoot = $encryption.RequireSecureBoot
                RecoveryID = $null
                RecoveryKey = $null
            }
            $VMHostKeys += $hostKey
        }
    }
    catch {
        $VMHost.Name + $_
    }
}
$VMHostKeys | Out-String | Out-File -FilePath "D:\soulTec\output\VMHostEncryptionReport.txt"


 
