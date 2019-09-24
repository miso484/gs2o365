<#
 .Synopsis
  Start migration to SharePoint online.
 .Description
  Start migration of shared files to SharePoint Online from local or shared drive by providing json file with source and target.
 .Parameter batchPath
  Path to json file with file migration source and destination mapping.
 .Parameter WhatIf
  Shows what would happen if the cmdlet runs. The cmdlet is not run.
 .Example
   # Start migration from user@domain.com GSuite to user@o365.domain.com Office365 account.
   Start-MigrationToSPO -batchPath 'C:\PathTo\SharedDirBatch.json' -Verbose
#>
function Start-MigrationToSPO {
    [CmdletBinding(confirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true)]
        [string] $batchPath
    )
    
    ## Import Migration Tool module
    Write-Verbose 'Importing Migration Tool PowerShell module ...'
    Import-Module Microsoft.SharePoint.MigrationTool.PowerShell

    ## Modify Path
    $batchPath = $batchPath.Replace('\', '\\')

    ## Load JSON with defined migration tasks
    Write-Verbose 'Loading Json with defined migration ...'
    $Global:JsonTasks = Get-Content $batchPath | ConvertFrom-Json

    ## Register the SPMT session SPO credentials
    Write-Verbose 'Registering SharePoint Migration Tool session ...'
    Register-SPMTMigration -SPOCredential $Global:SPOCredential -Force
    
    for ($i = 0; $i -lt $Global:JsonTasks.Tasks.Count; $i++) {
             
        ## Add tasks into the migration session
        Write-Verbose 'Adding tasks into the migration session ...'
        $JsonDefinition = ConvertTo-Json $Global:JsonTasks.Tasks[$i] -Depth 100
        Add-SPMTTask -JsonDefinition $JsonDefinition

    }
      
    ## Start migration
    Write-Verbose 'Starting Migration ...'
    Start-SPMTMigration

    ## Get migration status
    Write-Verbose 'Getting migration status ...'
    Get-SPMTMigration

    
}