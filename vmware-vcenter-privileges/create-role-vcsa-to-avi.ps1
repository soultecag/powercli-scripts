<#
.SYNOPSIS
    Creates a Role in vCenter that allows a Service Account to register the vCenter Server to Avi Load Balancer via NSX Cloud.
.DESCRIPTION
    This script is used to create new roles on your vCenter server.
    The permissions are based on the documentation found here: https://techdocs.broadcom.com/us/en/vmware-security-load-balancing/avi-load-balancer/avi-load-balancer/22-1/vmware-avi-load-balancer-installation-guide/installing-nsx-alb-in-vmware-nsx-t-environments/installing-the-avi-controller-nsx-t-/installation-prerequisites/roles-and-permissions-for-vcenter-and-nsx-t-users/vcenter-roles.html
    After the roles are created, they need to be manually associated with a username/serviceaccount and a vSphere object (like a Folder, Cluster, Datacenter, etc...)
.OUTPUTS
    Results are printed to the console.
.NOTES
    Author        Matthias Grasmück, matthias.grasmueck@soultec.ch
    
    Change Log    V1.00, 22.01.2024 - Initial version
    Change Log    V1.10, 11.04.2025 - Updated version
#>

# Load all PowerCLI Modules
Get-Module -ListAvailable "VMware.VimAutomation.Core" | Import-Module -ErrorAction SilentlyContinue

# Set the PowerCLI configuration
Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -InvalidCertificateAction Ignore -Confirm:$false | Out-Null

# Get the vCenter Server address, username and password as PSCredential
$vCenterServer = Read-Host "Enter vCenter Server host name (DNS with FQDN or IP address)"
$vCenterUser = Read-Host "Enter your user name (DOMAIN\User or user@domain.com)"
$vCenterUserPassword = Read-Host "Enter your password (this will be converted to a secure string)" -AsSecureString:$true
$Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $vCenterUser,$vCenterUserPassword
#$ViRolePrefix = Read-Host "Enter the customer's prefix ID"

# Connect to the vCenter Server with collected credentials
Connect-VIServer -Server $vCenterServer -Credential $Credentials | Out-Null
Write-Host "Connected to your vCenter server $vCenterServer" -ForegroundColor Green


$ViPrivileges_VcsaToAviGlobal = @(
    'System.Anonymous',
    'System.Read',
    'System.View',
    'ContentLibrary.AddLibraryItem',
    'ContentLibrary.DeleteLibraryItem',
    'ContentLibrary.UpdateSession',
    'ContentLibrary.UpdateLibraryItem',
    'Datastore.AllocateSpace',
    'Datastore.DeleteFile',
    'Network.Assign',
    'Network.Delete',
    'VApp.Import',
    'VirtualMachine.Config.AddNewDisk',
    'VirtualMachine.Config.AdvancedConfig'
)

$New_ViRole_VcsaToAviGlobal_Name = Read-Host "What's the name of you new Avi Global role?"

$New_ViRole_VcsaToAviGlobal = New-VIRole -Name $New_ViRole_VcsaToAviGlobal_Name -Privilege (Get-VIPrivilege -Id $ViPrivileges_VcsaToAviGlobal)
Write-Host "Created vCenter role $New_ViRole_VcsaToAviGlobal" -ForegroundColor Green

$ViPrivileges_VcsaToAviFolder = @(
    'System.Anonymous',
    'System.Read',
    'System.View',
    'Folder.Create',
    'Network.Assign',
    'Network.Delete',
    'Resource.AssignVMToPool',
    'Task.Create',
    'Task.Update',
    'VApp.AssignVM',
    'VApp.AssignResourcePool',
    'VApp.AssignVApp',
    'VApp.Create',
    'VApp.Delete',
    'VApp.Export',
    'VApp.Import',
    'VApp.PowerOff',
    'VApp.PowerOn',
    'VApp.ApplicationConfig',
    'VApp.InstanceConfig',
    'VirtualMachine.Config.AddExistingDisk',
    'VirtualMachine.Config.AddNewDisk',
    'VirtualMachine.Config.AddRemoveDevice',
    'VirtualMachine.Config.AdvancedConfig',
    'VirtualMachine.Config.CPUCount',
    'VirtualMachine.Config.Memory',
    'VirtualMachine.Config.Settings',
    'VirtualMachine.Config.Resource',
    'VirtualMachine.Config.MksControl',
    'VirtualMachine.Config.DiskExtend',
    'VirtualMachine.Config.EditDevice',
    'VirtualMachine.Config.RemoveDisk',
    'VirtualMachine.Inventory.Create',
    'VirtualMachine.Inventory.Delete',
    'VirtualMachine.Inventory.Register',
    'VirtualMachine.Inventory.Unregister',
    'VirtualMachine.Interact.DeviceConnection',
    'VirtualMachine.Interact.ToolsInstall',
    'VirtualMachine.Interact.PowerOff',
    'VirtualMachine.Interact.PowerOn',
    'VirtualMachine.Interact.Reset',
    'VirtualMachine.Provisioning.DiskRandomAccess',
    'VirtualMachine.Provisioning.FileRandomAccess',
    'VirtualMachine.Provisioning.DiskRandomRead',
    'VirtualMachine.Provisioning.DeployTemplate',
    'VirtualMachine.Provisioning.MarkAsVM'
)

$New_ViRole_VcsaToAviFolder_Name = Read-Host "What's the name of you new Avi Folder role?"

$New_ViRole_VcsaToAviFolder = New-VIRole -Name $New_ViRole_VcsaToAviFolder_Name -Privilege (Get-VIPrivilege -Id $ViPrivileges_VcsaToAviFolder)
Write-Host "Created vCenter role $New_ViRole_VcsaToAviFolder" -ForegroundColor Green

# Disconnecting from the vCenter Server
Disconnect-VIServer -Confirm:$false
Write-Host "Disconnected from your vCenter Server $vCenterServer" -ForegroundColor Green