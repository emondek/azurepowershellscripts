#Add-AzureAccount

# Initialize variables: Change these to match your Azure environment 
$subscriptionName = 'Microsoft Azure Subscription' 
$storageAccount = 'pedrorodmsihdpstor'
$numStorageAccounts = 4
$serviceName = 'msihdp'
$vnetName = 'msihdpvnet'
$subnetName = 'Subnet-1'
$location = 'East US'
$imageName = '5112500ae3b842c8b9c604889f8753c3__OpenLogic-CentOS-66-20150605'
$userName = 'msiadmin'
$password = 'msihdp123!'
$type = 'Standard_LRS' #if you want premium storage, change this
$Container = 'vhds'

# Set the current subscription and storage account
Select-AzureSubscription -SubscriptionName $subscriptionName

# OPTIONAL: Create service account and storage accounts. Comment thes out if you already have these
$storageAccounts = @()
$containerUris = @()

for ($i=1;$i -le $numStorageAccounts;$i++)
{
    Write-Output "Creating Azure Storage Account: $storageAccount$i"
    $storageAccountName = $storageAccount + $i
    New-AzureStorageAccount -StorageAccountName $storageAccountName -Location $location -Type $type
    Set-AzureSubscription -SubscriptionName $subscriptionName -CurrentStorageAccount $storageAccountName
    $storageAccounts += $storageAccountName
    Write-Output "Creating Azure Blob Storage Container: $Container"
    New-AzureStorageContainer -Name $Container -Permission Off 
    $blobContainer = Get-AzureStorageContainer -Name $Container
    $containerUris += $blobContainer.CloudBlobContainer.Uri.ToString()
}
Write-Output "Creating Azure Cloud Service: $serviceName"
New-AzureService -ServiceName $serviceName -Location $location 

Set-AzureSubscription -SubscriptionName $subscriptionName -CurrentStorageAccount $storageAccounts[0]


# Create the master nodes
$masterVMName = 'msihdpmaster'
$numMasterVMs = 3
$masterVMSize = 'Standard_D13'
$masterAVSetName = 'msihdpmaster'
$diskSize = 1000
$diskLabel = 'datadisk1'
$sshPort = 57700
$currentStorageAccount = $containerUris[0]

$count = 1
[hashtable]$Param=@{}

#Bash script used to format data disks. See https://gist.github.com/trentmswanson/9c22bb71182e982bd36f before executing to verify contents. 
#$fileUris = @("https://gist.githubusercontent.com/trentmswanson/9c22bb71182e982bd36f/raw/47330d83bd884e88ef56edf5dae5597a1d989554/autopart.sh")

#I modified the autopart.sh file to use lazy initialization of the disk for the format. Otherwise, large disk format with the original Bash script can cause a timeout of the extension
$fileUris = @("https://pedrorodmsihdpstor.blob.core.windows.net/scripts/autopart.sh")
$commandToExecute = 'bash autopart.sh'
$Param['fileUris'] = $fileUris
$Param['commandToExecute'] = 'bash autopart.sh'
$Param['timeStamp'] = (Get-Date).Ticks
$PublicConfiguration = ConvertTo-Json $Param
$extensionName = 'CustomScriptForLinux'
$Publisher= 'Microsoft.OSTCExtensions'
$Version='1.1'

for ($x=1; $x -le $numMasterVMs; $x++)
{
    $vmName = $masterVMName + $x
    $osDisk = $currentStorageAccount + '/' + $vmName + '-os-1.vhd'
    $dataDisk = $currentStorageAccount + '/' + $vmName + '-data-1.vhd'
    
    Write-Output "Creating VM: $vmName"
    
    New-AzureVMConfig -Name $vmName -InstanceSize $masterVMSize -ImageName $imageName -AvailabilitySetName $masterAVSetName -MediaLocation $osDisk | `
        Add-AzureProvisioningConfig -Linux -LinuxUser $userName -Password $password | `
        Set-AzureEndpoint -Name 'SSH' -PublicPort ($sshPort + $x) | `
        Set-AzureSubnet $subnetName | `
        Add-AzureDataDisk -CreateNew -DiskSizeInGB $diskSize -DiskLabel $diskLabel -LUN 0 -MediaLocation $dataDisk | `
        Set-AzureVMExtension -ExtensionName $extensionName -Publisher $Publisher -Version $Version -PublicConfiguration $PublicConfiguration | `
        New-AzureVM -ServiceName $serviceName -VNetName $vnetName            
    
}

# Create the compute nodes
$computeVMName = 'msihdpcomp'
$numComputeVMs = 9
$computeVMSize = 'Standard_D13'
$computeAVSetName = 'msihdpcomp'
$numDataDisks = 8
$diskSize = 1000
$diskLabel = 'datadisk'
$sshPort = 57800
$currentStorageAccount = $containerUris[1]
$count = 1


for ($x=1; $x -le $numComputeVMs; $x++)
{
    $vmName = $computeVMName + $x
    $osDisk = $currentStorageAccount + '/' + $vmName + '-os-1.vhd'
    $dataDisk = $currentStorageAccount + '/' + $vmName + '-data-'

    $vmConfig = New-AzureVMConfig -Name $vmName -InstanceSize $computeVMSize -ImageName $imageName -AvailabilitySetName $computeAVSetName -MediaLocation $osDisk | `
        Add-AzureProvisioningConfig -Linux -LinuxUser $userName -Password $password | `
        Set-AzureEndpoint -Name 'SSH' -PublicPort ($sshPort + $x) | `
        Set-AzureVMExtension -ExtensionName $extensionName -Publisher $Publisher -Version $Version -PublicConfiguration $PublicConfiguration |`
        Set-AzureSubnet $subnetName

    for ( $y = 1; $y -le $numDataDisks; $y++ ) {

        $vmConfig = $vmConfig | Add-AzureDataDisk -CreateNew -DiskSizeInGB $diskSize -DiskLabel ($diskLabel + $y) -LUN ($y - 1) -MediaLocation ($dataDisk + $y + '.vhd')

    }
    Write-Output "Creating VM $vmname"
    New-AzureVM -ServiceName $serviceName -VMs $vmConfig -VNetName $vnetName

       
    # Provision 3 VMs per storage account
    $count++
    if ($count -eq 4) {
        $currentStorageAccount = $containerUris[2]
    } elseif ($count -eq 7) {
        $currentStorageAccount = $containerUris[3]
    }
        
}
