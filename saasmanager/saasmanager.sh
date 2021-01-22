#!/bin/bash
#
#    Program : saasbackup.sh
#      Author : Libre github.com/libre/
#==========================================================================
PROGNAME=`basename $0`
PROGPATH=`echo $0 | /bin/sed -e 's,[\\/][^\\/][^\\/]*$,,'`
datelog=`date "+%F_%H-%M-%S"`
PID=/tmp/saasbackup.pid
TMPSQL=/tmp/saasbackup.sql
WEBROOT=/var/www
LOG=/var/log/saasbackup.log
# Check
check() {
        #Check running root proection
        if [ ! $UID = 0 ]; then
                echo "Please run as root or system"
                exit 1
        fi
}

function gauge() {
        {
                for ((i = $2 ; i <= $3 ; i+=1)); do
                        sleep 1
                        echo $i
                done
        } | whiptail --title "SaaS Backup Manager, Please Wait" --gauge "$1"  10 60 $2
}

welcom() {
        whiptail --title "SaaS Manager Expresshoster.com" --msgbox "This is SaaS Manager for Expresshoster.com. You must hit OK to continue." 8 78
        soft
}

soft() {
        OPTION=$(whiptail --title "Menu SaaS Manager" --menu "Please chose the function SaaS Backup Manager" 40 60 8 \
        "1" "List Website info" \
        "2" "Provisioning Website" \
        "3" "Backup Website" \
        "4" "Restore Website" \
		"5"	"Disable Website" \
		"6"	"Enable Website" \
        "7" "Look Log Job backup and restore" 3>&1 1>&2 2>&3)
        exitstatus=$?
        if [ $exitstatus = 0 ]; then
                if [ "$OPTION" = 1 ]; then
                        hostname=`cat /etc/hostname`
                        listwebsites=`ls -l $WEBROOT | awk '{ print $9 }'`
                        whiptail --title "Website hosted to $hostname" --msgbox "List of Website hosted :\n $listwebsites \n" 60 60
                        soft
                fi
        fi

        if [ "$OPTION" = 2 ]; then
                hostname=`cat /etc/hostname`
                if (whiptail --title "Provisioning to $hostname" --yesno "Provisioning Wordpress ?" 10 60) then
                        DISTROS=$(whiptail --title "Provisioning Wordpress to $hostname" --radiolist \
                        "What is the Wordpress distro of your choice?" 15 60 4 \
                        "minimal" "Minimal Wordpress" ON \
                        "full" "Full Wordpress (Plugin, jetpack, themes)" OFF 3>&1 1>&2 2>&3)
                        exitstatus=$?
                        if [ $exitstatus = 0 ]; then
                                if (whiptail --title "Provisioning to $hostname" --yesno "Provisioning $DISTROS and Exemple Article and data ?" 10 60) then
                                        webname=$(whiptail --title "Provisioning to $hostname" --inputbox "Nickname for your website?" 10 60 myblog 3>&1 1>&2 2>&3)
                                        exitstatus=$?
                                        if [ $exitstatus = 0 ]; then
                                                DISTROS=`echo -n \"$DISTROS\" ; echo \"exemple\"`
                                                weburl=$(whiptail --title "Provisioning to $hostname" --inputbox "Domaine URL ?" 10 60 myblog.myweb.com 3>&1 1>&2 2>&3)
                                                exitstatus=$?
                                                if [ $exitstatus = 0 ]; then
                                                    provisioning -domain $weburl -name $webname -db yes -wordpress $DISTROS
													echo "Exit SaaS Backup Manager"
													exit 0
                                                else
                                                    soft
                                                fi
                                        else
                                                soft
                                        fi
                                else
                                        webname=$(whiptail --title "Provisioning to $hostname" --inputbox "Nickname for your website?" 10 60 myblog 3>&1 1>&2 2>&3)
                                        exitstatus=$?
                                        if [ $exitstatus = 0 ]; then
                                                weburl=$(whiptail --title "Provisioning to $hostname" --inputbox "Domaine URL ?" 10 60 myblog.myweb.com 3>&1 1>&2 2>&3)
                                                exitstatus=$?
                                                if [ $exitstatus = 0 ]; then
                                                        provisioning -domain $weburl -name $webname -db yes -wordpress $DISTROS
                                                else
                                                        soft
                                                fi
                                        else
                                                soft
                                        fi
                                fi
                        else
                                soft
                        fi
                else
                        if [ $exitstatus = 0 ]; then
                                if (whiptail --title "Provisioning to $hostname" --yesno "Provisioning Database for Website ?" 10 60) then
                                        webname=$(whiptail --title "Provisioning to $hostname" --inputbox "Nickname for your website?" 10 60 myblog 3>&1 1>&2 2>&3)
                                        exitstatus=$?
                                        if [ $exitstatus = 0 ]; then
                                                weburl=$(whiptail --title "Provisioning to $hostname" --inputbox "Domaine URL ?" 10 60 myblog.myweb.com 3>&1 1>&2 2>&3)
                                                exitstatus=$?
                                                if [ $exitstatus = 0 ]; then
                                                    provisioning -domain $weburl -name $webname -db yes
													echo "Exit SaaS Backup Manager"
													exit 0														
                                                else
                                                        soft
                                                fi
                                        else
                                                soft
                                        fi
                                else
                                        webname=$(whiptail --title "Provisioning to $hostname" --inputbox "Nickname for your website?" 10 60 myblog 3>&1 1>&2 2>&3)
                                        exitstatus=$?
                                        if [ $exitstatus = 0 ]; then
                                                weburl=$(whiptail --title "Provisioning to $hostname" --inputbox "Domaine URL ?" 10 60 myblog.myweb.com 3>&1 1>&2 2>&3)
                                                exitstatus=$?
                                                if [ $exitstatus = 0 ]; then
                                                    provisioning -domain $weburl -name $webname -db no
													echo "Exit SaaS Backup Manager"
													exit 0
                                                else
                                                    soft
                                                fi
                                        else
                                                soft
                                        fi
                                fi
                        else
                                soft
                        fi
                fi
        fi

        if [ "$OPTION" = 3 ]; then
                hostname=`cat /etc/hostname`
                # First List Backup
                COUNTER=1
                RADIOLIST=""  # variable where we will keep the list entries for radiolist dialog
                for i in $WEBROOT/; do
                                RADIOLIST="$RADIOLIST $i off "
                                let COUNTER=COUNTER+1
                done
                yourchoice=$(whiptail --title "Backup wizard to $hostname" --noitem --radiolist "Select Website" 28 90 $COUNTER $RADIOLIST 3>&1 1>&2 2>&3)
                if [ "${yourchoice}" = "" ]; then
                        # Canceled
                        soft
                fi
                if (whiptail --title "Backup Wizard to $hostname" --yesno "Backup Database for Website ?" 10 60) then
                        dbpass=$(whiptail --title "Backup wizard to $hostname" --inputbox "Pass DB your website?" 10 60 myblog 3>&1 1>&2 2>&3)
                        exitstatus=$?
                        if [ $exitstatus = 0 ]; then
                                saasbackup -name $yourchoice -dbname $yourchoice -dbuser $yourchoice -dbpass $dbpass
								soft
                        else
                                soft
                        fi
                else
                        saasbackup -name $yourchoice
						soft
                fi
        fi

        if [ "$OPTION" = 4 ]; then
                hostname=`cat /etc/hostname`
                # First List Backup
                COUNTER=1
                RADIOLIST=""  # variable where we will keep the list entries for radiolist dialog
                for i in $WEBROOT/; do
                                RADIOLIST="$RADIOLIST $i off "
                                let COUNTER=COUNTER+1
                done
                yourchoice=$(whiptail --title "Restore wizard to $hostname" --noitem --radiolist "Select Website" 28 90 $COUNTER $RADIOLIST 3>&1 1>&2 2>&3)
                if [ "${yourchoice}" = "" ]; then
                        # Canceled
                        soft
                fi

                FCOUNTER=1
                FRADIOLIST=""  # variable where we will keep the list entries for radiolist dialog
                for i in $WEBROOT/$yourchoice/backup; do
                                FRADIOLIST="$FRADIOLIST $i off "
                                let FCOUNTER=FCOUNTER+1
                done
                yourchoicef=$(whiptail --title "Restore wizard to $hostname" --noitem --radiolist "Select Backup for $yourchoice" 28 90 $COUNTER $RADIOLIST 3>&1 1>&2 2>&3)
                if [ "${yourchoice}" = "" ]; then
                        # Canceled
                        soft
                fi
                if (whiptail --title "Restore Wizard to $hostname" --yesno "Restore Database for Website ?" 10 60) then
                        dbpass=$(whiptail --title "Restore wizard to $hostname" --inputbox "Pass DB your website?" 10 60 myblog 3>&1 1>&2 2>&3)
                        exitstatus=$?
                        if [ $exitstatus = 0 ]; then
                                saasrestore -name $yourchoicef -dbname $yourchoice -dbuser $yourchoice -dbpass $dbpass
								soft
                        else
                                soft
                        fi
                else
                        saasbackup -name $yourchoicef
						soft
                fi
        fi
       if [ "$OPTION" = 5 ]; then
                hostname=`cat /etc/hostname`
                # First List Backup
                COUNTER=1
                RADIOLIST=""  # variable where we will keep the list entries for radiolist dialog
                for i in $WEBROOT/; do
                                RADIOLIST="$RADIOLIST $i off "
                                let COUNTER=COUNTER+1
                done
                yourchoice=$(whiptail --title "Disable wizard to $hostname" --noitem --radiolist "Select Website for disable ?" 28 90 $COUNTER $RADIOLIST 3>&1 1>&2 2>&3)
                if [ "${yourchoice}" = "" ]; then
                        # Canceled
                        soft
                fi
                if (whiptail --title "Disable Wizard to $hostname" --yesno "Disable the $yourchoice Website ?" 10 60) then
					a2dissite $yourchoice.conf  > /dev/null
					apachectl -k graceful > /dev/null
					soft
                else
                    soft
                fi
        fi
       if [ "$OPTION" = 6 ]; then
                hostname=`cat /etc/hostname`
                # First List Backup
                COUNTER=1
                RADIOLIST=""  # variable where we will keep the list entries for radiolist dialog
                for i in $WEBROOT/; do
                                RADIOLIST="$RADIOLIST $i off "
                                let COUNTER=COUNTER+1
                done
                yourchoice=$(whiptail --title "Enable wizard to $hostname" --noitem --radiolist "Select Website for disable ?" 28 90 $COUNTER $RADIOLIST 3>&1 1>&2 2>&3)
                if [ "${yourchoice}" = "" ]; then
                        # Canceled
                        soft
                fi
                if (whiptail --title "Enable Wizard to $hostname" --yesno "Disable the $yourchoice Website ?" 10 60) then
					a2dissite $yourchoice.conf  > /dev/null
					apachectl -k graceful > /dev/null
					soft
                else
                    soft
                fi
        fi		
        if [ "$OPTION" = 7 ]; then
                cat $LOG | more
                echo "Exit SaaS Backup Manager"
                exit 0
        else
                echo "Exit SaaS Backup Manager"
                exit 0
        fi
        exit 0
}

check
welcom
exit 0
