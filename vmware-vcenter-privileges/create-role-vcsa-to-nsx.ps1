<#
.SYNOPSIS
    Creates a Role in vCenter that allows a Service Account to register the vCenter Server to NSX.
.DESCRIPTION
    This script is used to create new roles on your vCenter server.
    The permissions are based on the documentation found here: 
    After the roles are created, they need to be manually associated with a username/serviceaccount and a vSphere object (like a Folder, Cluster, Datacenter, etc...)
.OUTPUTS
    Results are printed to the console.
.NOTES
    Author        Matthias Grasmück, matthias.grasmueck@soultec.ch
    
    Change Log    V1.00, 15.04.2025 - Initial version
#>

# Load all PowerCLI Modules
Get-Module -ListAvailable "VMware*" | Import-Module -ErrorAction SilentlyContinue

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


$ViPrivileges_VcsaToNsx = @(
    'Authorization.ReassignRolePermissions',
    'Authorization.ModifyPermissions',
    'Authorization.ModifyRoles',
    'Extension.Register',
    'Extension.Unregister',
    'Extension.Update',
    'Sessions.GlobalMessage',
    'Sessions.ValidateSession',
    'Sessions.TerminateSession',
    'Host.Config.Maintenance',
    'Host.Config.Network',
    'Host.Local.CreateVM',
    'Host.Local.DeleteVM',
    'Host.Local.ReconfigVM',
    'Task.Create',
    'Task.Update',
    'Task.Update.Task.Update',
    'ScheduledTask.Create',
    'ScheduledTask.Delete',
    'ScheduledTask.Edit',
    'ScheduledTask.Run',
    'Global.CancelTask',
    'Global.Licenses',
    'Resource.AssignVAppToPool',
    'Resource.AssignVMToPool',
    'ServiceAccount.Administer',
    'VirtualMachine.Config.AddExistingDisk',
    'VirtualMachine.Config.AddNewDisk',
    'VirtualMachine.Config.AddRemoveDevice',
    'VirtualMachine.Config.AdvancedConfig',
    'VirtualMachine.Config.Annotation',
    'VirtualMachine.Config.ChangeTracking',
    'VirtualMachine.Config.CPUCount',
    'VirtualMachine.Config.DiskExtend',
    'VirtualMachine.Config.DiskLease',
    'VirtualMachine.Config.EditDevice',
    'VirtualMachine.Config.HostUSBDevice',
    'VirtualMachine.Config.ManagedBy',
    'VirtualMachine.Config.Memory',
    'VirtualMachine.Config.MksControl',
    'VirtualMachine.Config.QueryFTCompatibility',
    'VirtualMachine.Config.QueryUnownedFiles',
    'VirtualMachine.Config.RawDevice',
    'VirtualMachine.Config.ReloadFromPath',
    'VirtualMachine.Config.RemoveDisk',
    'VirtualMachine.Config.Rename',
    'VirtualMachine.Config.ResetGuestInfo',
    'VirtualMachine.Config.Resource',
    'VirtualMachine.Config.Settings',
    'VirtualMachine.Config.SwapPlacement',
    'VirtualMachine.Config.ToggleForkParent',
    'VirtualMachine.Config.UpgradeVirtualHardware',
    'VirtualMachine.GuestOperations.Execute',
    'VirtualMachine.GuestOperations.Modify',
    'VirtualMachine.GuestOperations.ModifyAliases',
    'VirtualMachine.GuestOperations.Query',
    'VirtualMachine.GuestOperations.QueryAliases',
    'VirtualMachine.Provisioning.Clone',
    'VirtualMachine.Provisioning.CloneTemplate',
    'VirtualMachine.Provisioning.CreateTemplateFromVM',
    'VirtualMachine.Provisioning.Customize',
    'VirtualMachine.Provisioning.DeployTemplate',
    'VirtualMachine.Provisioning.DiskRandomAccess',
    'VirtualMachine.Provisioning.DiskRandomRead',
    'VirtualMachine.Provisioning.FileRandomAccess',
    'VirtualMachine.Provisioning.GetVmFiles',
    'VirtualMachine.Provisioning.MarkAsTemplate',
    'VirtualMachine.Provisioning.MarkAsVM',
    'VirtualMachine.Provisioning.ModifyCustSpecs',
    'VirtualMachine.Provisioning.PromoteDisks',
    'VirtualMachine.Provisioning.PutVmFiles',
    'VirtualMachine.Provisioning.ReadCustSpecs',
    'VirtualMachine.Inventory.Create',
    'VirtualMachine.Inventory.CreateFromExisting',
    'VirtualMachine.Inventory.Delete',
    'VirtualMachine.Inventory.Move',
    'VirtualMachine.Inventory.Register',
    'VirtualMachine.Inventory.Unregister',
    'Network.Assign',
    'VApp.ApplicationConfig',
    'VApp.AssignResourcePool',
    'VApp.AssignVApp',
    'VApp.AssignVM',
    'VApp.Clone',
    'VApp.Create',
    'VApp.Delete',
    'VApp.Export',
    'VApp.ExtractOvfEnvironment',
    'VApp.Import',
    'VApp.InstanceConfig',
    'VApp.ManagedByConfig',
    'VApp.Move',
    'VApp.PowerOff',
    'VApp.PowerOn',
    'VApp.PullFromUrls',
    'VApp.Rename',
    'VApp.ResourceConfig',
    'VApp.Suspend',
    'VApp.Unregister',
    'VcIntegrity.lifecycleHealth.Read',
    'VcIntegrity.lifecycleGeneral.Read',
    'VcIntegrity.lifecycleGeneral.Write',
    'VcIntegrity.lifecycleSoftwareSpecification.Read',
    'VcIntegrity.lifecycleSoftwareSpecification.Write',
    'VcIntegrity.lifecycleSoftwareRemediation.Write',
    'VcIntegrity.lifecycleSettings.Read',
    'VcIntegrity.lifecycleSettings.Write'
)

$New_ViRole_VcsaToNsx_Name = Read-Host "What's the name of you new role?"

$New_ViRole_VcsaToNsx = New-VIRole -Name $New_ViRole_VcsaToNsx_Name -Privilege (Get-VIPrivilege -Id $ViPrivileges_VcsaToNsx)
Write-Host "Created vCenter role $New_ViRole_VcsaToNsx" -ForegroundColor Green


# Disconnecting from the vCenter Server
Disconnect-VIServer -Confirm:$false
Write-Host "Disconnected from your vCenter Server $vCenterServer" -ForegroundColor Green
