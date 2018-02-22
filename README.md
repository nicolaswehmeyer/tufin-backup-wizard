# Tufin Backup Wizard (v. 1.7.5)
Tufin backup wizard is a solution that eases the difficulties an automated backup can create. It helps you to configure and realize the backup you desired, no matter if you are using SecureTrack or SecureChange / SecureApp.

# Disclaimer
This script is a Third-Party development and is not supported by Tufin. Feel free to contribute to this project by sending pull-requests to this repository.

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
5. **Finally:** Run the wizard and follow the instructions: **sh /usr/local/bin/backup-wizard.sh**

**Note:** The wizard will create a configuration file after everything was setup initially. The configuration file is located at /usr/local/bin/backup-wizard.cfg and is only readable for the root-user. Passwords for remote backups are also stored within this file. Once a configuration file exists, the wizard will not be shown again and rerunning the file triggers the backup with the previously defined bnackup settings.

# Additional features
- You can rerun the wizard by running the following command: **sh /usr/local/bin/backup-wizard.sh --reconfigure**
- You can delete a generated configuration file by running the following command: **sh /usr/local/bin/backup-wizard.sh --delete-configuration**

# Screenshots
Running tha wizard
![Running the wizard](https://github.com/nicolaswehmeyer/tufin-backup-wizard/blob/master/wizard-configuration.png)

Running the script after configuration
![Running the backup script](https://github.com/nicolaswehmeyer/tufin-backup-wizard/blob/master/wizard-running.png)

Reconfiguring the backup using --reconfigure
![Rerunning the wizard](https://github.com/nicolaswehmeyer/tufin-backup-wizard/blob/master/wizard-reconfigure.png)

# Supported versions
The script has been verified to work with TufinOS 2.13 / 2.14 and TOS R16-4 up to R17-1 HF3.
