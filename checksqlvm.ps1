param (
    [string]$Mode = "read"  # Default to "read" if no parameter is provided
)

# Ensure the required modules are imported
if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
    Install-Module -Name Az.Accounts -AllowClobber -Force
}
Import-Module Az.Accounts

if (-not (Get-Module -ListAvailable -Name Az.Sql)) {
    Install-Module -Name Az.Sql -AllowClobber -Force
}
Import-Module Az.Sql

if (-not (Get-Module -ListAvailable -Name Az.Compute)) {
    Install-Module -Name Az.Compute -AllowClobber -Force
}
Import-Module Az.Compute

<#
# Ensure proper login
$TenantId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx"
try {
    Connect-AzAccount -TenantId $TenantId -ErrorAction Stop
} catch {
    Write-Output "Failed to authenticate. Please ensure you are logged in with the correct account."
    exit
}
#>
# Import the list of subscriptions from sublist.txt
$subscriptions = Import-Csv -Path "sublist.txt" -Delimiter ',' -Header "SubscriptionName", "SubscriptionId", "TenantId" | Select-Object -Skip 1

# Initialize the output files
$outputFile = "allsqlvm.csv"
if (Test-Path $outputFile) {
    Remove-Item $outputFile
}
New-Item -Path $outputFile -ItemType File

# Function to log discovery details
function LogDiscovery {
    param (
        [string]$SqlName,    
        [string]$ResourceGroup,
        [string]$vCores,
        [string]$LicenseType,
        [string]$sqlImageOffer,
        [string]$sqlImageSku,
        [string]$Region,
        [string]$SubscriptionName,
        [string]$CreateDate
    )
    $logEntry = "$SqlName, $ResourceGroup, $vCores, $LicenseType, $sqlImageOffer, $sqlImageSku, $Region, $SubscriptionName, $CreateDate"
    Add-Content -Path $outputFile -Value $logEntry
}

LogDiscovery -SqlName "NAME" -ResourceGroup "RESOURCE GROUP" -vCore "vCores" -LicenseType "LICENSE TYPE" -sqlImageOffer "VERSION" -sqlImageSku "EDITION" -Region "LOCATION" -SubscriptionName "SUBSCRIPTION" -CreateDate "CREATEDATE"
Write-Output "$(Get-Date -Format HH:mm:ss) Job started"

# Loop through each subscription
foreach ($subscription in $subscriptions) {
    Write-Output "$(Get-Date -Format HH:mm:ss) Processing subscriptions: $($subscription.SubscriptionName)"
    $SubscriptionId = $subscription.SubscriptionId
    $SubscriptionName = $subscription.SubscriptionName
    $TenantId = $subscription.TenantId

    # Check if SubscriptionId or SubscriptionName is empty
    if ([string]::IsNullOrEmpty($SubscriptionId) -or [string]::IsNullOrEmpty($SubscriptionName)) {
        Write-Output "Error: Missing SubscriptionId or SubscriptionName"
        break
    }

    try {
        # Debug output to check the subscription details
        Write-Output "Setting context for Subscription: $SubscriptionName ($SubscriptionId)"

        # Set the current subscription context
        Set-AzContext -TenantId $TenantId -SubscriptionName $SubscriptionName -ErrorAction Stop

        # Discover SQL Virtual Machines
        Write-Output "$(Get-Date -Format HH:mm:ss) Processing SQL Virtual Machines"
        $sqlVms = Get-AzResource -ResourceType "Microsoft.SqlVirtualMachine/sqlVirtualMachines" -ExpandProperties
        foreach ($sqlVm in $sqlVms) {
            $sqlVmProperties = $sqlVm.Properties
            $licenseType = $sqlVmProperties.sqlServerLicenseType
            $sqlImageOffer = $sqlVmProperties.sqlImageOffer
            $virtualMachineResourceId = $sqlVmProperties.virtualMachineResourceId
            $sqlImageSku = $sqlVmProperties.sqlImageSku

            # Fetch VM properties using PowerShell
            $vmProperties = Get-AzResource -ResourceId $virtualMachineResourceId

            # Get the hardwareProfile
            $hardwareProfile = $vmProperties.Properties.HardwareProfile

            # Get the vmSize
            $vCores = $hardwareProfile.VmSize
            # Extract the second digit from the VM size string
            if ($vCores -match "Standard_([A-Z])(\d+)") {
                $vCores = [int]$matches[2]
            }

            $CreateDate = $vmProperties.Properties.timeCreated

            if ($LicenseType -eq "AHUB") {
                $LicenseType = "Azure Hybrid Benefit"
            }

            LogDiscovery -SqlName $sqlVm.Name -ResourceGroup $sqlVm.ResourceGroupName -vCores $vCores -LicenseType $LicenseType -sqlImageOffer $sqlImageOffer -sqlImageSku $sqlImageSku -Region $sqlVm.location -SubscriptionName $SubscriptionName -CreateDate $CreateDate
        }

    } catch {
        Write-Output "Failed to set context for subscription $SubscriptionId. Error: $_"
    }
}

Write-Output "$(Get-Date -Format HH:mm:ss) Discovery is completed. Please check the allsqlvm.csv files for details."
