<#
.SYNOPSIS
    Creates a Role in vCenter that allows a Service Account to register the vCenter Server to Aria Operations.
.DESCRIPTION
    This script is used to create new roles on your vCenter server.
    The permissions are based on the documentation found here: https://techdocs.broadcom.com/us/en/vmware-cis/aria/aria-operations/8-18/vmware-aria-operations-configuration-guide-8-18/connect-to-data-sources/vsphere/configuring-a-vcenter-server-cloud-account-in-vrealize-operations/privileges-required-for-configuring-a-vcenter-adapter-instance.html
    After the roles are created, they need to be manually associated with a username/serviceaccount and a vSphere object (like a Folder, Cluster, Datacenter, etc...)
.OUTPUTS
    Results are printed to the console.
.NOTES
    Author        Matthias Grasmück, matthias.grasmueck@soultec.ch
    
    Change Log    V1.00, 15.04.2025 - Initial version
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


$ViPrivileges_VcsaToAo = @(
    'StorageProfile.Apply',
    'StorageProfile.Update',
    'StorageProfile.View',
    'StorageViews.View',
    'StorageViews.ConfigureService',
    'Datastore.AllocateSpace',
    'Datastore.Browse',
    'Performance.ModifyIntervals',
    'VirtualMachine.GuestOperations.ModifyAliases',
    'VirtualMachine.GuestOperations.QueryAliases',
    'VirtualMachine.GuestOperations.Modify',
    'VirtualMachine.GuestOperations.Execute',
    'VirtualMachine.GuestOperations.Query',
    'VirtualMachine.Namespace.Management',
    'VirtualMachine.Namespace.ModifyContent',
    'VirtualMachine.Namespace.Query',
    'VirtualMachine.Namespace.ReadContent',
    'VirtualMachine.Inventory.Move',
    'VirtualMachine.Config.CPUCount',
    'VirtualMachine.Config.Resource',
    'VirtualMachine.Config.Memory',
    'VirtualMachine.Inventory.Delete',
    'VirtualMachine.State.CreateSnapshot',
    'VirtualMachine.State.RemoveSnapshot',
    'VirtualMachine.Interact.PowerOff',
    'VirtualMachine.Interact.PowerOn',
    'VirtualMachine.Interact.Reset',
    'Extension.Register',
    'Extension.Unregister',
    'Extension.Update',
    'AutoDeploy.Rule.Create',
    'AutoDeploy.Rule.Delete',
    'AutoDeploy.Rule.Edit',
    'AutoDeploy.RuleSet.Activate',
    'AutoDeploy.RuleSet.Edit',
    'Global.GlobalTag',
    'Global.SystemTag',
    'Global.Health',
    'Global.ManageCustomFields',
    'Global.SetCustomField',
    'Global.Licenses',
    'Host.Inventory.ManageClusterLifecyle',
    'Host.Inventory.EditCluster',
    'Resource.AssignVMToPool',
    'Resource.ColdMigrate',
    'Resource.HotMigrate',
    'Resource.QueryVMotion',
    'ExternalStatsProvider.Register',
    'ExternalStatsProvider.Unregister',
    'ExternalStatsProvider.Update',
    'vStats.CollectAny',
    'vStats.QueryAny',
    'vStats.Settings'
)

$New_ViRole_VcsaToAo_Name = Read-Host "What's the name of you new role?"

$New_ViRole_VcsaToAo = New-VIRole -Name $New_ViRole_VcsaToAo_Name -Privilege (Get-VIPrivilege -Id $ViPrivileges_VcsaToAo)
Write-Host "Created vCenter role $New_ViRole_VcsaToAo" -ForegroundColor Green


# Disconnecting from the vCenter Server
Disconnect-VIServer -Confirm:$false
Write-Host "Disconnected from your vCenter Server $vCenterServer" -ForegroundColor Green