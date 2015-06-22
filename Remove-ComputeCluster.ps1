#Add-AzureAccount

# Initialize variables
$subscriptionName = 'Microsoft Azure Subscription'
$storageAccount = 'cluster1stor1'
$serviceName = 'cluster1'

# Set the current subscription and storage account
Select-AzureSubscription -SubscriptionName $subscriptionName
Set-AzureSubscription -SubscriptionName $subscriptionName -CurrentStorageAccount $storageAccount

# Remove the master nodes
$masterVMName = 'cluster1master'
$numMasterVMs = 3
for ($x=1; $x -le $numMasterVMs; $x++)
{
    $vmName = $masterVMName + $x
    Remove-AzureVM -Name $vmName -ServiceName $serviceName -DeleteVHD      
}

# Remove the compute nodes
$computeVMName = 'cluster1comp'
$numComputeVMs = 9
for ($x=1; $x -le $numComputeVMs; $x++)
{
    $vmName = $computeVMName + $x
    Remove-AzureVM -Name $vmName -ServiceName $serviceName -DeleteVHD      
}
