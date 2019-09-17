<#
 .Synopsis
  Start GSuite to Office365 migration.
 .Description
  Start GSuite to Office365 migration for multiple users specified in csv file.
 .Parameter MSOnlineMinVersion
  Minimum Version for MSOnline PowerShell Module.
 .Parameter O365AdminAccount
  Office 365 account with admin privilegies.
 .Parameter csvPath
  Path to csv file with users for import.
 .Parameter csvName
  Name of csv file with users for import.
 .Parameter WhatIf
  Shows what would happen if the cmdlet runs. The cmdlet is not run.
 .Example
   # Create Office 365 users using default parameters.
   Create-Office365Users
 .Example
   # Create Office 365 users connecting with other admin account.
   Create-Office365Users -O365AdminAccount "other.user@domain.com"
 .Example
   # Create Office 365 users connecting with other admin account and different csv path and name.
   Create-Office365Users -O365AdminAccount "other.user@domain.com" -csvPath "C:\" -csvName "Import.csv"
#>
function Start-GSuiteToO365Migration {
    [cmdletbinding(SupportsShouldProcess=$true, confirmImpact='High')]
    param(
        [string] $User = 'miso.stamenic',
        [string] $GSDomain = 'domain.com',
        [string] $ODomain = 'o365.domain.com',
        [string] $GSKeyPath = 'D:\\Download\\GSuite Service Key\\KeyFile.json',
        [string] $CSVDataPath = 'D:\\Projects\\GSuite-to-Office365-Migration\\GMail Contacts and Calendars to O365\\3 - Migration Process\\UsersPasswords-Exhange-Batch.csv',
        [string] $GEndpointName = 'gmailEndpoint'
    )
    ## Set Execution Policy
    $CurrentExecPol = (Get-ExecutionPolicy)
    Write-Verbose "Checking current Execution Policy. The Execution Policy is $CurrentExecPol."
    if ($CurrentExecPol -ne 'RemoteSigned'){ 
      Write-Verbose "Setting PowerShell Execution Policy from $CurrentExecPol to RemoteSigned ..."
      Set-ExecutionPolicy RemoteSigned 
    }
    
    ## Connect to Exchange Online PowerShell
    $date = (Get-Date -UFormat "%d%m%Y")
    $GBatchName = "gmailBatch-$date"
    $UserCredential = (Get-Credential "$User@$ODomain")
    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection

    Write-Verbose "Connect to the Exchange Online ..."
    Import-PSSession $Session -DisableNameChecking

    ## Test O365 Connection
    Write-Verbose 'Testing Office365 connection ...'
    Get-Mailbox

    ## Test GSuite Connection
    Write-Verbose 'Testing GSuite connection ...'
    Test-MigrationServerAvailability -Gmail -ServiceAccountKeyFileData $([System.IO.File]::ReadAllBytes("$GSKeyPath")) -EmailAddress "$User@$GSDomain"

    ## Create a migration endpoint in Office365
    Write-Verbose "Creating a $GEndpointName migration endpoint in Office365 ..."
    New-MigrationEndpoint -Gmail -ServiceAccountKeyFileData $([System.IO.File]::ReadAllBytes("$GSKeyPath")) -EmailAddress "$User@$GSDomain" -Name $GEndpointName

    ## Create a migration batch in Office365
    Write-Verbose "Creating a $GBatchName migration batch in Office365 ..."
    New-MigrationBatch -SourceEndpoint $GEndpointName -Name $GBatchName -CSVData $([System.IO.File]::ReadAllBytes("$CSVDataPath")) -TargetDeliveryDomain $ODomain

    ## Start a migration batch
    Write-Verbose "Starting the $GBatchName migration batch ..."
    Start-MigrationBatch -Identity $GBatchName
    Get-MigrationBatch -Identity $GBatchName

    ## When Migration batch status goes to synced status
    #Complete-MigrationBatch -Identity $GBatchName

    ## Disconnect from Exchange Online PowerShell
    Write-Verbose "Disconnecting from the Exchange Online ..."
    Remove-PSSession $Session

    ## Set back Execution Policy
    Write-Verbose "Setting PowerShell Execution Policy to $CurrentExecPol ..."
    Set-ExecutionPolicy $CurrentExecPol
}
Export-ModuleMember -Function Start-GSuiteToO365Migration