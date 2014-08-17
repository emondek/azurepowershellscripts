<#
.SYNOPSIS
   Resize the specified VM to A8 or A9.
.DESCRIPTION
   Please note that A8/A9 virtual machine sizes have a few requirements.  First, they can only
   be provisioned on regional virtual networks.  If you specify a legacy virtual network
   (i.e. one that is associated with an affinity group) then the script will throw an error.
   Second, A8/A9 virtual machine sizes need to be provisioned inside a cloud
   service that is created by location or with a new affinity group (i.e. one that has never
   contained a non-A8/A9 virtual machine size).  Third, the existing virtual
   machine instance needs to be deleted and re-provisioned as A8/A9.  You cannot re-size
   existing VM instances.  Fourth, a cloud service can only contain virtual machines of size
   A8/A9.  You can not mix A8/A9 with other virtual machine sizes in the same cloud service.
.EXAMPLE
  .\Resize-AzureVM.ps1 -SourceServiceName 'mysourceservicename' -DestinationServiceName 'mydestinationservicename' `
     -Name 'myvm' -VNetName 'myvnet' -InstanceSize A8
#>
param
(
    # Name of the Source Cloud Service that contains the VM to be resized
    [Parameter(Mandatory = $true)]
    [String]
    $SourceServiceName,

    # Name of the Destination Cloud Service where the VM will be provisioned and resized
    [Parameter(Mandatory = $true)]
    [String]
    $DestinationServiceName,

    # Name of the VM to be resized
    [Parameter(Mandatory = $true)]
    [String]
    $Name,

    # Name of the the virtual network that the VM is attached to
    [Parameter(Mandatory = $true)]
    [String]
    $VNetName,

    # VM size
    [Parameter(Mandatory = $true)]
    [String]
    $InstanceSize
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

$pathprefix = 'c:\vms\' + $SourceServiceName + '\'

# Create the directory for export files if it doesn't already exist
$pathExists = Test-Path -Path $pathprefix
if ($pathExists -eq $False) {
    New-Item -Path $pathprefix -Type directory
}

# Export the VM config
$path = $pathprefix + $Name + '.xml'
Export-AzureVM -ServiceName $SourceServiceName -Name $Name -Path $path

# Get the VM object so that we can check when the disks are released
$vm = Get-AzureVM -ServiceName $SourceServiceName -Name $Name

# Delete the VM (but not the disks)
Remove-AzureVM -ServiceName $SourceServiceName -Name $Name

# Check if the VM is still attached to the disks
while ((Get-AzureDisk -DiskName $vm.VM.OSVirtualHardDisk.DiskName).AttachedTo -ne $null) {
    Start-Sleep -Seconds 30
}
$dataDisks = $vm.VM.DataVirtualHardDisks
foreach ($dataDisk in $dataDisks) {
    while ((Get-AzureDisk -DiskName $dataDisk.DiskName).AttachedTo -ne $null) {
        Start-Sleep -Seconds 30
    }
}

# Provision and re-size the VM in the Destination Cloud Service
$vm = Import-AzureVM -Path $path
Set-AzureVMSize -VM $vm -InstanceSize $InstanceSize
New-AzureVM -ServiceName $DestinationServiceName -VMs $vm -VNetName $VNetName
