# Tufin Backup Wizard (v. 1.7.2)
Tufin backup wizard is a solution that eases the difficulties an automated backup can create. It helps you to configure and realize the backup you desired, no matter if you are using SecureTrack or SecureChange / SecureApp.

# Capabilities
- Save backups to local storage
- Automatically delete older backups within local storage
- Define prefixes for your backup file names (usefull if many Tufin servers save backup files to the same directory)
- Save backups to a remote location via FTP
- Save backups to a remote location via SCP

# Prerequisites
A Tufin installation containing TufinOS with TOS (Tufin Orchestration Suite) installed is required. For remote backups make sure that the user has the required permissions to store data on a remote server.

# Quickstart
Simply download the latet copy of the backup wizard and place it on your Tufin Servers:
1. Download the latest copy
2. Place it in the following directory on your Tufin Server: **/usr/local/bin/**
3. Make sure to set the correct owner of the script: **chown root:root /usr/local/bin/backup-wizard.sh**
4. Also make sure to set the correct permissions: **chmod 750 /usr/local/bin/backup-wizard.sh**
5. **Finally:** Run the wizard and follow the instructions: **./usr/local/bin/backup-wizard.sh**

Note: The wizard will create a configuration file after everything was setup initially. The configuration file is located at /usr/local/bin/backup-wizard.cfg and is only readable for the root-user. Passwords for remote backups are also stored within this file.

# Screenshots
![Running the wizard](https://github.com/nicolaswehmeyer/tufin-backup-wizard/blob/master/wizard-configuration.png)
![Running the backup script](https://github.com/nicolaswehmeyer/tufin-backup-wizard/blob/master/wizard-running.png)
![Rerunning the wizard](https://github.com/nicolaswehmeyer/tufin-backup-wizard/blob/master/wizard-configuration.png/wizard-reconfigure.png)

# Supported versions
The script has been verified to work with TufinOS 2.13 / 2.14 and TOS R16-4 up to R17-1.
