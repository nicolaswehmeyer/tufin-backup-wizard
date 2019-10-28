#!/bin/sh
# Script provided by Tufin, Nicolas Wehmeyer, Professional Services Consultant
# Disclaimer: This script is a third-party development and is not supported by Tufin. Use it at your own risk
# Version: 1.7.6

###							           ###
##### When needed, change the config and log file locations here #####
CFG_FILE_LOCATION="/usr/local/bin/backup-wizard.cfg"
BACKUP_FILE_LOCATION="/var/log/st/backup-wizard.log"
##### When needed, change the config and log file locations here #####
###							            ##

### We need some additional values for our script to run nicely
export PATH="${PATH}:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin"
SCRIPT_WORKDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPT_FILENAME=`basename "$0"`
CRONTAB_TEMP_FILE=${SCRIPT_WORKDIR}/backup-wizard-cron
SUITE_STATUS_FILE="/opt/tufin/securitysuite/status/suite.status"
DATE=`/bin/date +%F`
TIME=`/bin/date +%H%M`
VER=`/usr/sbin/st ver | grep SecureTrack |awk '{print $3$4$5$6}'`

### Creating info and error handlers
log_timestamp_info() {
	LOG_TIME=`/bin/date +%T`
	LOG_DATE=`/bin/date +%F`
	LOG_TIMESTAMP="[${LOG_DATE} ${LOG_TIME}]"
	echo "${LOG_TIMESTAMP} INFO:" 
}

log_timestamp_error() {
	LOG_TIME=`/bin/date +%T`
	LOG_DATE=`/bin/date +%F`
	LOG_TIMESTAMP="[${LOG_DATE} ${LOG_TIME}]"
	echo "${LOG_TIMESTAMP} ERROR:" 
}

script_help() {
	echo -e "Usage: ${SCRIPT_WORKDIR}/${SCRIPT_FILENAME} [--help] [--reconfigure] [--show-configuration] [--delete-configuration]"
	echo -e ""
	echo -e "Run this script without parameters for the first time to properly configure it."
	echo -e "After the script has been configured you can run it without parameters to create backups."
	echo -e ""
	echo -e "--help|-h\t\t\tDisplay this information."
	echo -e "--reconfigure|-r\t\tReconfigure backup settings. This will overwrite current settings."
	echo -e "--show-configuration|-s\t\tShow the current backup settings."
	echo -e "--delete-configuration|-d\tDelete generated configuration file."
	echo -e "--add-cronjob|-c\t\tCreate or overwrite an existing cronjob in root users crontab."
	echo -e "--delete-cronjob|-e\t\tErase backup cronjobs that are referenced to this script."
	echo -e ""
	exit 0
}

### Check if services are running and select correct backup method
initialize_backup() {
	### Check if the script is being run with correct permissions
	check_permissions
	### Check if configuration has already been done
	check_configuration_file
	### Set backup file path
	set_backup_file_path
	### Call function to check if tufin-jobs are running
	check_st_services
	### Show configuration settings
	show_configuration
	### Call corresponding function for backup type provided
	if [ "${BACKUP_MODE}" == "local" ]
	then
		create_backup local
	elif [ "${BACKUP_MODE}" == "ftp" ] || [ "${BACKUP_MODE}" == "scp" ]
	then
		create_backup remote
	fi
}

### Check current user permissions
check_permissions() {
	if [[ $EUID -ne 0 ]]
	then
		echo -e "$(log_timestamp_error) This script must be run as root. Aborting"
		exit 1
	else
		echo -e "$(log_timestamp_info) Permissions checked successful. Script was initiated by root user."
		return
	fi
}

### Check if configuration file exists and contains valid data
check_configuration_file() {
	if [ -r "${CFG_FILE_LOCATION}" ] && [ -s "${CFG_FILE_LOCATION}" ]
	then
		echo -e "$(log_timestamp_info) Backup configuration file already exists. Importing settings."
		source ${CFG_FILE_LOCATION}
		return
	else
		echo -e "$(log_timestamp_info) Backup configuration file doesn't exists or is empty. Starting first time wizard."
		setup_wizard
	fi
}

### Check if a prefix was defined and change the backup file accordingly
set_backup_file_path() {
	if [ -z ${BACKUP_FILE_PREFIX} ]
	then
		BACKUP_FILE_PATH=${BACKUP_DIR}tos-backup-${VER}-${TIME}
	else
		BACKUP_FILE_PATH=${BACKUP_DIR}${BACKUP_FILE_PREFIX}-tos-backup-${VER}-${TIME}
	fi
}

### Check if tufin-jobs are running otherwise stop backup
check_st_services() {
	### Chek if tufin-jobs are running. Otherwise stop backup
	source ${SUITE_STATUS_FILE}
	ST_STATUS=${ST}
	SCW_STATUS=${SCW}
	SA_STATUS=${SA}
	if ( [ ${ST_STATUS} == "ENABLED" ] ) || ( [ ${ST_STATUS} == "ENABLED" ] && [ ${SCW_STATUS} == "ENABLED" ] )
	then
		if [[ -z $(ps -ef | grep tufin-jobs | grep -v grep) ]]
		then
			echo -e "$(log_timestamp_error) Checking services. Tufin-jobs service not running. Aborting."
			exit 1
		else
			echo -e "$(log_timestamp_info) Checking services. Tufin-jobs service running. Continuing with backup."
			return
		fi
	else
		echo -e "$(log_timestamp_info) Skipping services check as this is a SecureChange server."
		return
	fi
}

### Start setup wizard
setup_wizard() {
	clear
	echo -e "$(log_timestamp_info) ---------------------------------------------------------------------------------"
	echo -en "$(log_timestamp_info) Please select your backup mode. Type \"local\", \"ftp\" or \"scp\" and press ENTER [Default: local]: "
	read BACKUP_MODE

	if [ -z ${BACKUP_MODE} ]
	then
		BACKUP_MODE="local"
	elif [ ${BACKUP_MODE} == "local" ]
	then
		echo -e "$(log_timestamp_info) Backup mode set to local."
	elif [ ${BACKUP_MODE} == "ftp" ]
	then
		echo -e "$(log_timestamp_info) Backup mode set to FTP transfer."
	elif [ ${BACKUP_MODE} == "scp" ]
	then
		echo -e "$(log_timestamp_info) Backup mode set to SCP transfer."
	else
		echo -e "$(log_timestamp_error) You haven't provided a correct backup mode. Please type \"local\", \"ftp\" or \"scp\". Aborting"
		exit 1
	fi
	echo -en "$(log_timestamp_info) Do you want to add a prefix to the backup file names? Please type \"yes\" or \"no\" and press ENTER. [Default: no]: "
	read PREFIX_NEEDED
	
	if [ -z ${PREFIX_NEEDED} ]
	then
		PREFIX_NEEDED="no"
	fi
	### Backup file prefix
	if [ ${PREFIX_NEEDED} == "yes" ]
	then
		echo -en "$(log_timestamp_info) Please enter the prefix and press ENTER. [Example: st-server]: "
		read BACKUP_FILE_PREFIX
	elif [ ${PREFIX_NEEDED} == "no" ]
	then
		echo -e "$(log_timestamp_info) No prefix specified. Continuing without a prefix."
	else
		echo -e "$(log_timestamp_error) You provided wrong inputs, aborting. Please try again."
		exit 1
	fi
	### Backup mode local
	if [ ${BACKUP_MODE} == "local" ]
	then
		echo -en "$(log_timestamp_info) Please specify the destination folder for your backups. Example: Type \"/your/folder/\" and press [ENTER]. Default is \"/root/\": "
		read BACKUP_DIR
		if [ -z ${BACKUP_DIR} ]
		then
			echo -e "$(log_timestamp_info) You haven't specified a custom backup directory. Backups will be saved to \"/root\"/"
			BACKUP_DIR=/root/
		else
			echo -e "$(log_timestamp_info) Backup directory has been set to ${BACKUP_DIR}."
		fi
	
		echo -en "$(log_timestamp_info) Do you want to delete older backups from your backup folder automatically? Type \"yes\" or \"no\" and press ENTER. [Default: no]: "
		read CLEANUP_NEEDED
		if [ -z ${CLEANUP_NEEDED} ]
		then
			"$(log_timestamp_info) Older backup files will not be cleaned up automatically."
		elif [ ${CLEANUP_NEEDED} == "yes" ]
		then
			echo -en "$(log_timestamp_info) How many backup files do you want to store within ${BACKUP_DIR}? Please type a numerical value: "
			read MAX_BACKUPS
			echo -e "$(log_timestamp_info) Okay. Backups will be created within ${BACKUP_DIR}. Additionally we will store ${MAX_BACKUPS} backups in this directory and remove older ones automatically."
		elif [ ${CLEANUP_NEEDED} == "no" ]
		then
			echo -e "$(log_timestamp_info) Okay. Older backups will not be deleted automatically."
		else
			echo -e "$(log_timestamp_error) You haven't specified a correct value. Please type \"yes\" or \"no\". Aborting."
			exit 1
		fi
	fi
	### Backup mode remote
	if [ ${BACKUP_MODE} == "ftp" ] || [ ${BACKUP_MODE} == "scp" ]
	then
		### Define backup directory on remote server
		echo -n "$(log_timestamp_info) Please specify folder on the remote server for your backups. Example: Type \"/your/folder/\" and press ENTER. [Default: \"/root/\"]: "
		read BACKUP_DIR
		if [ -z ${BACKUP_DIR} ]
		then
			echo -e "$(log_timestamp_info) You haven't specified a custom backup directory. Backups will be saved to \"/root\"/ on the remote server."
			BACKUP_DIR="/root/"
		else
			echo -e "$(log_timestamp_info) Backups will be saved to the remote server in this directory: ${BACKUP_DIR}."
		fi
		### Get remote servers ip address
		echo -en "$(log_timestamp_info) Please specify the ip address or hostname of the remote server. Make sure that the remote server is resolveable and reachable: "
		read SERVER
		if [ -z ${SERVER} ]
		then
			echo -e "$(log_timestamp_error) You haven't specified a server ip or hostname. Aborting."
			exit 1
		else	
			echo -e "$(log_timestamp_info) Settings saved. Backups will be saved to ${SERVER}."
		fi
		### Get remote servers user
		echo -en "$(log_timestamp_info) Please specify the user to access the remote server. Make sure that the user has the necessary permissions on the remote server: "
		read USERNAME
		if [ -z ${USERNAME} ]
		then
			echo -e "$(log_timestamp_error) You haven't specified a username for accessing the remote server ${SERVER}. Aborting."
			exit 1
		else
			echo -e "$(log_timestamp_info) Okay. Using ${USERNAME} to login to ${SERVER}."
		fi
		### Set remote server users password
		echo -en "$(log_timestamp_info) Please specify the password for ${USERNAME} to login to ${SERVER}: "
		read PASSWORD
		if [ -z ${PASSWORD} ]
		then
			echo -e "$(log_timestamp_error) You haven't specified a password for accessing the remote server ${SERVER}. Aborting."
			exit 1
		else
			echo -e "$(log_timestamp_info) The password has been set successfully."
		fi
	fi
	### Create the configuration file
	echo -e "$(log_timestamp_info) Saving settings to configuration file ${CFG_FILE_LOCATION}."
	touch ${CFG_FILE_LOCATION}
	if [ -z ${BACKUP_MODE} ]
	then
		echo -e "$(log_timestamp_error) Could not save backup mode to configuration file. Aborting."
		rm -f ${CFG_FILE_LOCATION}
		exit 1
	else
		echo "BACKUP_MODE=${BACKUP_MODE}" >> ${CFG_FILE_LOCATION}
	fi

	if [ ! -z ${BACKUP_FILE_PREFIX} ]
	then
		echo "BACKUP_FILE_PREFIX=${BACKUP_FILE_PREFIX}" >> ${CFG_FILE_LOCATION}
	fi

	if [ -z ${BACKUP_DIR} ]
	then
		echo "$(log_timestamp_error) Missing backup directory. Cannot save configuration file. Aborting."
		rm -f ${CFG_FILE_LOCATION}
		exit 1
	else
		echo "BACKUP_DIR=${BACKUP_DIR}" >> ${CFG_FILE_LOCATION}
	fi

	if [ ! -z ${MAX_BACKUPS} ]
	then
		echo "MAX_BACKUPS=${MAX_BACKUPS}" >> ${CFG_FILE_LOCATION}
	fi

	if [ ! -z ${SERVER} ]
	then
		echo "SERVER=${SERVER}" >> ${CFG_FILE_LOCATION}
	fi

	if [ ! -z ${USERNAME} ]
	then
		echo "USERNAME=${USERNAME}" >> ${CFG_FILE_LOCATION}
	fi

	if [ ! -z ${PASSWORD} ]
	then
		echo "PASSWORD=${PASSWORD}" >> ${CFG_FILE_LOCATION}
	fi

	if [ -r "${CFG_FILE_LOCATION}" ] && [ -s "${CFG_FILE_LOCATION}" ]
	then
		echo -e "$(log_timestamp_info) Changing file permissions of ${CFG_FILE_LOCATION}, so only root is able to read it."
		chown root:root ${CFG_FILE_LOCATION}
		chmod 750 ${CFG_FILE_LOCATION}
		echo -ne "$(log_timestamp_info) Configuration was successful. Do you want to create a cronjob now? [yes/no]: "
		read CRONJOB_NEEDED
		if [ ${CRONJOB_NEEDED} == "yes" ]
		then
			add_cronjob 
			echo -e "$(log_timestamp_info) ---------------------------------------------------------------------------------"
		else
			echo -e "$(log_timestamp_info) Okay, no cronjob will be created."
			echo -e "$(log_timestamp_info) Use \"${SCRIPT_WORKDIR}/${SCRIPT_FILENAME} --add-cronjob\" to add one later."
			echo -e "$(log_timestamp_info) ---------------------------------------------------------------------------------"
		fi
		exit
	fi
}

### Reconfigure the backup
reconfigure_backup() {
	echo -ne "$(log_timestamp_info) Are you sure that you want to delete your current backup settings in ${CFG_FILE_LOCATION} and rerun the setup wizard? [yes/no]: "
	read reconfiguration_needed
	if [ ${reconfiguration_needed} == "yes" ]
	then
		clear
		rm -f ${CFG_FILE_LOCATION}
		echo -e "$(log_timestamp_info) Done. Deleted current backup configuration file ${CFG_FILE_LOCATION}. Starting setup wizard."
		setup_wizard
	elif [ ${reconfiguration_needed} == "no" ]
	then
		echo -e "$(log_timestamp_info) Backup settings will not be reconfigured. Aborting."
		exit 1
	else
		echo -e "$(log_timestamp_error) Wrong option set. Aborting without deleting the current backup settings."
		exit 1
	fi
}

### show configuration file
show_configuration() {
	if [ -r "${CFG_FILE_LOCATION}" ] && [ -s "${CFG_FILE_LOCATION}" ]
	then
		check_configuration_file
		### Display configuration settings
		if [ "${BACKUP_MODE}" == "local" ]
		then
			### Display all passed backup settings
			echo -e "$(log_timestamp_info) Backup settings"
			echo -e "-------------------------------------------"
			### Backup Mode
			if [ -z "${BACKUP_MODE}" ]
			then
				echo -e "Backup mode:\t\tundefined"
			else
				echo -e "Backup mode:\t\t${BACKUP_MODE}"
			fi
			### Backup type	
			if [ -z "${BACKUP_TYPE}" ]
			then
				echo -e "Backup type:\t\tFull Backup"
			else
				echo -e "Backup type:\t\t${BACKUP_TYPE}"
			fi
			### Backup folder	
			if [ -z "${BACKUP_DIR}" ]
			then
				echo -e "Backup folder:\t\tNot specified"
			else
				echo -e "Backup folder:\t\t${BACKUP_DIR}"
			fi
			### Backup file prefix	
			if [ -z "${BACKUP_FILE_PREFIX}" ]
			then
				echo -e "Backup prefix:\t\tNot specified"
			else
				echo -e "Backup prefix:\t\t${BACKUP_FILE_PREFIX}"
			fi
			### Maximal number of backups	
			if [ -z "${MAX_BACKUPS}" ]
			then
				echo -e "Max. backups:\t\tNone"
			else
				echo -e "Max. Backups:\t\t${MAX_BACKUPS}"
			fi
			echo -e "-------------------------------------------"
		elif [ "${BACKUP_MODE}" == "ftp" ] || [ "${BACKUP_MODE}" == "scp" ]
		then
			### Check if we have all values to create the backup
			if [ -z "${USERNAME}" ] || [ -z "${PASSWORD}" ] || [ -z "${SERVER}" ]
			then
				echo -e "$(log_timestamp_error) Please provide directory, username, passwort and server. Aborting"
				exit 1
			fi
			### Display all passed backup settings
			echo -e "$(log_timestamp_info) Backup settings"
			echo -e "-------------------------------------------"
			### Backup Mode
			if [ -z "${BACKUP_MODE}" ]
			then
				echo -e "Backup mode:\t\tundefined"
			else
				echo -e "Backup mode:\t\t${BACKUP_MODE}"
			fi
			### Backup type	
			if [ -z "${BACKUP_TYPE}" ]
			then
				echo -e "Backup type:\t\tFull Backup"
			else
				echo -e "Backup type:\t\t${BACKUP_TYPE}"
			fi
			### Backup folder	
			if [ -z "${BACKUP_DIR}" ]
			then
				echo -e "Backup folder:\t\tNone"
			else
				echo -e "Backup folder:\t\t${BACKUP_DIR}"
			fi
			### Backup file prefix	
			if [ -z "${BACKUP_FILE_PREFIX}" ]
			then
				echo -e "Backup prefix:\t\tNone"
			else
				echo -e "Backup prefix:\t\t${BACKUP_FILE_PREFIX}"
			fi
			### Maximal number of backups	
			if [ -z "${MAX_BACKUPS}" ]
			then
				echo -e "Max. backups:\t\tIgnoring (local backups only)"
			else
				echo -e "Max. Backups:\t\t${MAX_BACKUPS}"
			fi
			### Remote username	
			if [ -z "${USERNAME}" ]
			then
				echo -e "Remote Username:\tNot specified"
			else
				echo -e "Remote Username:\t${USERNAME}"
			fi
			### Remote password	
			if [ -z "${PASSWORD}" ]
			then
				echo -e "Remote Password:\tNot specified"
			else
				echo -e "Remote Password:\t******"
			fi
			### Remote server	
			if [ -z "${SERVER}" ]
			then
				echo -e "Remote Server:\t\tNot specified"
			else
				echo -e "Remote Server:\t\t${SERVER}"
			fi
			echo -e "-------------------------------------------"
		fi
		if [ "${1}" == "show_only" ]
		then
			exit 0
		else
			return
		fi
	else
		echo -e "$(log_timestamp_error) Could not find configuration file. Please start the script first to configure your settings."
		exit 1
	fi
}

### Delete configuration file
delete_configuration() {
	if [ -r "${CFG_FILE_LOCATION}" ] && [ -s "${CFG_FILE_LOCATION}" ]
	then
		echo -e "$(log_timestamp_info) Removing file ${CFG_FILE_LOCATION} now."
		rm -f ${CFG_FILE_LOCATION}
		if [ ! -f "${CFG_FILE_LOCATION}" ]
		then
			echo -e "$(log_timestamp_info) Configuration file ${CFG_FILE_LOCATION} has been deleted."
			exit 0
		else
			echo -e "$(log_timestamp_error) Could not delete the file ${CFG_FILE_LOCATION}. Check permissions. Aborting."
			exit 1
		fi
	else
		echo -e "$(log_timestamp_error) Could not find configuration file. Please start the script first to configure your settings."
		exit 1
	fi
}

### Add or overwrite an existing cronjob
add_cronjob() {
	/usr/bin/crontab -luroot > ${CRONTAB_TEMP_FILE} 2>/dev/null
	if [ -s ${CRONTAB_TEMP_FILE} ]
	then
		if [[ ! -z $(grep "${SCRIPT_WORKDIR}/${SCRIPT_FILENAME}" "${CRONTAB_TEMP_FILE}") ]]
		then
			echo "$(log_timestamp_info) Found old backup cronjobs. Removing old jobs before creating a new one."
			/usr/bin/crontab -luroot | grep -v ${SCRIPT_WORKDIR}/${SCRIPT_FILENAME} > ${CRONTAB_TEMP_FILE}
			echo "00 01 * * * ${SCRIPT_WORKDIR}/${SCRIPT_FILENAME} >> ${BACKUP_FILE_LOCATION} 2>&1" >> ${CRONTAB_TEMP_FILE}
			/usr/bin/crontab ${CRONTAB_TEMP_FILE}
			echo -e "$(log_timestamp_info) Crontab has been updated. Use \"crontab -luroot\" to view the newly created job."
		else
			echo "00 01 * * * ${SCRIPT_WORKDIR}/${SCRIPT_FILENAME} >> ${BACKUP_FILE_LOCATION} 2>&1" >> ${CRONTAB_TEMP_FILE}
			/usr/bin/crontab ${CRONTAB_TEMP_FILE}
			echo -e "$(log_timestamp_info) New cronjob has been created. Use \"crontab -luroot\" to view the changes."
		fi
	else
		echo -e "$(log_timestamp_info) Empty Crontab file. New cronjob has been added. Use \"crontab -luroot\" to view the changes."
		echo "00 01 * * * ${SCRIPT_WORKDIR}/${SCRIPT_FILENAME} >> ${BACKUP_FILE_LOCATION} 2>&1" >> ${CRONTAB_TEMP_FILE}
		/usr/bin/crontab ${CRONTAB_TEMP_FILE}
	fi
	rm -f ${CRONTAB_TEMP_FILE}
	if [ "${1}" == "no_wizard" ]
	then
		exit 0
	else
		return
	fi
}

### Delete backup cronjobs
delete_cronjob() {
	if [[ ! -z $(/usr/bin/crontab -luroot | grep "${SCRIPT_WORKDIR}/${SCRIPT_FILENAME}") ]]
	then 
		/usr/bin/crontab -luroot | grep -v ${SCRIPT_WORKDIR}/${SCRIPT_FILENAME} | /usr/bin/crontab -
		echo -e "$(log_timestamp_info) Removed backup cronjobs from root users crontab."
	else
		echo -e "$(log_timestamp_error) There are no backup cronjobs that can be removed."
	fi
	exit
}

### Create the actual backup locally first
create_backup() {
	### Create local backup
	if [ "$1" == "local" ]
	then
        	### Create local backup
        	if [ -n "${BACKUP_DIR}" ]
        	then
			if [ -d "${BACKUP_DIR}" ]
			then
                		echo "$(log_timestamp_info) Creating new backup file ${BACKUP_FILE_PATH}_${DATE}.zip. This will take some time."
        		else
                		echo "$(log_timestamp_info) Backup folder ${BACKUP_DIR} doesn't exist. Creating it."
				echo "$(log_timestamp_info) Creating new backup file ${BACKUP_FILE_PATH}_${DATE}.zip. This will take some time."
				/bin/mkdir ${BACKUP_DIR}
			fi
		else
			echo "$(log_timestamp_error) Please specify backup folder first."
			exit 1
        	fi
		### Create the backup file
        	RESULT=`/usr/sbin/tos backup ${BACKUP_FILE_PATH}`
        	### Check if the backup has been created successfully
        	echo ${RESULT} | grep -i "Backup finished successfully" >/dev/null
        	if [ $? -ne 0 ]
        	then
        	        echo "$(log_timestamp_error) Backup failed. Reason: " ${RESULT}
        	        exit 1
        	else
        	        echo "$(log_timestamp_info) Backup has been created successfully."
        	fi
		### Cleanup the backupfolder
		cleanup_backupfolder local
	### Create remote backup
	elif [ "$1" == "remote" ] && [ -n "${BACKUP_DIR}" ]
	then
		### Create temporary local backup file for remote backup
		if [ -z ${BACKUP_FILE_PREFIX} ]
			then
				echo -e "$(log_timestamp_info) Creating temporary backup file /tmp/tos-backup-${VER}-${TIME}_${DATE}.zip. This will take some time."
                        	RESULT=`/usr/sbin/tos backup /tmp/tos-backup-${VER}-${TIME}`
			else
				echo -e "$(log_timestamp_info) Creating temporary backup file /tmp/${BACKUP_FILE_PREFIX}-tos-backup-${VER}-${TIME}_${DATE}.zip for remote backup. This will take some time."
				RESULT=`/usr/sbin/tos backup /tmp/${BACKUP_FILE_PREFIX}-tos-backup-${VER}-${TIME}`
		fi		
		### Transfer backup file using SCP
		if [ ${BACKUP_MODE} == "scp" ]
		then
			scp_transfer
		### Transfer backup file using FTP
		elif [ ${BACKUP_MODE} == "ftp" ]
		then
			ftp_transfers
		else
			echo -e "$(log_timestamp_error) No backup mode defined. Please set backup mode (local/ftp/scp)"
			exit
		fi
	fi
}

### Clean backupfolder from older backups
cleanup_backupfolder() {
        ### Delete older backup files
	if [ "$1" == "local" ]
        then
        	if [ -z "${MAX_BACKUPS}" ] || [ "${MAX_BACKUPS}" = 0 ]
        	then
                	echo "$(log_timestamp_info) Maximum number of backup files has not been set. Backup folder will not be cleaned automatically."
        		exit
		elif [ -n "${MAX_BACKUPS}" ] && [ -z "${BACKUP_FILE_PREFIX}" ]
                then
			FILE_COUNT=`/bin/find ${BACKUP_DIR} -type f -name "tos-backup*"| wc -l`
                elif [ -n "${MAX_BACKUPS}" ] && [ -n "${BACKUP_FILE_PREFIX}" ]
		then
                        FILE_COUNT=`/bin/find ${BACKUP_DIR} -type f -name "${BACKUP_FILE_PREFIX}-tos-backup*"| wc -l`
                fi
		if [ ${FILE_COUNT} -gt ${MAX_BACKUPS} ]
                then
                        FILES_TO_DELETE=$((FILE_COUNT-MAX_BACKUPS))
                        if [ -z ${BACKUP_FILE_PREFIX} ]
                        then
                                /bin/rm `/bin/ls -drt ${BACKUP_DIR}tos-backup-* | /usr/bin/head -${FILES_TO_DELETE}`
                        else
                                /bin/rm `/bin/ls -drt ${BACKUP_DIR}${BACKUP_FILE_PREFIX}-tos-backup-* | /usr/bin/head -${FILES_TO_DELETE}`
                        fi
                        echo "$(log_timestamp_info) ${FILES_TO_DELETE} older backups have been removed from ${BACKUP_DIR}."
                else
                        echo "$(log_timestamp_info) Not exceeding number of maximum backups, deletion of older files is not necessary."
                fi
	fi
	### Deleting temporary backup file for remote backup
	if [ "$1" == "remote" ] && [ -z ${BACKUP_FILE_PREFIX} ]
        then
		echo "$(log_timestamp_info) Deleting temporary backup file /tmp/tos-backup-${VER}-${TIME}_${DATE}.zip."
		if [ -e "/tmp/tos-backup-${VER}-${TIME}_${DATE}.zip" ]
		then
			rm -rf /tmp/tos-backup-${VER}-${TIME}_${DATE}.zip
			echo "$(log_timestamp_info) Done. Deleted temporary local backup file."
			exit
		else
			echo "$(log_timestamp_error) Could not delete local backup file /tmp/tos-backup-${VER}-${TIME}_${DATE}.zip."
			exit
		fi
	fi
	### Deleting temporary backup file for remote backup with file prefix
	if [ "$1" == "remote" ] && [ -n ${BACKUP_FILE_PREFIX} ]
        then
		echo "$(log_timestamp_info) Deleting temporary backup file /tmp/${BACKUP_FILE_PREFIX}-tos-backup-${VER}-${TIME}_${DATE}.zip."
		if [ -e "/tmp/${BACKUP_FILE_PREFIX}-tos-backup-${VER}-${TIME}_${DATE}.zip" ]
		then
			rm -rf /tmp/${BACKUP_FILE_PREFIX}-tos-backup-${VER}-${TIME}_${DATE}.zip
			echo "$(log_timestamp_info) Done. Deleted temporary local backup file."
			exit
		else
			echo "$(log_timestamp_error) Could not delete local backup file /tmp/${BACKUP_FILE_PREFIX}-tos-backup-${VER}-${TIME}_${DATE}.zip."
			exit
		fi
	fi
}

### Actual method for FTP transfers
ftp_transfer() {
	### Check if necessary variables have been set
	if [ -z "${USERNAME}" ] || [ -z "${PASSWORD}" ] || [ -z "${SERVER}" ]
	then
		echo "$(log_timestamp_error) Missing mandatory settings for remote backup. Please start the script with --reconfigure."
		exit
	fi
	### Copying backup to remote server via FTP
	if [ -z ${BACKUP_FILE_PREFIX} ]
	then
		echo "$(log_timestamp_info) Starting FTP filetransfer:"
		### If everything went well we can now copy the backup via FTP
		curl -v -T /tmp/tos-backup-${VER}-${TIME}_${DATE}.zip ftp://${USERNAME}:${PASSWORD}@${SERVER}/${BACKUP_DIR}
	else
		echo "$(log_timestamp_info) Starting FTP filetransfer:"
		#### If everything went well we can now copy the backup via FTP
		curl -v -T /tmp/${BACKUP_FILE_PREFIX}-tos-backup-${VER}-${TIME}_${DATE}.zip ftp://${USERNAME}:${PASSWORD}@${SERVER}/${BACKUP_DIR}
	fi
	### Calling function to delete temporary backup file
	cleanup_backupfolder remote
}

### Actual method for SCP transfers
scp_transfer() {
### If everything went well we can now copy the backup via scp
	### Check if necessary variables have been set
	if [ -z "${USERNAME}" ] || [ -z "${PASSWORD}" ] || [ -z "${SERVER}" ]
	then
		echo "$(log_timestamp_error) Missing mandatory settings for remote backup. Please start the script with --reconfigure."
		exit
	fi
	### Copying backup to remote server via SCP
	if [ -z ${BACKUP_FILE_PREFIX} ]
	then
		echo "$(log_timestamp_info) Starting SCP filetransfer:"
		/usr/local/st/expect -c "
			log_user 1
			set timeout -1
			spawn scp -o LogLevel=error /tmp/tos-backup-${VER}-${TIME}_${DATE}.zip ${USERNAME}@${SERVER}:${BACKUP_DIR}.
			expect {
				es/no { send yes\r; exp_continue }
				assword: { send ${PASSWORD}\r }
				such file or directory { send_user \"Remote directory doesn't exist or is not writeable\n\" }
				timeout { send_user \"Failed to receive password prompt from ${SERVER}. Aborting.\n\"; exit 1 }
				eof { send_user \"SCP failure. Aborting \n\"; exit 1 }
			}
			expect {
				100% { send_user \"Backup has been saved to remote server as ${BACKUP_DIR}tos-backup-${VER}-${TIME}_${DATE}.zip.\n\" }
				timeout { send_user \"Failed to successfully transfer file to ${SERVER}. Aborting.\n\"; exit 1 }
				eof { send_user \"Transmission failure. Aborting\n\"; exit 1 }
			}
			expect {
				ost connection { send_user \"Could not connect to remote server. Aborting transfer.\n\" }
				timeout { send_user \"Failed to connect to ${SERVER}. Aborting.\n\"; exit 1 }
				eof { send_user \"Connection failure. Aborting\n\"; exit 1 }
			}
			sleep 1
			exit
		"
	### Copy to remote server with backup file prefix
	else
		echo "$(log_timestamp_info) Starting SCP filetransfer."
		/usr/local/st/expect -c "
			log_user 1
			set timeout -1
			spawn scp -o LogLevel=error /tmp/${BACKUP_FILE_PREFIX}-tos-backup-${VER}-${TIME}_${DATE}.zip ${USERNAME}@${SERVER}:${BACKUP_DIR}.
			expect {
				es/no { send yes\r; exp_continue }
				assword: { send ${PASSWORD}\r }
				such file or directory { send_user \"Remote directory doesn't exist or is not writeable\n\" }
				timeout { send_user \"Failed to connect to ${SERVER}. Aborting.\n\"; exit 1 }
				eof { send_user \"SCP failure. Aborting.\n\"; exit 1 }
			}
			expect {
				100% { send_user \"Backup has been saved to remote server as ${BACKUP_DIR}${BACKUP_FILE_PREFIX}-tos-backup-${VER}-${TIME}_${DATE}.zip.\n\" }
				timeout { send_user \"Failed to successfully transfer file to ${SERVER}. Aborting.\n\"; exit 1 }
				eof { send_user \"Transmission failure. Aborting\n\"; exit 1 }
			}
			expect {
				ost connection { send_user \"Could not connect to remote server. Aborting transfer.\n\" }
				timeout { send_user \"Failed to connect to ${SERVER}. Aborting.\n\"; exit 1 }
				eof { send_user \"Connection failure. Aborting\n\"; exit 1 }
			}
			sleep 1
			exit
		"
	fi
	### Calling function to delete temporary backup file
	cleanup_backupfolder remote
}

### Enhance the functionality of the script by the use of these options
for arg in "$@"; do
	shift
	case "$arg" in
		"--help")			set -- "$@" "-h" ;;
		"--reconfigure")		set -- "$@" "-r" ;;
		"--show-configuration")		set -- "$@" "-s" ;;
		"--delete-configuration")	set -- "$@" "-d" ;;
		"--add-cronjob")		set -- "$@" "-c" ;;
		"--delete-cronjob")		set -- "$@" "-e" ;;
		*)				set -- "$@" "$arg"
	esac
done
while getopts "hrsdce" OPTION
do
	case "${OPTION}" in
		"h")	script_help ;;
		"r")	reconfigure_backup ;;
		"s")	show_configuration show_only ;;
		"d")	delete_configuration ;;
		"c")	add_cronjob no_wizard;;
		"e")	delete_cronjob ;;
		"?")	script_help; exit 1 ;;
	esac
done

### Run the backup script in correct order
initialize_backup

