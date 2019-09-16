<# 
MORE INFO

https://docs.microsoft.com/en-us/powershell/exchange/exchange-online/connect-to-exchange-online-powershell/connect-to-exchange-online-powershell
https://docs.microsoft.com/en-us/Exchange/mailbox-migration/perform-g-suite-migration#start-a-g-suite-migration-with-exchange-online-powershell

#>

# Set Execution Policy
Set-ExecutionPolicy RemoteSigned

# Connect to Exchange Online PowerShell

$User = 'miso.stamenic'
$GSDomain = 'domain.com'
$ODomain = 'o365.domain.com'

$GSKeyPath = 'D:\\Download\\GSuite Service Key\\KeyFile.json'
$CSVDataPath = 'D:\\Projects\\GSuite-to-Office365-Migration\\Migrate GMail Contacts and Callendars\\3 - Migration Process\\UsersPasswords-Exhange-Batch.csv'

$date = (Get-Date -UFormat "%d%m%Y")
$GEndpointName = 'gmailEndpoint'
$GBatchName = "gmailBatch-$date"

$UserCredential = (Get-Credential "$User@$ODomain")
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection

Import-PSSession $Session -DisableNameChecking

##Test O365 Connection
Get-Mailbox

#Test GSuite Connection
Test-MigrationServerAvailability -Gmail -ServiceAccountKeyFileData $([System.IO.File]::ReadAllBytes("$GSKeyPath")) -EmailAddress "$User@$GSDomain"

#Create a migration endpoint in Office365
New-MigrationEndpoint -Gmail -ServiceAccountKeyFileData $([System.IO.File]::ReadAllBytes("$GSKeyPath")) -EmailAddress "$User@$GSDomain" -Name $GEndpointName

#Create a migration batch in Office365
New-MigrationBatch -SourceEndpoint $GEndpointName -Name $GBatchName -CSVData $([System.IO.File]::ReadAllBytes("$CSVDataPath")) -TargetDeliveryDomain $ODomain

#Start a migration batch
Start-MigrationBatch -Identity $GBatchName
Get-MigrationBatch -Identity $GBatchName

#When Migration batch status goes to synced status
#Complete-MigrationBatch -Identity $GBatchName

# Disconnect from Exchange Online PowerShell
Remove-PSSession $Session