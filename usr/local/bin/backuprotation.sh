#!/bin/bash
#
#     Program : backuprotation.sh
#      Author : Libre github.com/libre/
#==========================================================================
PROGNAME=`basename $0`
PROGPATH=`echo $0 | /bin/sed -e 's,[\\/][^\\/][^\\/]*$,,'`
datelog=`date "+%F_%H-%M-%S"`
REVISION=`echo '$Revision: 1.0.0 $' | sed -e 's/[^0-9.]//g'`
WEBROOT="/var/www"
#set -x
# Check
check() {
	#Check running root proection
	if [ ! $UID = 0 ]; then
		echo "$datelog Please run as root or system"
		echo "For help use -help"
		exit 1
	fi
	if [ -z "${WEBSITECUSTOMER}" ]; then
		echo "$datelog Website name Not specified       [STOPED]"
		echo "For help use -help"
		exit 1
	fi
	if [ -z "${ACTION}" ]; then
		ACTION="no"
	fi
	if [ "${ACTION}" == "yes" ] || [ "${ACTION}" == "Yes" ] || [ "${ACTION}" == "YES" ] || [ "${ACTION}" == "oui" ] || [ "${ACTION}" == "Oui" ]; then
		echo "$datelog Real action confirmed, i am delete old backup "
		ACTION="yes"
	else 
		echo "$datelog /!\ WARNING : Action delete not confirmed, only simulation"
		ACTION="no"				
	fi
	if [ ! -d "${WEBROOT}/${WEBSITECUSTOMER}" ]; then
		echo "$datelog Website name not existe [STOPED]"
		echo "For help use -help"
		exit 1
	fi
	if [ ! -d "${WEBROOT}/${WEBSITECUSTOMER}/backup" ]; then
		echo "$datelog Folder Backup for Website ${CHECKCUSTOMEREXIST} not existe [STOPED]"
		echo "For help use -help"
		exit 1
	fi
	if [ -z "${ROTATION}" ]; then
		echo "$datelog Value rotation is empty  [STOPED]"
		echo "For help use -help"
		exit 1
	fi
	if [ ${ROTATION} -ge "357" ]; then
		echo "$datelog Value rotation over up (max 357 day) [STOPED]"
		echo "For help use -help"
		exit 1
	fi
	if [ ${ROTATION} -le "1" ]; then
		echo "$datelog Value 0 or 1 in not autorized    (minimul less 1 backup) [STOPED]"
		echo "For help use -help"
		exit 1
	fi
	rotation
}

rotation() {
	#Count of backup for website :
	COUNTBKF=`ls -lAX ${WEBROOT}/${WEBSITECUSTOMER}/backup/ | grep WEBROOT | sed '1d' | awk '{ print $9 }' | wc -l`
	if [ ${COUNTBKF} > ${ROTATION} ]; then
		DIFBKF=`echo    $((COUNTBKF - ROTATION))`
		if [ $DIFBKF -lt 0 ]; then 
			echo "Value is negative... not eligible backup for delete found"
		elif [ $DIFBKF -gt 0 ]; then 
			LISTDELBKF=$(mktemp)
			ls -lAX ${WEBROOT}/${WEBSITECUSTOMER}/backup/ | grep WEBROOT | sed '1d' | awk '{ print $9 }' | head -n ${DIFBKF} > ${LISTDELBKF}
		else 
			echo "Value = 0 backup diff not eligible backup for delete found"
		fi 
	fi
	if [ -a "${LISTDELBKF}" ]; then
		while IFS= read -r line
		do
			if [ ${ACTION} == "no" ]; then 
				echo "[SIMULATION] Old Backup ${WEBROOT}/${WEBSITECUSTOMER}/backup/$line  [DELETED]"
			fi 
			if [ ${ACTION} == "yes" ]; then 
				echo "rm -f ${WEBROOT}/${WEBSITECUSTOMER}/backup/$line OK"
				echo "Old Backup ${WEBROOT}/${WEBSITECUSTOMER}/backup/$line  [DELETED]"
			fi 			
			CHECKDBNAME=`echo $line | tr -d 'WEBROOT'`
			CHECKBKF=`ls -lAX ${WEBROOT}/${WEBSITECUSTOMER}/backup/ | grep "DATABASE${CHECKDBNAME}" | awk '{ print $9 }' | wc -l`
			if [ ! ${CHECKBKF} -eq 1 ]; then
				if [ ${ACTION} == "no" ]; then 
					echo "[SIMULATION] Old DB Backup ${WEBROOT}/${WEBSITECUSTOMER}/backup/DATABASE${CHECKDBNAME} [DELETED]"
				fi 
				if [ ${ACTION} == "yes" ]; then 
					echo "rm -f ${WEBROOT}/${WEBSITECUSTOMER}/backup/DATABASE${CHECKDBNAME} OK"
					echo "Old DB Backup ${WEBROOT}/${WEBSITECUSTOMER}/backup/DATABASE${CHECKDBNAME} [DELETED]"
				fi 					
			fi
		done < "${LISTDELBKF}"
		rm -f ${LISTDELBKF}
	fi
	echo "$datelog Rotation for ${WEBSITECUSTOMER} [Finished]"
	exit 1
}


print_usage() {
	echo "Usage: $PROGNAME [-name myweb] [-rotation 7 ] [-delete yes ]"
	echo "  -name (folder root of website (not folder webroot, folder root of user)"
	echo "  -rotation number of last backup"
	echo "  -delete yes not specified, only simulation ! NOT DELETED."
	echo ""
	echo " ex: $PROGNAME -name myweb -rotation 7 -delete yes"
	echo " The folder is ${WEBROOT}/myweb"
	echo " The backup folder is ${WEBROOT}/myweb/backup/"
	echo ""
	echo "Usage: $PROGNAME -help"
	echo "Usage: $PROGNAME -version"
}
print_help() {
	echo "$PROGNAME $REVISION"
	echo ""
	echo "SaaS Manager Suite"
	echo ""
	print_usage
	echo ""
	echo "SaaS Manager Suite. © expresshoster.com 2020"
	echo ""
	exit 0
}

while test -n "$1"; do
	case "$1" in
		-help)
			print_help
			;;
		-version)
			echo "$PROGNAME $REVISION"
			;;
		-name)
			WEBSITECUSTOMER=$2;
			shift;
			;;
		-rotation)
			ROTATION=$2;
			shift;
			;;
		-delete)
			ACTION=$2;
			shift;
			;;				
		*)
			echo "Unknown argument: $1"
			print_usage
			;;
	esac
	shift
done
check
echo "unknow error"
exit 1