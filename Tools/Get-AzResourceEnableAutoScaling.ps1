# Connecting to Azure account 
Connect-AzAccount -DeviceCode

# Get all subscriptions
$subscriptions = Get-AzSubscription

# Define the desired resource types
$resourceTypes = "Microsoft.Compute/virtualMachineScaleSets", "Microsoft.ContainerService/managedClusters", "Microsoft.Web/sites"

# Create an empty list to store the results
$results = @()

# For each subscription, list the resource groups and resources
foreach ($subscription in $subscriptions) {
    # Select the current subscription
    Select-AzSubscription -SubscriptionId $subscription.Id

    # List the resource groups
    $groups = Get-AzResourceGroup

    # For each resource group, list the resources that match the desired types or that have the enableAutoScaling property
    foreach ($group in $groups) {
        $resources = Get-AzResource -ResourceGroupName $group.ResourceGroupName | Where-Object { $resourceTypes -contains $_.ResourceType -or $_.Properties.enableAutoScaling -eq $true }
        foreach ($resource in $resources) {
            # Create a custom object with the desired properties
            $result = [PSCustomObject]@{
                Subscription     = $subscription.Name
                ResourceGroup    = $group.ResourceGroupName
                ResourceName     = $resource.Name
                ResourceType     = $resource.ResourceType
                ResourceLocation = $resource.Location
            }
            # Add the object to the list of results
            $results += $result
        }
    }
}

# Make sure the ImportExcel module is installed and install it if necessary
if (-not (Get-Module -Name ImportExcel -ListAvailable)) {

    $install = Read-Host -Prompt "The ImportExcel module is not installed. Do you want to install it now? (Y/N)"

    if ($install -eq "Y") {

        Install-Module -Name ImportExcel -Scope CurrentUser -Force -AllowClobber
        Import-Module -Name ImportExcel -Force
        Write-Host "The ImportExcel module was installed successfully."

    } else {

        Write-Host "The ImportExcel module is required to export the results to an Excel file. Please install it and run the script again."
        Exit
    }
}

# Export the list of results to an xlsx file
$results | Export-Excel -Path C:\Temp\ResourcesScallingEnabled.xlsx -AutoSize -FreezeTopRow -BoldTopRow
