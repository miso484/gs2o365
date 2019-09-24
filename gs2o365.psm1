<#
 .Synopsis
  Create Office365 users.
 .Description
  Connect to Office365 and create Office365 users specified in csv file.
 .Parameter O365AdminAccount
  Office 365 account with admin privilegies (Mandatory).
 .Parameter csvPath
  Path to csv file with users for import (Mandatory).
 .Parameter MSOnlineMinVersion
  Minimum Version for MSOnline PowerShell Module.
 .Parameter ValidateMOSSA
  Validate if Microsoft Online Services Sign-in Assistant is installed (Yes|No).
 .Parameter WhatIf
  Shows what would happen if the cmdlet runs. The cmdlet is not run.
  .Example
   # Create Office 365 users connecting with other admin account and different csv path and name.
   Add-O365Users -O365AdminAccount "adminuser@domain.com" -csvPath "C:\PathTo\NewUsers.csv" -ValidateMOSSA yes -Verbose
#>
function Add-O365Users {
    [CmdletBinding(SupportsShouldProcess = $true, confirmImpact = 'High')]
    param(
        [Parameter(Mandatory=$true)]
        [string] $O365AdminAccount,
        [Parameter(Mandatory=$true)]
        [string] $csvPath,
        [string] $MSOnlineMinVersion = '1.1.183.17',
        [ValidateSet('Yes', 'No')][string] $ValidateMOSSA
    )
    if (!$ValidateMOSSA) {
        $ValidateMOSSA = Read-Host -Prompt 'Have you installed Microsoft Online Services Sign-in Assistant (Yes|No):'
    }
    switch ($ValidateMOSSA.ToLower()) {
        "yes" { 
            ## Install MSOnline powershell module
            Write-Verbose "Installing MSOnline PowerShell module ..."
            if (!(Get-Module -Name MSOnline)) {
                Find-Module -Name MSOnline | Format-List
                Install-Module -Name MSOnline -MinimumVersion $MSOnlineMinVersion -Force -Verbose
                Get-Command -Module MSOnline
            }
    
            ## Connect to Office365
            Write-Verbose "Connecting to Office365 ..."
            Get-Credential $O365AdminAccount | Export-Clixml C:\O365Credential.xml
            $cred = Import-Clixml C:\O365Credential.xml
            Connect-MsolService -Credential $cred
            Remove-Item C:\O365Credential.xml

            ## Create users via a CSV file
            Write-Verbose "Creating users via a CSV file ..."
            Import-Csv -Path "$csvPath" |
            ForEach-Object {
                New-MsolUser -DisplayName $_.DisplayName -FirstName $_.FirstName -LastName $_.LastName -UserPrincipalName $_.UserPrincipalName -UsageLocation $_.UsageLocation -LicenseAssignment $_.AccountSkuId -Verbose
            } |
            Export-Csv -Path "$(Split-Path $csvPath)\O365Users_Results.csv"
            #Remove-Item -Path "$(Split-Path $csvPath)\O365Users_Results.csv"
        }
        "no" { 
            Write-Host "Install Microsoft Online Services Sign-in Assistant: https://www.microsoft.com/en-us/download/details.aspx?id=41950"
            Break
        }
        Default { 
            Write-Host "Valid answers are Yes or No, try again"
            Break
        }
    }
}

<#
 .Synopsis
  Remove Office365 accounts.
 .Description
  Remove to Office365 and create Office365 accounts specified in import csv file.
 .Parameter MSOnlineMinVersion
  Minimum Version for MSOnline PowerShell Module.
 .Parameter O365AdminAccount
  Office 365 account with admin privilegies.
 .Parameter csvPath
  Path to csv file with users for removal.
 .Parameter ValidateMOSSA
  Validate if Microsoft Online Services Sign-in Assistant is installed (Yes|No). 
 .Example
   # Remove Office 365 users using default parameters.
   Remove-O365Users
 .Example
   # Remove Office 365 users connecting with other admin account.
   Remove-O365Users -O365AdminAccount "adminuser@domain.com"
 .Example
   # Remove Office 365 users connecting with other admin account and different csv path and name.
   Remove-O365Users -O365AdminAccount "adminuser@domain.com" -csvPath "C:\Import.csv" -Verbose
#>
function Remove-O365Users {
    [CmdletBinding(SupportsShouldProcess = $true, confirmImpact = 'High')]
    param(
        [Parameter(Mandatory=$true)]
        [string] $O365AdminAccount,
        [string] $MSOnlineMinVersion = '1.1.183.17',
        [string] $csvPath = "$PSScriptRoot\config\O365Users_Sample.csv",
        [ValidateSet('Yes', 'No')][string] $ValidateMOSSA
    )
    if (!$ValidateMOSSA) {
        $ValidateMOSSA = Read-Host -Prompt 'Have you installed Microsoft Online Services Sign-in Assistant (Yes|No):'
    }
    switch ($ValidateMOSSA.ToLower()) {
        "yes" { 
            ## Install MSOnline powershell module
            if (!(Get-Module -Name MSOnline)) {
                Find-Module -Name MSOnline | Format-List
                Install-Module -Name MSOnline -MinimumVersion $MSOnlineMinVersion -Force -Verbose
                Get-Command -Module MSOnline
            }
    
            ## Connect to Office365
            Get-Credential $O365AdminAccount | Export-Clixml C:\O365Credential.xml
            $cred = Import-Clixml C:\O365Credential.xml
            Connect-MsolService -Credential $cred
            Remove-Item C:\O365Credential.xml

            ## Remove a group of users
            Import-Csv -Path "$csvPath" |
            ForEach-Object { Remove-MsolUser -UserPrincipalName $_.UserPrincipalName -Force -Verbose }
        }
        "no" { 
            Write-Host "Install Microsoft Online Services Sign-in Assistant: https://www.microsoft.com/en-us/download/details.aspx?id=41950"
            Break
        }
        Default { 
            Write-Host "Valid answers are Yes or No, try again"
            Break
        }
    }
}

<#
 .Synopsis
  Start GSuite to Office365 migration.
 .Description
  Start GSuite to Office365 migration for multiple users specified in csv file.
 .Parameter OGlobalAdminUser
  Office 365 user with admin privilegies (without domain name).
 .Parameter GSDomain
  Google Suite migration source domain.
 .Parameter ODomain
  Office365 migration target domain.
 .Parameter GSKeyPath
  Path to Google Suite Key json file.
 .Parameter CSVDataPath
  Path to csv file with account migration source and destination mapping.
 .Parameter WhatIf
  Shows what would happen if the cmdlet runs. The cmdlet is not run.
 .Example
   # Start migration using csv user mapping by providing Office365 admin user, GSuite domain.com, and O365 o365.domain.com domains.
   Start-GSuiteToO365Migration -OGlobalAdminUser user -GSDomain domain.com -ODomain o365.domain.com -Verbose
#>
function Start-GSuiteToO365Migration {
    [CmdletBinding(SupportsShouldProcess = $true, confirmImpact = 'High')]
    param(
        [Parameter(Mandatory=$true)]
        [string] $OGlobalAdminUser,
        [Parameter(Mandatory=$true)]
        [string] $GSDomain,
        [Parameter(Mandatory=$true)]
        [string] $ODomain,
        [Parameter(Mandatory=$true)]
        [string] $GSKeyPath,
        [Parameter(Mandatory=$true)]
        [string] $CSVDataPath,
        [string] $GEndpointName = 'gmailEndpoint'
    ) 
    ## Set Execution Policy
    $CurrentExecPol = (Get-ExecutionPolicy)
    Write-Verbose "Checking current Execution Policy. The Execution Policy is $CurrentExecPol."
    if ($CurrentExecPol -ne 'RemoteSigned') { 
        Write-Verbose "Setting PowerShell Execution Policy from $CurrentExecPol to RemoteSigned ..."
        Set-ExecutionPolicy RemoteSigned 
    }

    ## Modify Path
    $GSKeyPath = $GSKeyPath.Replace('\','\\')
    $CSVDataPath = $CSVDataPath.Replace('\','\\')
    
    ## Connect to Exchange Online PowerShell
    $date = (Get-Date -UFormat "%d%m%Y")
    $GBatchName = "gmailBatch-$date"
    $UserCredential = (Get-Credential "$OGlobalAdminUser@$ODomain")
    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection

    Write-Verbose "Connect to the Exchange Online ..."
    Import-PSSession $Session -DisableNameChecking

    ## Test O365 Connection
    Write-Verbose 'Testing Office365 connection ...'
    (Get-Mailbox | Select-Object -First 1).isValid

    ## Test GSuite Connection
    Write-Verbose 'Testing GSuite connection ...'
    Test-MigrationServerAvailability -Gmail -ServiceAccountKeyFileData $([System.IO.File]::ReadAllBytes("$GSKeyPath")) -EmailAddress "$OGlobalAdminUser@$GSDomain"

    ## Create a migration endpoint in Office365
    Write-Verbose "Checking if a $GEndpointName migration endpoint exists in Office365 ..."
    if (!(Get-MigrationEndpoint -Identity $GEndpointName)) {
        Write-Verbose "Migration endpoint does not exist. Creating a new $GEndpointName migration endpoint ..."
        New-MigrationEndpoint -Gmail -ServiceAccountKeyFileData $([System.IO.File]::ReadAllBytes("$GSKeyPath")) -EmailAddress "$OGlobalAdminUser@$GSDomain" -Name $GEndpointName
    }
    else {
        Write-Verbose  "Migration endpoint $GEndpointName exists ..."
    }

    ## Create a migration batch in Office365
    Write-Verbose "Checking if a $GBatchName migration batch exists in Office365 ..."
    if (!(Get-MigrationBatch -Identity $GBatchName)) {
        Write-Verbose "Migration batch does not exist. Creating a new $GBatchName migration batch ..."
        New-MigrationBatch -SourceEndpoint $GEndpointName -Name $GBatchName -CSVData $([System.IO.File]::ReadAllBytes("$CSVDataPath")) -TargetDeliveryDomain $ODomain  
    }
    else {
        Write-Verbose "Migration batch $GBatchName exists ...."
    }
    
    ## Start a migration batch
    $GBatchStatus = (Get-MigrationBatch -Identity $GBatchName).Status
    if ($GBatchStatus.ToString() -notin ('Starting', 'Syncing', 'Synced')) {
        Write-Verbose "Starting the $GBatchName migration batch ..."
        Start-MigrationBatch -Identity $GBatchName
    }
    else {
        Write-Verbose "The $GBatchName has $GBatchStatus status. Skipping ..."
    }

    ## Disconnect from Exchange Online PowerShell
    Write-Verbose "Disconnecting from the Exchange Online ..."
    Remove-PSSession $Session

    ## Set back Execution Policy
    Write-Verbose "Setting PowerShell Execution Policy to $CurrentExecPol ..."
    Set-ExecutionPolicy $CurrentExecPol
}

<#
 .Synopsis
  Start migration to SharePoint online.
 .Description
  Start migration of shared files to SharePoint Online from local or shared drive by providing json file with source and target.
 .Parameter batchPath
  Path to json file with file migration source and destination mapping.
 .Parameter WhatIf
  Shows what would happen if the cmdlet runs. The cmdlet is not run.
 .Example
   # Start migration from user@domain.com GSuite to user@o365.domain.com Office365 account.
   Start-MigrationToSPO -batchPath 'C:\PathTo\SharedDirBatch.json' -Verbose
#>
function Start-MigrationToSPO {
    [CmdletBinding(confirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true)]
        [string] $batchPath
    )
    
    ## Import Migration Tool module
    Write-Verbose 'Importing Migration Tool PowerShell module ...'
    Import-Module Microsoft.SharePoint.MigrationTool.PowerShell

    ## Modify Path
    $batchPath = $batchPath.Replace('\', '\\')

    ## Load JSON with defined migration tasks
    Write-Verbose 'Loading Json with defined migration ...'
    $Global:JsonTasks = Get-Content $batchPath | ConvertFrom-Json
    
    for ($i = 0; $i -lt $Global:JsonTasks.Tasks.Count; $i++) {
             
        ## Register the SPMT session SPO credentials
        Write-Verbose 'Registering SharePoint Migration Tool session ...'
        Register-SPMTMigration -SPOCredential $Global:SPOCredential -Force

        ## Add tasks into the migration session
        Write-Verbose 'Adding tasks into the migration session ...'
        $JsonDefinition = ConvertTo-Json $Global:JsonTasks.Tasks[$i] -Depth 100
        Add-SPMTTask -JsonDefinition $JsonDefinition
        
        ## Start migration
        Write-Verbose 'Starting Migration ...'
        Start-SPMTMigration

        ## Get migration status
        Write-Verbose 'Getting migration status ...'
        Get-SPMTMigration

    }
}

<#
 .Synopsis
  Start migration to OneDrive.
 .Description
  Start migration of shared files to OneDrive from local or shared drive by providing json file with source and target.
 .Parameter batchPath
  Path to json file with file migration source and destination mapping.
 .Parameter WhatIf
  Shows what would happen if the cmdlet runs. The cmdlet is not run.
 .Example
   # Start migration from user@domain.com GSuite to user@o365.domain.com Office365 account.
   Start-MigrationToOneDrive -batchPath 'C:\PathTo\MultipleUsersBatch.json' -Verbose
#>
function Start-MigrationToOneDrive {
    [CmdletBinding(confirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true)]
        [string] $batchPath
    )
    
    ## Import Migration Tool module
    Write-Verbose 'Importing Migration Tool PowerShell module ...'
    Import-Module Microsoft.SharePoint.MigrationTool.PowerShell

    ## Modify Path
    $batchPath = $batchPath.Replace('\', '\\')

    ## Load JSON with defined migration tasks
    Write-Verbose 'Loading Json with defined migration ...'
    $Global:JsonTasks = Get-Content $batchPath | ConvertFrom-Json
    
    for ($i = 0; $i -lt $Global:JsonTasks.Tasks.Count; $i++) {
        
        ## Setup user credentials
        $Task = $Global:JsonTasks.Tasks[$i]
        $Account = $Task.Account
        $Credential = ConvertTo-SecureString -String $Task.Credential -AsPlainText -Force
        $Global:SPOCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Account, $Credential
        
        ## Register the SPMT session SPO credentials
        Write-Verbose 'Registering SharePoint Migration Tool session ...'
        Register-SPMTMigration -SPOCredential $Global:SPOCredential -Force

        ## Add tasks into the migration session
        Write-Verbose 'Adding tasks into the migration session ...'
        $JsonDefinition = ConvertTo-Json $Global:JsonTasks.Tasks[$i] -Depth 100
        Add-SPMTTask -JsonDefinition $JsonDefinition
        
        ## Start migration
        Write-Verbose 'Starting Migration ...'
        Start-SPMTMigration

        ## Get migration status
        Write-Verbose 'Getting migration status ...'
        Get-SPMTMigration

    }
}

<#
 .Synopsis
  Stop GSuite to Office365 migration.
 .Description
  Stop GSuite to Office365 migration.
 .Parameter O365AdminAccount
  Office 365 account with admin privilegies (without).
 .Parameter WhatIf
  Shows what would happen if the cmdlet runs. The cmdlet is not run.
 .Example
   # Complete gmailBatch-19092019 migration batch.
   Stop-GSuiteToO365Migration -OGlobalAdminAccount 'adminuser@domain.com' -GBatchName gmailBatch-19092019 -Verbose
#>
function Stop-GSuiteToO365Migration {
    [CmdletBinding(SupportsShouldProcess = $true, confirmImpact = 'High')]
    param(
        [Parameter(Mandatory=$true)]
        [string] $OGlobalAdminAccount,
        [string] $GBatchName = 'gmailBatch'
    )
    ## Set Execution Policy
    $CurrentExecPol = (Get-ExecutionPolicy)
    Write-Verbose "Checking current Execution Policy. The Execution Policy is $CurrentExecPol."
    if ($CurrentExecPol -ne 'RemoteSigned') { 
        Write-Verbose "Setting PowerShell Execution Policy from $CurrentExecPol to RemoteSigned ..."
        Set-ExecutionPolicy RemoteSigned 
    }
    
    ## Connect to Exchange Online PowerShell
    $UserCredential = (Get-Credential "$OGlobalAdminAccount")
    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection

    Write-Verbose "Connect to the Exchange Online ..."
    Import-PSSession $Session -DisableNameChecking

    ## Test O365 Connection
    Write-Verbose 'Testing Office365 connection ...'
    (Get-Mailbox | Select-Object -First 1).isValid

    ## Complete-MigrationBatch
    $GBatchStatus = (Get-MigrationBatch -Identity $GBatchName).Status
    if ($GBatchStatus.ToString() -in ('Starting', 'Syncing', 'Synced')) {
        Write-Verbose "Completing the $GBatchName migration batch ..."
        Complete-MigrationBatch -Identity $GBatchName -Verbose
    }
    
    ## Disconnect from Exchange Online PowerShell
    Write-Verbose "Disconnecting from the Exchange Online ..."
    Remove-PSSession $Session

    ## Set back Execution Policy
    Write-Verbose "Setting PowerShell Execution Policy to $CurrentExecPol ..."
    Set-ExecutionPolicy $CurrentExecPol
}

Export-ModuleMember -Function Add-O365Users, Remove-O365Users, Start-GSuiteToO365Migration, Stop-GSuiteToO365Migration, Start-MigrationToOneDrive, Start-MigrationToSPO