#
# 1. Connect to Office365
#

# Download and install Microsoft Online Services Sign-in Assistant: https://www.microsoft.com/en-us/download/details.aspx?id=41950

# Install MSOnline powershell module
Find-Module -Name MSOnline | Format-List
Install-Module -Name MSOnline -MinimumVersion '1.1.183.17' -Force -Verbose
Get-Command -Module MSOnline

# Connect
Get-Credential "miso.stamenic@domain.com" | Export-Clixml C:\O365Credential.xml
$cred = Import-Clixml C:\O365Credential.xml
Connect-MsolService -Credential $cred
#Remove-Item C:\O365Credential.xml

#
# (Optional) Create one user account
#

# Create a new user with no license and with random password
New-MsolUser -UserPrincipalName "test.account@domain.com" -DisplayName "Test Account" -FirstName "Test" -LastName "Account"

# Validate
Get-MsolAccountSku
Get-MsolUser -UserPrincipalName "test.account@domain.com"

#
# 2. Create a bunch of users via a CSV file
#

$csvName = "Import_O365Users.csv"
$csvPath = "D:\Projects\GSuite-to-Office365-Migration\Migrate GMail Contacts and Callendars\2 - Provision O365 Users"
Import-Csv -Path "$csvPath\$csvName" |
    ForEach-Object {
      New-MsolUser -DisplayName $_.DisplayName -FirstName $_.FirstName -LastName $_.LastName -UserPrincipalName $_.UserPrincipalName -UsageLocation $_.UsageLocation -LicenseAssignment $_.AccountSkuId
    } |
    Export-Csv -Path "$csvPath\Import_O365Users_Results.csv"
#Remove-Item -Path "$csvPath\Import_O365Users_Results.csv"

#
# (Optional) Remove a group of users
#

$csvName = "Import_O365Users.csv"
$csvPath = "D:\Projects\GSuite-to-Office365-Migration\Migrate GMail Contacts and Callendars"
Import-Csv -Path "$csvPath\$csvName" |
    ForEach-Object { Remove-MsolUser -UserPrincipalName $_.UserPrincipalName -Force }