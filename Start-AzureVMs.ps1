# Connect to your Azure account (only needed when your token has expired)
#Add-AzureAccount

# Initialize variables
$subscriptionName = '<Subscription Name>'
$servicename = '<Service Name>'
$vms = '<VM 1>', '<VM 2>', '<VM 3>', '<VM N>'

# Set the current subscription
Select-AzureSubscription -SubscriptionName $subscriptionName

# Virtual Machines -> start
foreach ($vm in $vms)
{
    Start-AzureVM -Name $vm -ServiceName $servicename
}
