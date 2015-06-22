#Add-AzureAccount

# Initialize variables
$subscriptionName = 'Microsoft Azure Subscription'
$storageAccount = 'cluster1stor1'
$serviceName = 'cluster1'
$vnetName = 'cluster1vnet'
$subnetName = 'Subnet-1'
$location = 'West US'
$imageName = '5112500ae3b842c8b9c604889f8753c3__OpenLogic-CentOS-66-20150605'
$userName = 'clusteradmin'
$password = 'cluster123!'
$cluster1stor1 = 'https://cluster1stor1.blob.core.windows.net/vhds'
$cluster1stor2 = 'https://cluster1stor2.blob.core.windows.net/vhds'
$cluster1stor3 = 'https://cluster1stor3.blob.core.windows.net/vhds'
$cluster1stor4 = 'https://cluster1stor4.blob.core.windows.net/vhds'

# Set the current subscription and storage account
Select-AzureSubscription -SubscriptionName $subscriptionName
Set-AzureSubscription -SubscriptionName $subscriptionName -CurrentStorageAccount $storageAccount

# Create the master nodes
$masterVMName = 'cluster1master'
$numMasterVMs = 3
$masterVMSize = 'Standard_D13'
$masterAVSetName = 'cluster1master'
$diskSize = 1000
$diskLabel = 'datadisk1'
$sshPort = 57700
$currentStorageAccount = $cluster1stor1
$count = 1
for ($x=1; $x -le $numMasterVMs; $x++)
{
    $vmName = $masterVMName + $x
    $osDisk = $currentStorageAccount + '/' + $vmName + '-os-1.vhd'
    $dataDisk = $currentStorageAccount + '/' + $vmName + '-data-1.vhd'

    New-AzureVMConfig -Name $vmName -InstanceSize $masterVMSize -ImageName $imageName -AvailabilitySetName $masterAVSetName -MediaLocation $osDisk | `
        Add-AzureProvisioningConfig -Linux -LinuxUser $userName -Password $password | `
        Set-AzureEndpoint -Name 'SSH' -PublicPort ($sshPort + $x) | `
        Set-AzureSubnet $subnetName | `
        Add-AzureDataDisk -CreateNew -DiskSizeInGB $diskSize -DiskLabel $diskLabel -LUN 0 -MediaLocation $dataDisk | `
        New-AzureVM -ServiceName $serviceName -VNetName $vnetName       
}

# Create the compute nodes
$computeVMName = 'cluster1comp'
$numComputeVMs = 9
$computeVMSize = 'Standard_D13'
$computeAVSetName = 'cluster1comp'
$numDataDisks = 8
$diskSize = 1000
$diskLabel = 'datadisk'
$sshPort = 57800
$currentStorageAccount = $cluster1stor2
$count = 1
for ($x=1; $x -le $numComputeVMs; $x++)
{
    $vmName = $computeVMName + $x
    $osDisk = $currentStorageAccount + '/' + $vmName + '-os-1.vhd'
    $dataDisk = $currentStorageAccount + '/' + $vmName + '-data-'

    $vmConfig = New-AzureVMConfig -Name $vmName -InstanceSize $computeVMSize -ImageName $imageName -AvailabilitySetName $computeAVSetName -MediaLocation $osDisk | `
        Add-AzureProvisioningConfig -Linux -LinuxUser $userName -Password $password | `
        Set-AzureEndpoint -Name 'SSH' -PublicPort ($sshPort + $x) | `
        Set-AzureSubnet $subnetName

    for ( $y = 1; $y -le $numDataDisks; $y++ ) {

        $vmConfig = $vmConfig | Add-AzureDataDisk -CreateNew -DiskSizeInGB $diskSize -DiskLabel ($diskLabel + $y) -LUN ($y - 1) -MediaLocation ($dataDisk + $y + '.vhd')

    }

    New-AzureVM -ServiceName $serviceName -VMs $vmConfig -VNetName $vnetName

    # Provision 3 VMs per storage account
    $count++
    if ($count -eq 4) {
        $currentStorageAccount = $cluster1stor3
    } elseif ($count -eq 7) {
        $currentStorageAccount = $cluster1stor4
    }
        
}
