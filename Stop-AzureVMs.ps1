# Connect to your Azure account (only needed when your token has expired)
#Add-AzureAccount

# Initialize variables
$subscriptionName = '<Subscription Name>'
$servicename = '<Service Name>'
$vms = '<VM 1>', '<VM 2>', '<VM 3>', '<VM N>'
 
# Set the current subscription
Select-AzureSubscription -SubscriptionName $subscriptionName

# Virtual Machines -> shutdown and de-provision
foreach ($vm in $vms)
{
    Stop-AzureVM -ServiceName $servicename -Name $vm -Force
}