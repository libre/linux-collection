#!/bin/bash
#
#    Program : saasbackup.sh
#            :
#     Author : https://github.com/libre/linux-collection/
#    Purpose :
# Parameters : --help
#            : --version
#         
#      Notes : See --help for details
#==========================================================================

# Set Debug mode
#set -x

PROGNAME=`basename $0`
PROGPATH=`echo $0 | /bin/sed -e 's,[\\/][^\\/][^\\/]*$,,'`
REVISION=`echo '$Revision: 1.0.0 $' | sed -e 's/[^0-9.]//g'`
datelog=`date "+%F_%H-%M-%S"`
PID=/tmp/saasbackup.pid
TMPSQL=/tmp/saasbackup.sql
LOG=/var/log/saasbackup.log
WEBROOT=/var/www
HOSTDB=localhost

print_usage() {
        echo "Usage: $PROGNAME [-name myweb] [-dbname mywebdb ] [-dbuser userdb ] [-dbpass userpass ]"
        echo "          -name (folder root of website (not folder webroot, folder root of user"
		echo "			-dbname NAMEDATABASE, is specified backup db job. "
		echo "			-dbuser USERDB, is specified backup db job. "
		echo "			-dbpass PASSDB, is specified backup db job. "
        echo ""
        echo "Usage: $PROGNAME --help"
        echo "Usage: $PROGNAME --version"
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
#        support
}

function valid_ip() {
    local  ip=$HOSTDB
    local  stat=1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}
# Check
check() {
	#Check running root proection
	if [ ! $UID = 0 ]; then
		echo "Please run as root or system"
		exit 1
	fi
	# IP
	if [ "${WEBSITECUSTOMER}" = "" ]; then
			echo "$datelog Website name Not specified			[STOPED]" >> $LOG
			exit 1
	fi
	# IP
	if [ ! -z "${DATABASE}" ]; then
		BACKUPDB=1
		if [ "${DBUSER}" = "" ]; then
			echo "$datelog IP For DB User Not specified			[STOPED]" >> $LOG
			exit 1
		fi
		if [ "${DBPASS}" = "" ]; then
			echo "$datelog IP For DB Password Not specified		[STOPED]" >> $LOG
			exit 1
		fi
	else
		BACKUPDB=0
		echo "$datelog Ok Backup DB Detected					[Wait]" >> $LOG
	fi
	# Webroot exist
	if [ ! -d "$WEBROOT/$WEBSITECUSTOMER/web" ]; then
		echo "$datelog Webroot  folder not exist			[ERROR]" >> $LOG
		echo "$datelog Web ERROR 							[STOPED]" >> $LOG
		exit 1
	fi
	BACKUPFOLDER="$WEBROOT/$WEBSITECUSTOMER/backup"
	# BACKUPFOLDER  exist
	if [ ! -d "$BACKUPFOLDER" ]; then
		echo "$datelog BACKUPFOLDER  folder not exist		[ERROR]" >> $LOG
		echo "$datelog Web ERROR 							[STOPED]" >> $LOG
		exit 1
	fi
	echo "$datelog All check OK						[Starting]" >> $LOG
	# Test is running 
	if [ -a $PID ]; then
		echo "$datelog Backup is running Please wait ! 		[STOPED]" >> $LOG
		exit 1
	fi
	datelog=`date "+%F_%H-%M-%S"`
	echo "$datelog Backup Job started 				[Wait]" >> $LOG	
	echo "0 4" > $PID
	backupnow	
}

backupnow() {
	echo "1 4" > $PID
	datelog=`date +"%Y%m%d%H%M%S"`
	# naming an archive with current time and date
	BACKUP=$WEBSITECUSTOMER.$datelog
	NAMETARBAL="WEBROOT.$BACKUP.tar.gz"
	# naming a database dump with time and date as well
	if [ $BACKUPDB == 1 ]; then 
		DUMP=DATABASE.$BACKUP.sql.gz
		datelog=`date "+%F_%H-%M-%S"`
		echo "$datelog DB Dump Started						[Wait]" >> $LOG
		echo "2 4 $NAMETARBAL $DUMP" > $PID
		cd $BACKUPFOLDER
		mysqldump --host ${HOSTDB}  --user=${DBUSER} --password=${DBPASS} ${DATABASE}  | gzip -c > $DUMP
		datelog=`date "+%F_%H-%M-%S"`
		echo "$datelog DB Dump Started						[OK]" >> $LOG
	fi
	datelog=`date "+%F_%H-%M-%S"`
	echo "$datelog Webroot Dump Started					[Wait]" >> $LOG
	# create a compressed tar-gzipped archive of all website files and a website database dump
	echo "3 4 $NAMETARBAL $DUMP" > $PID
	cd $BACKUPFOLDER
	tar cPf $NAMETARBAL $WEBROOT/$WEBSITECUSTOMER/web
	datelog=`date "+%F_%H-%M-%S"`
	echo "4 4 $NAMETARBAL $DUMP" > $PID
	echo "$datelog Webroot Dump Finished					[OK]" >> $LOG
	sleep 2
	rm -f $PID
	datelog=`date "+%F_%H-%M-%S"`
	echo "$datelog Backup Temps Clean						[OK]" >> $LOG
	echo "$datelog Job Finished $BACKUP.tar.gz " >> $LOG
	echo "$datelog Job Finished $BACKUP.tar.gz"
	exit 0
}

while test -n "$1"; do
        case "$1" in
                --help|-h)
					print_help
					;;
                -V|--version)
					echo "$PROGNAME $REVISION"
					;;
                -name)
                    WEBSITECUSTOMER=$2;
					WWWUSER=$2;
					WWWGROUP=$2;				
                    shift;
                    ;;
				-dbname)
                    DATABASE=$2;
                    shift;
                    ;;					
				-dbuser)
                    DBUSER=$2;
                    shift;
                    ;;				
				-dbpass)
                    DBPASS=$2;
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





