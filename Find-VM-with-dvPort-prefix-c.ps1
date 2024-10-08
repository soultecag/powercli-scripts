<#
.SYNOPSIS
    List VMs with PortID c-xy.
.DESCRIPTION
   This scripts generated a CSV File with VM containing dvPort IDs with prefix c-
    https://knowledge.broadcom.com/external/article/318950/vnetwork-distributed-switch-contains-dvp.html
    Resolution for this issue is disconnected the vNIC of the VM, save. Then reconnect.
.OUTPUTS
    CSV File.
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



$vms = Get-VM


$vmInfo = @()

foreach ($vm in $vms) {
   
    $networkAdapters = Get-NetworkAdapter -VM $vm
    
    foreach ($adapter in $networkAdapters) {
        $portID = $adapter.ExtensionData.Backing.Port.PortKey
        
        # Only process if the portID starts with "c-"
        if ($portID -and $portID.StartsWith("c-")) {
            # Create a custom object with VM and port information
            $vmData = [PSCustomObject]@{
                VMName = $vm.Name
                PowerState = $vm.PowerState
                NetworkName = $adapter.NetworkName
                PortID = $portID
            }
            
            # Add the object to the array
            $vmInfo += $vmData
        }
    }
}


$vmInfo | Export-Csv -Path "C:\source\VMPortInfo.csv" -NoTypeInformation

