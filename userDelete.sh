#!/bin/bash

#This script disables, deletes, and/or archives users on the local system 

ARCHIVE_DIR="/archive"

#Display to usage 
usage(){
	echo "Usage: ${0} [-dra] USER [USERNAME]"
	echo "Disable a local linux account."
	echo "  -d Deletes accounts instead of disabling them."
	echo "  -r Removes the home directory associated with the account(s)."
	echo "  -a Creates an archive of the home directory associated with the account(s)."
 exit 1
}

#For the superuser control
if [[ "${UID}" -ne 0 ]]
	then
	echo "Please run with sudo or as root."
        exit 1
fi

#Options parsing 

while getopts dra OPTION
do 
	case ${OPTION} in 
		d) DELETE_USER="true";;
		r) REMOVE_OPTION="-r";;
		a) ARCHIVE="true";;
		?) usage;;
	esac
done

#For remove the option while leaving the remaining arguments
shift "$(( OPTIND - 1 ))"

#For help if the user doesn't supply at least one argument 
if [[ "${#}" -lt 1 ]]
	then
		usage
fi

#Loop through all the usernames supplied as arguments.
for USERNAME in "${@}"
do	
	echo "Processing user: ${USERNAME}"

#To make sure uid of the account is at least 1000.
        USERID=$(id -u ${USERNAME})
	if [[ "${USERID}" -lt 1000 ]]
	then	
		echo "Refusing to remove the ${USERNAME} account with UID ${USERID}."
	       	exit 1
	fi

#Create an archive if requested to do so
	if [[ "${ARCHIVE}" = "true" ]]
	then 
		#Make sure the ARCHIVE_DIR directory exists
		if [[ ! -d "${ARCHIVE_DIR}" ]]
		then
			echo "Creating ${ARCHIVE_DIR} directory."
			mkdir -p ${ARCHIVE_DIR}
			if [[ "${?}" -ne 0 ]]
			then	
				echo "The archive directory ${ARCHIVE_DIR} could not be created."
				exit 1
			fi
		fi
		
		#Archive the user's home directory and move it into the ARCHIVE_DIR
		HOME_DIR="/home/${USERNAME}"
		ARCHIVE_FILE="${ARCHIVE_DIR}/${USERNAME}.tgz"
		if [[ -d "${HOME_DIR}" ]]
		then	
			echo "Archiving ${HOME_DIR} to ${ARCHIVE_FILE}"
			tar -zcf ${ARCHIVE_FILE} ${HOME_DIR} > /dev/null
			if [[ "${?}" -ne 0 ]]
			then
				echo "Could not create ${ARCHIVE_FILE}."
				exit 1
			fi
		else
			echo "${HOME_DIR} does not exist or is not a directory."
			exit 1
		fi
	fi


	if [[ "${DELETE_USER}" = "true" ]]
	then
		#Delete the user 
		userdel ${REMOVE_OPTION} ${USERNAME}
	
		#To check
		if [[ "${?}" -ne 0 ]]
		then	
			echo "The account ${USERNAME} was not deleted."
			exit 1
		fi
		echo "The account ${USERNAME} was deleted."
	else
		chage -E 0 ${USERNAME}

		#To check 
		if [[ "${?}" -ne 0 ]]
		then
			echo "The account ${USERNAME} was not disabled."
			exit 1
		fi
		echo "The account ${USERNAME} was disabled."
	fi

done

exit 0




