#!/bin/bash
#
#    Program : saasrestore.sh
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
        echo "Usage: $PROGNAME [-action backup|restore] [-restorefile /mnt/mybackup/backup.tar.gz]"
        echo "          -backupname backup name file (not include WEBROOT or Extention (tar.gz)"
		echo "			ex: file is WEBROOT.MYWEBSITE.123120190456.tar.gz use name of backup : MYWEBSITE.123120190456"
		echo "			-dbname NAMEDATABASE, is specified backup db job. "
		echo "			-dbuser USERDB, is specified backup db job. **"
		echo "			-dbpass PASSDB, is specified backup db job. **"
		echo "          ** (required only for restore DB)"
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
	if [ "${RESTOREJOB}" = "" ]; then
			echo "$datelog Backup name Not specified			[STOPED]" >> $LOG
			exit 1
	fi
	RESTOREUSER=`echo $RESTOREJOB | awk -F '.' '{ print $2 }'`
	# IP
	if [ ! "${DBNAME}" = "" ]; then
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
		echo "$datelog Ok Restore DB Detected					[Wait]" >> $LOG
	fi
	# Webroot exist
	if [ ! -d "$WEBROOT/$RESTOREUSER/web" ]; then
		echo "$datelog Webroot  folder not exist			[ERROR]" >> $LOG
		echo "$datelog Web ERROR 							[STOPED]" >> $LOG
		exit 1
	fi
	# Check Backupfolder exist
	if [ ! -d "$WEBROOT/$RESTOREUSER/backup" ]; then
		echo "$datelog Webroot  folder not exist			[ERROR]" >> $LOG
		echo "$datelog Web ERROR 							[STOPED]" >> $LOG
		exit 1
	fi	
	RESTOREFILE="$WEBROOT/$RESTOREUSER/backup/WEBROOT.$WEBSITECUSTOMER.tar.gz"
	# BACKUPFOLDER  exist
	if [ ! -f "$RESTOREFILE" ]; then
		echo "$datelog BACKUPFIle 			not exist		[ERROR]" >> $LOG
		echo "$datelog Web ERROR 							[STOPED]" >> $LOG
		exit 1
	else
		WEBRESTOREFOLDER="$WEBROOT/$WEBSITECUSTOMER/web"
		WWWUSER=`echo $RESTOREUSER`
		WWWGROUP=`echo $RESTOREUSER`
	fi
	echo "$datelog All check OK							[Starting]" >> $LOG
	# Test is running 
	if [ -a $PID ]; then
		echo "$datelog Backup or Restore job is running Please wait ! 	[STOPED]" >> $LOG
		exit 1
	fi
	FILEINFOLDER="${BACKUPFOLDER}/${RESTOREFILE}"
	datelog=`date "+%F_%H-%M-%S"`
	echo "$datelog Restore Job started 					[Wait]" >> $LOG	
	echo "0 7" > $PID
	restorenow	
		
}

restorenow() {
	FILEINFOLDER="${BACKUPFOLDER}/${RESTOREFILE}"
	echo "1 7" > $PID
	datelog=`date "+%F_%H-%M-%S"`
	echo "$datelog Webservice 							[Stopped]" >> $LOG
	/etc/init.d/apache2 stop
	echo "2 7" > $PID
	datelog=`date "+%F_%H-%M-%S"`
	echo "$datelog Webroot erase						[Wait]" >> $LOG	
	rm -rf $WEBRESTOREFOLDER/*
	echo "3 7" > $PID
	datelog=`date "+%F_%H-%M-%S"`
	echo "$datelog Webroot erase						[OK]" >> $LOG

	if [ $BACKUPDB == 1 ]; then 	
		datelog=`date "+%F_%H-%M-%S"`
		echo "$datelog DB erase						[Wait]" >> $LOG		
		echo "SET FOREIGN_KEY_CHECKS = 0;" > $TMPSQL
		mysqldump --host ${HOSTDB} --add-drop-table --no-data -u ${DBUSER} --password=${DBPASS} ${DATABASE} | grep 'DROP TABLE' >> $TMPSQL
		echo "SET FOREIGN_KEY_CHECKS = 1;" >> $TMPSQL
		mysql --host ${HOSTDB} -u ${DBUSER} --password=${DBPASS} ${DATABASE} < $TMPSQL
		datelog=`date "+%F_%H-%M-%S"`
		echo "$datelog DB erase						[OK]" >> $LOG
		datelog=`date "+%F_%H-%M-%S"`
		echo "$datelog Restore $RESTOREFILE		[Wait]" >> $LOG
		echo "$datelog Restore DB		 					[Wait]" >> $LOG
		DUMPFILEFOR=`ls $FILEINFOLDER | awk -F "." '{ print "DATABASE""."$2"."$3"."$4".sql.gz" }'`
		#DUMPFILERESTORED=`ls $WEBROOT|grep .sql`
		gunzip -c $BACKUPFOLDER/$DUMPFILEFOR | mysql --host ${HOSTDB} -u ${DBUSER} --password=${DBPASS} ${DATABASE}		
		echo "4 7" > $PID
	fi
	cd /
	tar xfp $FILEINFOLDER -C /
	datelog=`date "+%F_%H-%M-%S"`
	echo "$datelog Restore $RESTOREFILE		[Ok]" >> $LOG	
	echo "$datelog Restore Owner file 	  					[Wait]" >> $LOG
	chown -R $WWWUSER:$WWWGROUP $WEBRESTOREFOLDER
	echo "5 7" > $PID
	datelog=`date "+%F_%H-%M-%S"`
	echo "$datelog Restore Owner file 						[Ok]" >> $LOG	

	#mysql --host ${HOSTDB} -u ${DBUSER} --password=${DBPASS} ${DATABASE} < $DUMPFILERESTORED
	datelog=`date "+%F_%H-%M-%S"`
	echo "$datelog Restore DB		 					[Ok]" >> $LOG	
	/etc/init.d/apache2 start
	echo "6 7" > $PID	
	echo "$datelog Webservice  						[Started]" >> $LOG
	echo "$datelog Cleanning Job	 					[Wait]" >> $LOG	
	rm -f $TMPSQL
	#rm -f $WEBROOT/$DUMPFILERESTORED
	echo "7 7" > $PID
	sleep 2
	rm -f $PID
	datelog=`date "+%F_%H-%M-%S"`
	echo "$datelog Cleanning Job	 					[Ok]" >> $LOG	
	echo "$datelog Restore $RESTOREFILE Job	[Finish]" >> $LOG	
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
                -backupname)
                    RESTOREJOB=$2;			
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





