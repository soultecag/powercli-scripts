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
    Change Log    V1.00, 10/10/2024 - Initial version
    Change Log    V1.1,  22/11/2024 - Added a confirmation process, added the option to ping the VMs afterwards 
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


# Get all VMs with portID starting with "c-"
$problematicVMs = Get-VM | Get-NetworkAdapter | Where-Object { $_.ExtensionData.Backing.Port.PortKey -like "c-*" } | Select-Object -ExpandProperty Parent -Unique

# Print out the VMs with problematic portIDs
Write-Host "VMs with portID 'c-':"
$problematicVMs | ForEach-Object { Write-Host $_.Name }

# Ask for confirmation to fix the issues
$confirmation = Read-Host "Do you want to fix those issues for the following VMs - resulting in 5sec Network Connectivity loss? (yes/no)"

if ($confirmation -eq "yes") {
    foreach ($vm in $problematicVMs) {
        Write-Host "Processing $($vm.Name)..."
        
        # Disconnect the network adapter
        Get-NetworkAdapter -VM $vm | Where-Object { $_.ExtensionData.Backing.Port.PortKey -like "c-*" } | Set-NetworkAdapter -Connected $false -Confirm:$false
        
        # Wait for 5 seconds
        Start-Sleep -Seconds 5
        
        # Reconnect the network adapter
        Get-NetworkAdapter -VM $vm | Where-Object { $_.ExtensionData.Backing.Port.PortKey -like "c-*" } | Set-NetworkAdapter -Connected $true -Confirm:$false
        
        Write-Host "Fixed network adapter for $($vm.Name)"
    }
    
    # List all affected VMs
    Write-Host "Affected VMs:"
    $problematicVMs | ForEach-Object { Write-Host $_.Name }
    
    # Option to read out IP and ping VMs
    $pingOption = Read-Host "Do you want to read out IPs and ping the affected VMs? (yes/no)"
    
    if ($pingOption -eq "yes") {
        foreach ($vm in $problematicVMs) {
            $ip = $vm.Guest.IPAddress[0]
            if ($ip) {
                Write-Host "$($vm.Name) IP: $ip"
                $pingResult = Test-Connection -ComputerName $ip -Count 1 -Quiet
                if ($pingResult) {
                    Write-Host "Ping successful for $($vm.Name)"
                } else {
                    Write-Host "Ping failed for $($vm.Name)"
                }
            } else {
                Write-Host "Unable to retrieve IP for $($vm.Name)"
            }
        }
    }
} else {
    Write-Host "Operation cancelled. No changes were made."
}
