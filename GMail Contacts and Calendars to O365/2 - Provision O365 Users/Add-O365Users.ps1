<#
 .Synopsis
  Create Office365 accounts.
 .Description
  Connect to Office365 and create Office365 accounts specified in import csv file.
 .Parameter MSOnlineMinVersion
  Minimum Version for MSOnline PowerShell Module.
 .Parameter O365AdminAccount
  Office 365 account with admin privilegies.
 .Parameter csvPath
  Path to csv file with users for import.
 .Parameter csvName
  Name of csv file with users for import.
 .Parameter ValidateMOSSA
  Validate if Microsoft Online Services Sign-in Assistant is installed (Yes|No).
 .Parameter WhatIf
  Shows what would happen if the cmdlet runs. The cmdlet is not run.
 .Example
   # Create Office 365 users using default parameters.
   Add-Office365Users
 .Example
   # Create Office 365 users connecting with other admin account.
   Add-Office365Users -O365AdminAccount "other.user@domain.com"
 .Example
   # Create Office 365 users connecting with other admin account and different csv path and name.
   Add-Office365Users -O365AdminAccount "other.user@domain.com" -csvPath "C:\" -csvName "Import.csv"
#>
function Add-Office365Users {
    [cmdletbinding(SupportsShouldProcess=$true, confirmImpact='High')]
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
            Import-Csv -Path "$csvPath\$csvName" |
            ForEach-Object {
                New-MsolUser -DisplayName $_.DisplayName -FirstName $_.FirstName -LastName $_.LastName -UserPrincipalName $_.UserPrincipalName -UsageLocation $_.UsageLocation -LicenseAssignment $_.AccountSkuId -Verbose
            } |
            Export-Csv -Path "$csvPath\Import_O365Users_Results.csv"
            #Remove-Item -Path "$csvPath\Import_O365Users_Results.csv"
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
#Export-ModuleMember -Function Add-Office365Users
Add-Office365Users -O365AdminAccount "miso.stamenic@wayseventech.com" -ValidateMOSSA yes -Verbose