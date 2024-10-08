<#
.SYNOPSIS
    Create_vCenter_OpenShift_Install_Roles.ps1 - PowerShell Script to create a new vCenter Roles algined with the prereqs for the OpenShift Container Platform Install.
    Originally created by https://github.com/saintdle/PowerCLI
    Reformated by https://github.com/ecwpz91/PowerCLI
.DESCRIPTION
    This script is used to create new roles on your vCenter server.
    The newly created roles will be filled with the needed permissions for installing OpenShift Container Platform using the IPI Method.
    The permissions are based on the documentation found here: https://docs.openshift.com/container-platform/latest/installing/installing_vsphere/installing-vsphere-installer-provisioned.html#installation-vsphere-installer-infra-requirements_installing-vsphere-installer-provisioned
    After the roles are created, they need to be manually associated with a username/serviceaccount and a vSphere object (like a Folder, Cluster, Datacenter, etc...)
.OUTPUTS
    Results are printed to the console.
.NOTES
    Author        Dean Lewis, https://vEducate.co.uk, Twitter: @saintdle
    Author        John Call, jcall@redhat.com
    Author        Yannick Gerber, yannick.gerber@soultec.ch
    
    Change Log    V1.00, 07/11/2020 - Initial version
    Change Log    V2.00, 01/04/2021 - Updated for openshift release 4.9
    Change Log    V20220531, 05/31/2022 - Updated for openshift release 4.10, added ResourcePool role
    Change Log    V20240909, 09/09/2024 - Updated for OpenShift Release 4.18, Role cusomizations

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


$OpenShift_vCenter = @(
    'Cns.Searchable',
    'InventoryService.Tagging.AttachTag',
    'InventoryService.Tagging.CreateCategory',
    'InventoryService.Tagging.CreateTag',
    'InventoryService.Tagging.DeleteCategory',
    'InventoryService.Tagging.DeleteTag',
    'InventoryService.Tagging.EditCategory',
    'InventoryService.Tagging.EditTag',
    'Sessions.ValidateSession',
    'StorageProfile.Update',
    'StorageProfile.View'
)

$OpenShiftInstallRole = New-VIRole -Name 'Role_OpenShift_vCenter' -Privilege (Get-VIPrivilege -Id $OpenShift_vCenter)
Write-Host "Created vCenter role $OpenShiftInstallRole" -ForegroundColor Green


$OpenShift_Cluster = @(
    'Host.Config.Storage',
    'Resource.AssignVMToPool',
    'VApp.AssignResourcePool',
    'VApp.Import',
    'VirtualMachine.Config.AddNewDisk'
)

$OpenShiftInstallRole = New-VIRole -Name 'Role_OpenShift_Cluster-propagate' -Privilege (Get-VIPrivilege -Id $OpenShift_Cluster)
Write-Host "Created vCenter role $OpenShiftInstallRole" -ForegroundColor Green


$OpenShift_ResourcePool = @(
    'Host.Config.Storage',
    'Resource.AssignVMToPool',
    'VApp.AssignResourcePool',
    'VApp.Import',
    'VirtualMachine.Config.AddNewDisk'
)

$OpenShiftInstallRole = New-VIRole -Name 'Role_OpenShift_ResourcePool-propagate' -Privilege (Get-VIPrivilege -Id $OpenShift_Cluster)
Write-Host "Created vCenter role $OpenShiftInstallRole" -ForegroundColor Green


$OpenShift_Datastore = @(
    'Datastore.AllocateSpace',
    'Datastore.Browse',
    'Datastore.FileManagement',
    'InventoryService.Tagging.ObjectAttachable'
)

$OpenShiftInstallRole = New-VIRole -Name 'Role_OpenShift_Datastore' -Privilege (Get-VIPrivilege -Id $OpenShift_Datastore)
Write-Host "Created vCenter role $OpenShiftInstallRole" -ForegroundColor Green


$OpenShift_PortGroup = @(
    'Network.Assign'
)

$OpenShiftInstallRole = New-VIRole -Name 'Role_OpenShift_PortGroup' -Privilege (Get-VIPrivilege -Id $OpenShift_PortGroup)
Write-Host "Created vCenter role $OpenShiftInstallRole" -ForegroundColor Green


$OpenShift_VMFolder = @(
    'InventoryService.Tagging.ObjectAttachable',
    'Resource.AssignVMToPool',
    'VApp.Import',
    'VirtualMachine.Config.AddExistingDisk',
    'VirtualMachine.Config.AddNewDisk',
    'VirtualMachine.Config.AddRemoveDevice',
    'VirtualMachine.Config.AdvancedConfig',
    'VirtualMachine.Config.Annotation',
    'VirtualMachine.Config.CPUCount',
    'VirtualMachine.Config.DiskExtend',
    'VirtualMachine.Config.DiskLease',
    'VirtualMachine.Config.EditDevice',
    'VirtualMachine.Config.Memory',
    'VirtualMachine.Config.RemoveDisk',
    'VirtualMachine.Config.Rename',
    'VirtualMachine.Config.ResetGuestInfo',
    'VirtualMachine.Config.Resource',
    'VirtualMachine.Config.Settings',
    'VirtualMachine.Config.UpgradeVirtualHardware',
    'VirtualMachine.Interact.GuestControl',
    'VirtualMachine.Interact.PowerOff',
    'VirtualMachine.Interact.PowerOn',
    'VirtualMachine.Interact.Reset',
    'VirtualMachine.Inventory.Create',
    'VirtualMachine.Inventory.CreateFromExisting',
    'VirtualMachine.Inventory.Delete',
    'VirtualMachine.Provisioning.Clone',
    'VirtualMachine.Provisioning.DeployTemplate',
    'VirtualMachine.Provisioning.MarkAsTemplate'
)

$OpenShiftInstallRole = New-VIRole -Name 'Role_OpenShift_VMFolder_propagate' -Privilege (Get-VIPrivilege -Id $OpenShift_VMFolder)
Write-Host "Created vCenter role $OpenShiftInstallRole" -ForegroundColor Green


$OpenShift_Datacenter = @(
    'InventoryService.Tagging.ObjectAttachable',
    'Resource.AssignVMToPool',
    'VApp.Import',
    'VirtualMachine.Config.AddExistingDisk',
    'VirtualMachine.Config.AddNewDisk',
    'VirtualMachine.Config.AddRemoveDevice',
    'VirtualMachine.Config.AdvancedConfig',
    'VirtualMachine.Config.Annotation',
    'VirtualMachine.Config.CPUCount',
    'VirtualMachine.Config.DiskExtend',
    'VirtualMachine.Config.DiskLease',
    'VirtualMachine.Config.EditDevice',
    'VirtualMachine.Config.Memory',
    'VirtualMachine.Config.RemoveDisk',
    'VirtualMachine.Config.Rename',
    'VirtualMachine.Config.ResetGuestInfo',
    'VirtualMachine.Config.Resource',
    'VirtualMachine.Config.Settings',
    'VirtualMachine.Config.UpgradeVirtualHardware',
    'VirtualMachine.Interact.GuestControl',
    'VirtualMachine.Interact.PowerOff',
    'VirtualMachine.Interact.PowerOn',
    'VirtualMachine.Interact.Reset',
    'VirtualMachine.Inventory.Create',
    'VirtualMachine.Inventory.CreateFromExisting',
    'VirtualMachine.Inventory.Delete',
    'VirtualMachine.Provisioning.Clone',
    'VirtualMachine.Provisioning.DeployTemplate',
    'VirtualMachine.Provisioning.MarkAsTemplate',
    'Folder.Create',
    'Folder.Delete'
)

$OpenShiftInstallRole = New-VIRole -Name 'Role_OpenShift_Datacenter_propagate' -Privilege (Get-VIPrivilege -Id $OpenShift_Datacenter)
Write-Host "Created vCenter role $OpenShiftInstallRole" -ForegroundColor Green


# Disconnecting from the vCenter Server
Disconnect-VIServer -Confirm:$false
Write-Host "Disconnected from your vCenter Server $vCenterServer" -ForegroundColor Green
