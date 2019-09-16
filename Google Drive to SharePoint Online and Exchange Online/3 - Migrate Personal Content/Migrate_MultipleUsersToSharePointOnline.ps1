#Import-Module Microsoft.SharePoint.MigrationTool.PowerShell

$scriptPath = 'D:\Projects\GSuite-to-Office365-Migration\Google Drive to SharePoint Online and Exchange Online'
$batchPath = "$scriptPath\BatchMultipleUsers.json"

# Load JSON with defined migration tasks
$Global:JsonTasks = Get-Content $batchPath | ConvertFrom-Json

for ($i = 0; $i -lt $Global:JsonTasks.Tasks.Count; $i++)
{
    $Task = $Global:JsonTasks.Tasks[1]
    $Account = $Task.Account
    $Credential = ConvertTo-SecureString -String $Task.Credential -AsPlainText -Force
    $Global:SPOCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Account, $Credential

    # Register the SPMT session SPO credentials
    Register-SPMTMigration -SPOCredential $Global:SPOCredential -Force

    # Add tasks into the migration session    
    $JsonDefinition = ConvertTo-Json $Global:JsonTasks.Tasks[$i] -Depth 100
    Add-SPMTTask -JsonDefinition $JsonDefinition
    
    # Start migration
    Start-SPMTMigration

    # Get migration status
    Get-SPMTMigration
}
