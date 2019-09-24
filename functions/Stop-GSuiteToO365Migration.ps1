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