<#
.SYNOPSIS
   Moves all the virtual machines in the specified cloud service to the specified virtual
   network.
.DESCRIPTION
   This script is commonly used to move virtual machines from a legacy virtual network 
   to a new regional virtual network so that you can take advantage of new capabilities 
   such as internal load balancing and virtual network to virtual network connectivity.
   
   Please note that A8/A9 virtual machine sizes also require regional virtual networks but
   have three additional requirements.  First, they need to be provisioned inside a cloud
   service that is created with a new affinity group (or by location).  Second, the existing
   virtual machine instance needs to be deleted and re-provisioned as A8/A9.  You cannot
   re-size existing VM instances to A8/A9.  Third, a cloud service can only contain virtual
   machines of size A8/A9.  You can not mix A8/A9 with other virtual machine sizes in the same
   cloud service.  Therefore, please use the Resize-AzureVM cmdlet to resize virtual machines.
.EXAMPLE
  .\Move-AzureVMToVnet.ps1 -ServiceName 'myservicename' -VNetName 'myvnet'
#>
param
(
    # Name of the Cloud Service that contains the VM's to be moved
    [Parameter(Mandatory = $true)]
    [String]
    $ServiceName,

    # Name of the the virtual network where the VM's will be moved
    [Parameter(Mandatory = $true)]
    [String]
    $VNetName
)

# The script has been tested on Powershell 3.0
Set-StrictMode -Version 3

# Following modifies the Write-Verbose behavior to turn the messages on globally for this session
$VerbosePreference = "Continue"

# Check if Windows Azure Powershell is avaiable
if ((Get-Module -ListAvailable Azure) -eq $null)
{
    throw "Windows Azure Powershell not found! Please install from http://www.windowsazure.com/en-us/downloads/#cmd-line-tools"
}

$pathprefix = 'c:\vms\' + $ServiceName + '\'

# Create the directory for export files if it doesn't already exist
$pathExists = Test-Path -Path $pathprefix
if ($pathExists -eq $False) {
    New-Item -Path $pathprefix -Type directory
}

# Export all the VMs in the cloud service
$vms = Get-AzureVM -ServiceName $ServiceName
foreach ($vm in $vms) { 
    $path = $pathprefix + $vm.Name + '.xml'
    Export-AzureVM -ServiceName $ServiceName -Name $vm.Name -Path $path
}

# Delete all virtual machines (but not the cloud service or disks)
Remove-AzureDeployment -ServiceName $ServiceName -Slot Production -Force

# Check if the VMs are still attached to their disks
foreach ($vm in $vms) {
    while ((Get-AzureDisk -DiskName $vm.VM.OSVirtualHardDisk.DiskName).AttachedTo -ne $null) {
        Start-Sleep -Seconds 30
    }
    $dataDisks = $vm.VM.DataVirtualHardDisks
    foreach ($dataDisk in $dataDisks) {
        while ((Get-AzureDisk -DiskName $dataDisk.DiskName).AttachedTo -ne $null) {
            Start-Sleep -Seconds 30
        }
    }
}

# Provision the virtual machines on the new virtual network
$vms = @()
Get-ChildItem $pathprefix | foreach {
                $path = $pathprefix + $_
                $vms += Import-AzureVM -Path $path
}
New-AzureVM -ServiceName $ServiceName -VMs $vms -VNetName $VNetName
