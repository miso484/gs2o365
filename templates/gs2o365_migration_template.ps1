#
# SETUP VARIABLES THAT SHOULD BE MODIFIED BEFORE MIGRATION
#

## Office365 global admin user
$AdminUser = 'adminuser'
## Source domain (GSuite)
$SourceGSDomain = 'domain.com'
## Target domain (Office365)
$TargetO365Domain = 'domain.com'
## Edit O365Users_Sample.csv file the from the templates dir and modify path to it
$O365UsersCSVPath = 'C:\PathTo\O365Users_Sample.csv'
## Modify path to GSuite Service Key
$GSServiceKeyPath = 'C:\PathTo\GSuiteServiceKey.json'
## Edit UsersMigration_Sample.csv file the from the templates dir and modify path to it
$UsersMigrationCSVPath = 'C:\PathTo\UsersMigration_Sample.csv'
## Edit SharedDirBatch.json file the from the templates dir and modify path to it
$SharedItemsPath = 'C:\PathTo\SharedDirBatch_Sample.json'
## Edit MultipleUsersBatch_Sample file the from the templates dir and modify path to it
$PersonalItemsPath = 'C:\PathTo\MultipleUsersBatch_Sample.json'

# 
# PHASE 1: MIGRATE GMAIL, CONTACTS AND CALENDARS
# 

# Read and apply steps from Preparation-PhaseOne.txt file in the documentation dir

# Add new Office 365 users (save auto generated user passwords since it will be needed in phase 2)
$params = @{ 'O365AdminAccount' = "$AdminUser@$TargetO365Domain";
             'ValidateMOSSA' = 'yes';
             'csvPath' = "$O365UsersCSVPath"
}
Add-O365Users @params -Verbose

# Start migration
$params = @{ 'OGlobalAdminUser' = "$AdminUser";
             'GSDomain' = "$SourceGSDomain";
             'ODomain' = "$TargetO365Domain";
             'GSKeyPath' = "$GSServiceKeyPath";
             'CSVDataPath' = "$UsersMigrationCSVPath"
}
Start-GSuiteToO365Migration @params -Verbose

# 
# PHASE 2: MIGRATE PERSONAL AND SHARED ITEMS
# 

# Read and apply steps from Preparation-PhaseTwo.txt file in the documentation dir

# Start migration of shared items to SharePoint Online
Start-MigrationToSPO -batchPath $SharedItemsPath -Verbose

# Start migration of user items for each specified user
Start-MigrationToOneDrive -batchPath $PersonalItemsPath -Verbose