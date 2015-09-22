#Add-AzureAccount

# Initialize variables
$subscriptionName = 'Microsoft Azure Subscription' 
$serviceName = 'msihdp'

# Set the current subscription and storage account
Select-AzureSubscription -SubscriptionName $subscriptionName
Set-AzureSubscription -SubscriptionName $subscriptionName 
# Remove the master nodes
$masterVMName = 'msihdpmaster'
$numMasterVMs = 3
for ($x=1; $x -le $numMasterVMs; $x++)
{
    $vmName = $masterVMName + $x
    Write-Output "Removing VM $vmName"
    Remove-AzureVM -Name $vmName -ServiceName $serviceName -DeleteVHD      
}

# Remove the compute nodes
$computeVMName = 'msihdpcomp'
$numComputeVMs = 9
for ($x=1; $x -le $numComputeVMs; $x++)
{
    $vmName = $computeVMName + $x
    Write-Output "Removing VM $vmName"
    Remove-AzureVM -Name $vmName -ServiceName $serviceName -DeleteVHD      
}
