#  Powershell script for changing the SQL Server license type across multiple subscriptions
This Powershell scripts are designed for changing the license type of all SQL Servers deloyed across multiple subscriptions, from Azure Hybrid Benefit to Pay as You Go. It supports **Azure SQL on VM**, **Azure SQL Database**, **Azure SQL Elastic Pool**, **Azure SQL Managed Instance** and **Azure SQL Managed Instance Pool**.


##  Step 1: Install the Azure PowerShell Module
    If you haven't install the following Azure PowerShell module, please send these commands:
```
    Install-Module -Name Az.Accounts -AllowClobber -Force
    Install-Module -Name Az.Sql -AllowClobber -Force
    Install-Module -Name Az.Compute -AllowClobber -Force
```

##  Step 2: Verify the Installation
Verify the modules are installed completely by sending these commands:
```
Get-Module -ListAvailable -Name Az.Sql
Get-Module -ListAvailable -Name Az.Accounts
Get-Module -ListAvailable -Name Az.Compute
```   

##  Step 3: Single sign-on with your Azure account
Send "Connect-AzAccount" command to sign on with your browser, you may need to have Azure Subscription Reader role or corresponding role privilege above.

```
Connect-AzAccount -TenantId "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyy"
``` 

##  Step 4: Modify the sublist.txt
Edit the **sublist.txt** and place your subscription name and id after the 1st header row "SubscriptionName", "SubscriptionId"
```
"SubscriptionName", "SubscriptionId", "TenantId"
your-sub-name1, xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxx1, yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyy
your-sub-name2, xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxx2, yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyy
```  

##  Step 5: Execute the checksqlahb.ps1 for checking
Open powershell, locate to the script folder, execute  [checksqlahb](checksqlahb.ps1)
``` 
.\checksqlahb.ps1
``` 

Change the license may takes 1-2 minutues for each SQL Server approximately. Please be patient if your subscriptions have a lot of resources.

After you see "Discovery and disablement completed", you can check the **findallsqlsvr.txt** for all SQL Servers discovery. You also can check the **findahbonly.txt** which only list out all kinds of SQL resources with Azure Hybrid Benefit enabled.    

##  Step 6: Execute the confirmsqlahb.ps1 for change all Azure Hybrid Benefit to PayGO
If you confirm to change all the SQL Servers listed in the **findallsqlsvr.txt** from Azure Hybrid Benefit to Pay as you go, then execute  [confirmsqlahb](confirmsqlahb.ps1)

``` 
.\confirmsqlahb.ps1
``` 

After you see "Discovery and disablement completed", you can check the **resultpaygo.txt** for results.
