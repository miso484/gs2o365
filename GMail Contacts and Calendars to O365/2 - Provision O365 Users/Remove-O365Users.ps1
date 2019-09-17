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
 .Parameter csvName
  Name of csv file with users for removal.
 .Parameter ValidateMOSSA
  Validate if Microsoft Online Services Sign-in Assistant is installed (Yes|No). 
 .Example
   # Remove Office 365 users using default parameters.
   Remove-Office365Users
 .Example
   # Remove Office 365 users connecting with other admin account.
   Remove-Office365Users -O365AdminAccount "other.user@domain.com"
 .Example
   # Remove Office 365 users connecting with other admin account and different csv path and name.
   Remove-Office365Users -O365AdminAccount "other.user@domain.com" -csvPath "C:\" -csvName "Import.csv"
#>
function Remove-Office365Users {
    param(
        [string] $MSOnlineMinVersion = '1.1.183.17',
        [string] $O365AdminAccount = 'miso.stamenic@domain.com',
        [string] $csvPath = 'D:\Projects\GSuite-to-Office365-Migration\GMail Contacts and Calendars to O365\2 - Provision O365 Users',
        [string] $csvName = 'Import_O365Users.csv',
        [ValidateSet('Yes', 'No')][string] $ValidateMOSSA
    )
    if (!$ValidateMOSSA){
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
            Import-Csv -Path "$csvPath\$csvName" |
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
#Export-ModuleMember -Function Remove-Office365Users
Remove-Office365Users -O365AdminAccount "miso.stamenic@wayseventech.com"