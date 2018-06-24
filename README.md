# Tufin Backup Wizard (v. 1.7.6)
Automating backups for Tufin Orchestration Suite as well as automatically cleaning up older backups from your backup storage is not a builtin feature in Tufin. This appliaction has been developed to make your life easier and solve some of the most common backup requirements of Tufin customers. The Tufin Backups Wizard is a script that enables you to easily realize the backup you intended. You can setup local Tufin backups as well as backups that get saved to remote servers via FTP and SCP.

When the appliaction is run for the first time it will guide you through the setup process. After the initial setup has been completed, you can create a cronjob that will run the script periodically and by that create your automated local or remote Tufin backups.

# Disclaimer
Tufin Backup Wizard is a Third-Party solution and is not supported by Tufin. Feel free to contribute to this project by sending pull-requests to this repository. If you like to contribute to this project, please create your own branch and name it as the feature you intend to add.

# Tufin Backup Wizard Capabilities
- Create local Tufin backups (create and save backups on your Tufin server)
- Define prefixes for your backup files (usefull if many Tufin servers create backup files within the same directory)
- Automatically delete older backups within your local storage (the script will not remove any files on remote servers)
- Create remote Tufin backups via FTP
- Create remote Tufin backups via SCP

# Prerequisites
A Tufin installation containing TufinOS with TOS (Tufin Orchestration Suite) installed is required. For remote backups make sure that the user has the required permissions to store data on a remote server.

# Quickstart
Simply download the latet copy of the backup wizard and place the file called **backup-wizard.sh** on your Tufin Server:
1. Download the latest copy of **backup-wizard.sh**
2. Place it in the following directory on your Tufin Server: **/usr/local/bin/**
3. Make sure to set the correct owner of the script: **chown root:root /usr/local/bin/backup-wizard.sh**
4. Also make sure to set the correct permissions: **chmod 750 /usr/local/bin/backup-wizard.sh**
5. **Finally:** Run the wizard and follow the instructions: **sh /usr/local/bin/backup-wizard.sh**

**Note:** The wizard will create a configuration file after everything was setup initially. The configuration file is located at /usr/local/bin/backup-wizard.cfg by default (can be changed within **backup-wizard.sh**) and is only readable by the root-user.

**Also Note:** Passwords for remote backups will also stored within this file. Once a configuration file exists, the wizard will not be shown again and rerunning the file triggers the backup with the previously defined backup settings.
Recommendation: Use ssh-keys for auth + dummy-passwords

# CLI optional parameters
- **--help | -h:** View appliactions help information
- **--reconfigure | -r:** Rerun wizard and overwrite the existing backup settings
- **--show-configuration | -s:** Show current backup settings
- **--delete-configuration | -d:** Delete current backup settings including configuration file
- **---add-cronjob | -c:** Create or overwrite an existing cronjob in root users crontab
- **--delete-cronjob | -e:** Erase backup cronjobs that are referenced to this script

# Screenshots
Running tha wizard
![Running the wizard](https://github.com/nicolaswehmeyer/tufin-backup-wizard/blob/master/wizard-configuration.png)

Running the script after configuration
![Running the backup script](https://github.com/nicolaswehmeyer/tufin-backup-wizard/blob/master/wizard-running.png)

Reconfiguring the backup using --reconfigure
![Rerunning the wizard](https://github.com/nicolaswehmeyer/tufin-backup-wizard/blob/master/wizard-reconfigure.png)

# Supported versions
The script has been verified to work within the following Tufin environments:
- TufinOS: 2.13 / 2.14 / 2.15
- Tufin Orchestration Suite (TOS): R16-4 / R17-1 / R17-2 / R17-3
