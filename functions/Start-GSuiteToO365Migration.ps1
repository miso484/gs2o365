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
   Start-GSuiteToO365Migration -OGlobalAdminUser user -GSDomain domain.com -ODomain o365.domain.com -GSKeyPath 'C:\PathTo\GoogleServiceKey.json' -CSVDataPath 'C:\UsersMigration.csv' -Verbose
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