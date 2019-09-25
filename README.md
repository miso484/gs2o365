PURPOSE

The purpose of this repository is to automatize migration process from GSuite to Office365 by using functions from gs2o365 module.

MIGRATION PHASES

The migration process is done in two phases:

    Phase 1: Migrate GMail, Contacts, and Calendars.
    
    Phase 2: Migrate shared items to SharePoint Online and items for each user from Google Drive to OneDrive.

PREPARATION

Make sure to read files in documentation directory (mostly preparation files) before starting migration.

STEPS TO PACKAGE AND IMPORT MODULE

choco pack --version=1.5

choco install gs2o365 --source="'D:\Projects\gs2o365\gs2o365.1.5.nupkg'" -y

refreshenv

Get-Module -ListAvailable

Import-Module 'C:\ProgramData\chocolatey\lib\gs2o365'

Get-Command -Module gs2o365

STEPS TO REMOVE PACKAGE AND MODULE

Remove-Module gs2o365

choco uninstall gs2o365 -y

MIGRATION STEPS

Modify gs2o365_migration_template.ps1 file variables in the templates directory.
