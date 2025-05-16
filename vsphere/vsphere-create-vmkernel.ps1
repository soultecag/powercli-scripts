<#
.SYNOPSIS
    Create vmkernel adapters en mass
    
.DESCRIPTION


    Example CSV Files

    hostname,portgroup,ip
    esxi01,DPG-vMotion,192.168.10.101/24

    hostname,portgroup,ip,subnetmask
    esxi01,DPG-vMotion,192.168.10.101,255.255.255.0

    hostname,portgroup,ip
    esxi01,DPG-vMotion,192.168.10.101



    The IP doesn't need to be in CIDR format. The script is designed to handle both formats:

    - CIDR format (like "192.168.1.10/24")
    - Standard IP format (like "192.168.1.10")

    If you provide the IP in standard format, the script will look for a "subnetmask" column in your CSV file. If that column doesn't exist or is empty, it will use a default subnet mask of "255.255.255.0" (which is equivalent to /24 in CIDR notation).
    
.OUTPUTS
    Results are printed to the console.
.NOTES
  
    Author        Yannick Gerber, yannick.gerber@soultec.ch
    Change Log    V1.00, 26.04.2025 - Initial version

#>

# CONFIGURATION - Edit these values as needed
$CsvPath = "D:\soulTec\powercli\vmkernel.csv"  # Path to your CSV file
$DefaultNetworkStack = "defaultTcpipStack" 

# VMkernel service configuration - Set to $true to enable
$EnableVMotion = $false                    # vMotion traffic
$EnableFT = $false                        # Fault Tolerance logging
$EnableMgmt = $false                       # Management traffic
$EnableVSAN = $false                      # VSAN traffic
$EnableVSANWitness = $false               # VSAN Witness traffic
$EnableProvisioning = $true              # Provisioning services (includes vSphere Replication & NFC)
$EnableVSphereReplication = $false        # vSphere Replication traffic
$EnableVSphereReplicationNFC = $false     # vSphere Replication NFC traffic
$EnableVSphereBackupNFC = $false          # vSphere Backup NFC traffic
$EnableNVMeTCP = $false                   # NVMe over TCP
$EnableNVMeRDMA = $false                  # NVMe over RDMA


# Helper function to convert CIDR notation to subnet mask
function ConvertCidrToSubnetMask {
    param([int]$Cidr)
    
    $mask = [IPAddress]([UInt32]::MaxValue -shl (32 - $Cidr) -shr (32 - $Cidr))
    return $mask.ToString()
}

# Load the PowerCLI module if not already loaded
if (-not (Get-Module -Name VMware.VimAutomation.Core)) {
    Import-Module VMware.VimAutomation.Core
}

# Set PowerCLI configuration to ignore invalid certificates
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null

# Get the vCenter Server address, username and password as PSCredential
$vCenterServer = Read-Host "Enter vCenter Server host name (DNS with FQDN or IP address)"
$vCenterUser = Read-Host "Enter your user name (DOMAIN\User or user@domain.com)"
$vCenterUserPassword = Read-Host "Enter your password (this will be converted to a secure string)" -AsSecureString:$true
$Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $vCenterUser,$vCenterUserPassword

# Connect to the vCenter Server with collected credentials
Connect-VIServer -Server $vCenterServer -Credential $Credentials | Out-Null
Write-Host "Connected to your vCenter server $vCenterServer" -ForegroundColor Green

# Extract domain suffix from vCenter Server if it's an FQDN
$domainSuffix = ""
if ($vCenterServer -match '\.(.+)$') {
    $domainSuffix = $Matches[1]
    Write-Host "Detected domain suffix: $domainSuffix" -ForegroundColor Cyan
}

# Verify CSV file exists
if (-not (Test-Path -Path $CsvPath)) {
    Write-Host "CSV file not found at path: $CsvPath" -ForegroundColor Red
    Disconnect-VIServer -Server * -Confirm:$false
    exit
}

# Determine CSV delimiter (comma or semicolon)
$csvContent = Get-Content -Path $CsvPath -Raw
$delimiter = if ($csvContent -match ";") { ";" } else { "," }

# Import CSV using detected delimiter
$vmkernelConfigs = Import-Csv -Path $CsvPath -Delimiter $delimiter

# Initialize counters
$successCount = 0
$failCount = 0
$skippedCount = 0

Write-Host "Starting VMkernel adapter creation based on CSV file: $CsvPath" -ForegroundColor Cyan
Write-Host "Detected delimiter: '$delimiter'" -ForegroundColor Cyan
Write-Host "Found $($vmkernelConfigs.Count) entries to process" -ForegroundColor Cyan
Write-Host "Default Network Stack: $DefaultNetworkStack" -ForegroundColor Cyan
Write-Host "Enabled services: " -NoNewline -ForegroundColor Cyan
if ($EnableVMotion) { Write-Host "vMotion " -NoNewline -ForegroundColor Yellow }
if ($EnableFT) { Write-Host "FT " -NoNewline -ForegroundColor Yellow }
if ($EnableMgmt) { Write-Host "Management " -NoNewline -ForegroundColor Yellow }
if ($EnableVSAN) { Write-Host "VSAN " -NoNewline -ForegroundColor Yellow }
if ($EnableVSANWitness) { Write-Host "VSAN Witness " -NoNewline -ForegroundColor Yellow }
if ($EnableVSphereReplication) { Write-Host "vSphere Replication " -NoNewline -ForegroundColor Yellow }
if ($EnableVSphereReplicationNFC) { Write-Host "vSphere Replication NFC " -NoNewline -ForegroundColor Yellow }
if ($EnableVSphereBackupNFC) { Write-Host "vSphere Backup NFC " -NoNewline -ForegroundColor Yellow }
if ($EnableNVMeTCP) { Write-Host "NVMe TCP " -NoNewline -ForegroundColor Yellow }
if ($EnableNVMeRDMA) { Write-Host "NVMe RDMA " -NoNewline -ForegroundColor Yellow }
if ($EnableProvisioning) { Write-Host "Provisioning " -NoNewline -ForegroundColor Yellow }
Write-Host ""

# Process each entry in the CSV
foreach ($config in $vmkernelConfigs) {
    $hostname = $config.hostname
    $portGroup = $config.portgroup
    $ipAddress = $config.ip
    
    # Ensure required fields are present
    if (-not $hostname -or -not $portGroup -or -not $ipAddress) {
        Write-Warning "Skipping row with missing data: $($config | Out-String)"
        $skippedCount++
        continue
    }
    
    try {
        # Get the ESXi host - first try with the hostname as provided
        Write-Host "Processing host: $hostname" -ForegroundColor Cyan
        $esxiHost = Get-VMHost -Name $hostname -ErrorAction SilentlyContinue
        
        # If not found and it doesn't include a dot (likely a short name), try with domain suffix
        if (-not $esxiHost -and -not $hostname.Contains(".") -and $domainSuffix) {
            $fqdn = "$hostname.$domainSuffix"
            Write-Host "  Host not found with short name, trying FQDN: $fqdn" -ForegroundColor Yellow
            $esxiHost = Get-VMHost -Name $fqdn -ErrorAction Stop
        }
        elseif (-not $esxiHost) {
            # If still not found, throw error
            throw "Host $hostname not found in vCenter inventory"
        }
        
        # Get the distributed port group
        Write-Host "  Looking for port group: $portGroup" -ForegroundColor Cyan
        $dvPortGroup = Get-VDPortgroup -Name $portGroup -ErrorAction Stop
        
        # Get the virtual switch associated with the distributed port group
        $vdSwitch = $dvPortGroup.VDSwitch
        Write-Host "  Found distributed switch: $($vdSwitch.Name)" -ForegroundColor Cyan
        
        # Create a hashtable for the VMkernel adapter configuration
        $vmkParams = @{
            VMHost = $esxiHost
            PortGroup = $dvPortGroup
            VirtualSwitch = $vdSwitch
            IP = $ipAddress
        }
        
        # Get subnet mask from IP if provided in CIDR notation, otherwise assume default
        if ($ipAddress -match "/\d+$") {
            $ipParts = $ipAddress -split "/"
            $vmkParams.IP = $ipParts[0]
            $cidr = [int]$ipParts[1]
            $subnetMask = ConvertCidrToSubnetMask -Cidr $cidr
            $vmkParams.SubnetMask = $subnetMask
        } elseif ($config.subnetmask) {
            $vmkParams.SubnetMask = $config.subnetmask
        } else {
            # Default subnet mask if not specified
            $vmkParams.SubnetMask = "255.255.255.0"
        }
        
        # Add gateway if provided
        if ($config.gateway) {
            $vmkParams.Gateway = $config.gateway
        }
        
        # Check if a VMkernel adapter with the same IP already exists
        $existingVMK = Get-VMHostNetworkAdapter -VMHost $esxiHost -VMKernel | Where-Object {$_.IP -eq $vmkParams.IP}
        if ($existingVMK) {
            Write-Host "  WARNING: A VMkernel adapter with IP $($vmkParams.IP) already exists on $hostname." -ForegroundColor Yellow
            Write-Host "  Will use the existing adapter for service configuration." -ForegroundColor Yellow
            $vmk = $existingVMK
        } else {
            # Determine which network stack to use (from CSV or default)
            $networkStackToUse = if ($config.networkstack) { $config.networkstack } else { $DefaultNetworkStack }
            Write-Host "  Creating VMkernel adapter with IP: $($vmkParams.IP), subnet: $($vmkParams.SubnetMask), network stack: $networkStackToUse" -ForegroundColor Cyan
            
            # Create the VMkernel adapter using the host network system API
            $hostNetworkSystem = Get-View $esxiHost.ExtensionData.ConfigManager.NetworkSystem
            
            # Create IP configuration
            $ipConfig = New-Object VMware.Vim.HostIpConfig
            $ipConfig.Dhcp = $false
            $ipConfig.IpAddress = $vmkParams.IP
            $ipConfig.SubnetMask = $vmkParams.SubnetMask
            if ($vmkParams.Gateway) {
                $ipConfig.DefaultGateway = $vmkParams.Gateway
            }
            
            # Create vnic spec
            $vnicSpec = New-Object VMware.Vim.HostVirtualNicSpec
            $vnicSpec.Ip = $ipConfig
            $vnicSpec.Mtu = 1500
            
            # Set network policy
            $vnicSpec.NetStackInstanceKey = $networkStackToUse
            
            # Create the VMkernel using HostNetworkSystem API
            try {
                # For distributed portgroups, we need to add via port group key 
                $dvPortgroupKey = $dvPortGroup.Key
                $hostNetworkSystem.AddVirtualNic($dvPortgroupKey, $vnicSpec)
                
                # Give vCenter a moment to register the new adapter
                Start-Sleep -Seconds 2
                
                # Retrieve the newly created VMkernel adapter
                $vmk = Get-VMHostNetworkAdapter -VMHost $esxiHost -VMKernel | Where-Object {$_.IP -eq $vmkParams.IP}
                
                if (-not $vmk) {
                    throw "Failed to find the VMkernel adapter after creation"
                }
            } catch {
                Write-Host "  WARNING: Failed to create VMkernel with network stack using direct API: $_" -ForegroundColor Yellow
                Write-Host "  Trying with standard PowerCLI method without network stack specified" -ForegroundColor Yellow
                $vmk = New-VMHostNetworkAdapter @vmkParams -Confirm:$false
            }
        }
        
        # Get the VMkernel adapter name
        $vmkName = $vmk.Name
        Write-Host "  Configuring services for VMkernel adapter: $vmkName" -ForegroundColor Cyan
        
        # Get the Virtual NIC Manager
        $vmkMgr = Get-View -Id $esxiHost.ExtensionData.ConfigManager.VirtualNicManager
        
        # Enable services using the VirtualNicManager API
        if ($EnableVMotion) {
            Write-Host "  Enabling vMotion service" -ForegroundColor Cyan
            try {
                $vmkMgr.SelectVnicForNicType("vmotion", $vmkName)
            } catch {
                Write-Host "  WARNING: Could not enable vMotion service: $_" -ForegroundColor Yellow
            }
        }
        
        if ($EnableMgmt) {
            Write-Host "  Enabling Management traffic service" -ForegroundColor Cyan
            try {
                $vmkMgr.SelectVnicForNicType("management", $vmkName)
            } catch {
                Write-Host "  WARNING: Could not enable Management traffic service: $_" -ForegroundColor Yellow
            }
        }
        
        if ($EnableFT) {
            Write-Host "  Enabling Fault Tolerance logging service" -ForegroundColor Cyan
            try {
                $vmkMgr.SelectVnicForNicType("faultToleranceLogging", $vmkName)
            } catch {
                Write-Host "  WARNING: Could not enable Fault Tolerance service: $_" -ForegroundColor Yellow
            }
        }
        
        if ($EnableVSAN) {
            Write-Host "  Enabling VSAN traffic service" -ForegroundColor Cyan
            try {
                $vmkMgr.SelectVnicForNicType("vsan", $vmkName)
            } catch {
                Write-Host "  WARNING: Could not enable VSAN traffic service: $_" -ForegroundColor Yellow
            }
        }
        
        if ($EnableVSANWitness) {
            Write-Host "  Enabling VSAN Witness service" -ForegroundColor Cyan
            try {
                $vmkMgr.SelectVnicForNicType("vsanwitness", $vmkName)
            } catch {
                Write-Host "  WARNING: Could not enable VSAN Witness service: $_" -ForegroundColor Yellow
            }
        }
        
        if ($EnableVSphereReplication) {
            Write-Host "  Enabling vSphere Replication service" -ForegroundColor Cyan
            try {
                $vmkMgr.SelectVnicForNicType("vSphereReplication", $vmkName)
            } catch {
                Write-Host "  WARNING: Could not enable vSphere Replication service: $_" -ForegroundColor Yellow
            }
        }
        
        if ($EnableVSphereReplicationNFC) {
            Write-Host "  Enabling vSphere Replication NFC service" -ForegroundColor Cyan
            try {
                $vmkMgr.SelectVnicForNicType("vSphereReplicationNFC", $vmkName)
            } catch {
                Write-Host "  WARNING: Could not enable vSphere Replication NFC service: $_" -ForegroundColor Yellow
            }
        }
        
        if ($EnableVSphereBackupNFC) {
            Write-Host "  Enabling vSphere Backup NFC service" -ForegroundColor Cyan
            try {
                $vmkMgr.SelectVnicForNicType("vsphereBackupNFC", $vmkName)
            } catch {
                Write-Host "  WARNING: Could not enable vSphere Backup NFC service: $_" -ForegroundColor Yellow
            }
        }
        
        if ($EnableProvisioning) {
            Write-Host "  Enabling Provisioning service" -ForegroundColor Cyan
            try {
                $vmkMgr.SelectVnicForNicType("vSphereProvisioning", $vmkName)
            } catch {
                Write-Host "  WARNING: Could not enable Provisioning service: $_" -ForegroundColor Yellow
            }
        }
        
        if ($EnableNVMeTCP) {
            Write-Host "  Enabling NVMe over TCP service" -ForegroundColor Cyan
            try {
                $vmkMgr.SelectVnicForNicType("nvmetcp", $vmkName)
            } catch {
                Write-Host "  WARNING: Could not enable NVMe over TCP service: $_" -ForegroundColor Yellow
            }
        }
        
        if ($EnableNVMeRDMA) {
            Write-Host "  Enabling NVMe over RDMA service" -ForegroundColor Cyan
            try {
                $vmkMgr.SelectVnicForNicType("nvmerdma", $vmkName)
            } catch {
                Write-Host "  WARNING: Could not enable NVMe over RDMA service: $_" -ForegroundColor Yellow
            }
        }
        
        $actualHostname = $esxiHost.Name
        Write-Host "Successfully processed VMkernel adapter on $actualHostname for $portGroup with IP $($vmkParams.IP)" -ForegroundColor Green
        $successCount++
    }
    catch {
        Write-Host "Failed to process VMkernel adapter on $hostname for $portGroup $_" -ForegroundColor Red
        $failCount++
    }
}

# Display summary
Write-Host "`nSummary:" -ForegroundColor Cyan
Write-Host "Successfully processed $successCount VMkernel adapters" -ForegroundColor Green
Write-Host "Failed to process $failCount VMkernel adapters" -ForegroundColor Red
Write-Host "Skipped $skippedCount configurations due to incomplete data" -ForegroundColor Yellow

# Disconnect from vCenter server
Write-Host "Script execution complete. Disconnecting from vCenter Server..." -ForegroundColor Cyan
Disconnect-VIServer -Server * -Confirm:$false
