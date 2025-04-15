<#
.SYNOPSIS
    Creates a Role in vCenter that allows a Service Account to register the vCenter Server to Aria Operations for Networks.
.DESCRIPTION
    This script is used to create new roles on your vCenter server.
    The permissions are based on the documentation found here: https://techdocs.broadcom.com/us/en/vmware-cis/aria/aria-operations-for-networks/6-14/vrealize-network-insight-installation-6-14/nsx-assessment-mode-for-evaluation-license/add-vcenter-server.html
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


$ViPrivileges_VcsaToAon = @(
    'Global.Settings',
    'DVSwitch.Modify',
    'DVSwitch.PortConfig',
    'DVPortgroup.Modify',
    'DVPortgroup.PolicyOp'
)

$New_ViRole_VcsaToAon_Name = Read-Host "What's the name of you new role?"

$New_ViRole_VcsaToAon = New-VIRole -Name $New_ViRole_VcsaToAon_Name -Privilege (Get-VIPrivilege -Id $ViPrivileges_VcsaToAon)
Write-Host "Created vCenter role $New_ViRole_VcsaToAon" -ForegroundColor Green


# Disconnecting from the vCenter Server
Disconnect-VIServer -Confirm:$false
Write-Host "Disconnected from your vCenter Server $vCenterServer" -ForegroundColor Green