<#
.SYNOPSIS
    Script to change ESXi Root Password
.DESCRIPTION
    If you do not have vSphere configuration profiles configured ;)
.NOTES

    Author        Yannick Gerber, yannick.gerber at soultec.ch
    
    Change Log    V1.00, 11/03/2025 - Initial version
   
#>

# Load the PowerCLI SnapIn and set the configuration
#Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null
# Simple PowerCLI script to change root password on all ESXi hosts in vCenter


# Connect to vCenter
$vCenterServer = Read-Host "Enter vCenter Server FQDN/IP"
Connect-VIServer -Server $vCenterServer

# Get the new password
$newRootPassword = Read-Host "Enter new root password for ALL ESXi hosts" -AsSecureString
$credential = New-Object System.Management.Automation.PSCredential("root", $newRootPassword)

# Get all ESXi hosts
$allHosts = Get-VMHost | Where-Object {$_.ConnectionState -eq "Connected" -or $_.ConnectionState -eq "Maintenance"}

Write-Host "Found $($allHosts.Count) ESXi hosts in Connected or Maintenance state."
Write-Host "Changing root password on all hosts..."

# Process each host
foreach ($vmHost in $allHosts) {
    try {
        # Get the ESXCli instance
        $esxcli = Get-EsxCli -VMHost $vmHost -V2
        
        # Create arguments for account set command
        $arguments = $esxcli.system.account.set.CreateArgs()
        $arguments.id = "root"
        $arguments.password = $credential.GetNetworkCredential().Password
        $arguments.passwordconfirmation = $credential.GetNetworkCredential().Password
        
        # Change password
        $result = $esxcli.system.account.set.Invoke($arguments)
        
        if ($result) {
            Write-Host "SUCCESS: Changed root password on $($vmHost.Name)" -ForegroundColor Green
        } else {
            Write-Host "FAILED: Could not change root password on $($vmHost.Name)" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "ERROR: $($vmHost.Name) - $_" -ForegroundColor Red
    }
}

Write-Host "Password change operation complete!"
Write-Host "Disconnecting from vCenter..."
Disconnect-VIServer -Server $global:DefaultVIServer -Confirm:$false
