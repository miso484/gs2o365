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
   Add-O365Users -O365AdminAccount "adminuser@domain.com" -csvPath "C:\PathTo\NewUsers.csv"
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