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