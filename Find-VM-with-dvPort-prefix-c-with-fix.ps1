<#
.SYNOPSIS
    Fix VMs with dvPort ID prefix c-xy.
.DESCRIPTION
   This scripts generated a CSV File with VM containing dvPort IDs with prefix c-
    https://knowledge.broadcom.com/external/article/318950/vnetwork-distributed-switch-contains-dvp.html
    This script then automatically disconnected the vNIC and reconnect its.
.OUTPUTS
    Only console output
.NOTES
  
    Author        Yannick Gerber, yannick.gerber@soultec.ch


#>

# Load the PowerCLI SnapIn and set the configuration
Add-PSSnapin VMware.VimAutomation.Core -ea "SilentlyContinue"
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null

# Get the vCenter Server address, username and password as PSCredential
$vCenterServer = Read-Host "Enter vCenter Server host name (DNS with FQDN or IP address)"
$vCenterUser = Read-Host "Enter your user name (DOMAIN\User or user@domain.com)"
$vCenterUserPassword = Read-Host "Enter your password (this will be converted to a secure string)" -AsSecureString:$true
$Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $vCenterUser,$vCenterUserPassword

# Connect to the vCenter Server with collected credentials
Connect-VIServer -Server $vCenterServer -Credential $Credentials | Out-Null
Write-Host "Connected to your vCenter server $vCenterServer" -ForegroundColor Green

Add-PSSnapin VMware.VimAutomation.Core -ea "SilentlyContinue"
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null


# Get all VMs
$vms = Get-VM


foreach ($vm in $vms) {
    # Get network adapters for the VM
    $networkAdapters = Get-NetworkAdapter -VM $vm
    
    foreach ($adapter in $networkAdapters) {
        $portID = $adapter.ExtensionData.Backing.Port.PortKey
        
        # Only process if the portID starts with "c-"
        if ($portID -and $portID.StartsWith("c-")) {
            Write-Host "Processing VM: $($vm.Name), Adapter: $($adapter.Name)"
            
            # Disconnect the network adapter
            Set-NetworkAdapter -NetworkAdapter $adapter -Connected $false -Confirm:$false
            Write-Host "Network adapter disconnected"
            
            # Wait for a few seconds
            Start-Sleep -Seconds 5
            
            # Reconnect the network adapter
            Set-NetworkAdapter -NetworkAdapter $adapter -Connected $true -Confirm:$false
            Write-Host "Network adapter reconnected"
        }
    }
}
# Disconnect from vCenter Server
Disconnect-VIServer -Confirm:$false
