#!/bin/bash
#
#    Program : prov_a2hostinglamp.sh
#       Name : Provisioning Apache2 LAMP Hosting
#    Author  : https://github.com/libre
#    Purpose : Script Bot Provisionning Webhosting
#      Notes : See --help for details
#==========================================================================

PROGNAME=`basename $0`
PROGPATH=`echo $0 | /bin/sed -e 's,[\\/][^\\/][^\\/]*$,,'`
REVISION=`echo '$Revision: 1.0 $' | sed -e 's/[^0-9.]//g'`
AUTHOR="https://github.com/libre"
ROOTWWW="/var/www"
TMPROOT="/var/tmp"
STATE_WARNING="STOPPED"
STATE_ERROR="ERROR"
STATE_UNKNOWN="UNKNOW"
STATE_OK="OK"
DATELOG=`date "+%Y-%m-%d %H:%M:%S"`
IP=`ip address show | grep inet | grep global | awk '{ print $2 }' | awk -F '/' '{ print $1 }'`
ROOTMYSQL='root'
# Obfusqued Password. encode pwd root db base64. 
PWDENCRYPTEDMYSQL='ZGVtbw=='
## Template Vhost.
#
#
vhost_template() {
        echo -e "<IfModule mod_ssl.c>" >> $VHOSTAPACHE
        echo -e "        <VirtualHost $DOMAIN:443>" >> $VHOSTAPACHE
        echo -e "                ServerAdmin webmaster@$DOMAIN" >> $VHOSTAPACHE
        echo -e "                            ServerName $DOMAIN" >> $VHOSTAPACHE
        echo -e "                DocumentRoot /var/www/$NAME/web" >> $VHOSTAPACHE
        echo -e "                ErrorLog /var/www/$NAME/log/error.log" >> $VHOSTAPACHE
        echo -e "                CustomLog /var/www/$NAME/log/access.log combined" >> $VHOSTAPACHE
        echo -e "                SSLEngine on" >> $VHOSTAPACHE
        echo -e "                SSLCertificateFile      /etc/ssl/certs/ssl-cert-snakeoil.pem" >> $VHOSTAPACHE
        echo -e "                SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key" >> $VHOSTAPACHE
		echo -e "                AssignUserID $NAME $NAME" >> $VHOSTAPACHE
        echo -e "                <FilesMatch \"\.(cgi|shtml|phtml|php)$\">" >> $VHOSTAPACHE
        echo -e "                                SSLOptions +StdEnvVars" >> $VHOSTAPACHE
        echo -e "                </FilesMatch>" >> $VHOSTAPACHE
        echo -e "                <Directory /usr/lib/cgi-bin>" >> $VHOSTAPACHE
        echo -e "                               SSLOptions +StdEnvVars" >> $VHOSTAPACHE
        echo -e "                </Directory>" >> $VHOSTAPACHE
        echo -e "        </VirtualHost>" >> $VHOSTAPACHE
        echo -e "</IfModule>" >> $VHOSTAPACHE
        echo -e "\e[96m[ $DATELOG ]\e[39m Provisioning Vhost is created \e[32m Wait" $RETURNSCREEN
        echo -e "\e[96m[ $DATELOG ]\e[39m Activation vHost \e[92m Actived" $RETURNSCREEN
}

## Template Htaccess.
#
#
htaccess_template() {
		DIRECTORYWEB="$ROOTWWW/$NAME/web"
        echo '# BEGIN WordPress' >> $DIRECTORYWEB/.htaccess
        echo 'RewriteRule ^index\.php$ – [L]' >> $DIRECTORYWEB/.htaccess
        echo 'RewriteCond %{REQUEST_FILENAME} !-f' >> $DIRECTORYWEB/.htaccess
        echo 'RewriteCond %{REQUEST_FILENAME} !-d' >> $DIRECTORYWEB/.htaccess
        echo 'RewriteRule . /index.php [L]' >> $DIRECTORYWEB/.htaccess
        echo '# END WordPress' >> $DIRECTORYWEB/.htaccess
}

# Function All command Found befor running script.
# Check Value entry option validity.
init() {
		# Check as Root user. 
		if (( $EUID != 0 )); then
			echo -e "\e[96m[ $DATELOG ]\e[39m Please run as root \e[91mAborting."
			exit
		fi

        # Check command exist.
        command -v apache2 >/dev/null 2>&1 || { echo -e "\e[96m[ $DATELOG ]\e[39m I require apache2 but it's not installed.  \e[91mAborting." >&2; exit 1; }
        command -v a2ensite >/dev/null 2>&1 || { echo -e "\e[96m[ $DATELOG ]\e[39m I require a2ensite but it's not installed.  \e[91mAborting." >&2; exit 1; }
        command -v apachectl >/dev/null 2>&1 || { echo -e "\e[96m[ $DATELOG ]\e[39m I require apachectl but it's not installed.  \e[91mAborting." >&2; exit 1; }
		check_modrewrite=`apachectl -M | grep rewrite  | wc -l`
		if [ "$check_modrewrite" -eq 0 ]; then
				echo -e "\e[96m[ $DATELOG ]\e[39m Mode Rewrite is not actived \e[93m Wait"
				a2enmod rewrite
				/etc/init.d/apache2 reload
				echo -e "\e[96m[ $DATELOG ]\e[39m Mode Rewrite is not actived \e[92m Actived"
		fi
		check_headers=`apachectl -M | grep headers  | wc -l`
		if [ "$check_headers" -eq 0 ]; then
				echo -e "\e[96m[ $DATELOG ]\e[39m Mode headers is not actived, let me active... \e[93m Wait"
				a2enmod headers
				/etc/init.d/apache2 reload
				echo -e "\e[96m[ $DATELOG ]\e[39m Mode headers is not actived, let me active... \e[92m Actived"				
		fi
		check_ssl=`apachectl -M | grep ssl  | wc -l`
		if [ "$check_ssl" -eq 0 ]; then
				echo -e "\e[96m[ $DATELOG ]\e[39m Mode ssl is not actived, let me active... \e[93m Wait"
				echo -e "\e[96m[ $DATELOG ]\e[39m Self Signed SSL 443  \e[93m Wait"
				a2enmod ssl
				/etc/init.d/apache2 reload
				echo -e "\e[96m[ $DATELOG ]\e[39m Self Signed SSL 443 \e[92m Actived"
		fi
		check_ssl=`apachectl -M | grep itk  | wc -l`		
		if [ "$check_ssl" -eq 0 ]; then
				echo -e "\e[96m[ $DATELOG ]\e[39m Mode ITK is not actived, let me active... \e[93m Wait"
				echo -e "\e[96m[ $DATELOG ]\e[39m ITK  \e[93m Wait"
				a2enmod mpm_itk
				/etc/init.d/apache2 reload
				echo -e "\e[96m[ $DATELOG ]\e[39m ITK \e[92m Actived"
				check_ssl=`apachectl -M | grep itk  | wc -l`
				if [ "$check_ssl" -eq 0 ]; then
					echo -e "[ $DATELOG ]\e[39m ITK Its require  but it's not installed.  \e[91mAborting." >&2;
					exit 1;
				fi
		fi		
        command -v mysql >/dev/null 2>&1 || { echo -e "[ $DATELOG ] I require mysql it's not installed.  \e[91mAborting." >&2; exit 1; }
        command -v wp >/dev/null 2>&1 || { echo -e "[ $DATELOG ]\e[39m I require wp it's not installed.  \e[91mAborting." >&2; exit 1; }
        command -v curl >/dev/null 2>&1 || { echo -e "[ $DATELOG ]\e[39m I require curl but it's not installed.  \e[91mAborting." >&2; exit 1; }
        command -v sendmail >/dev/numm 2>&1 || { echo -e "[ $DATELOG ]\e[39m I require sendmail but it's not installed.  \e[91mAborting." >&2; exit 1; }
		if [ -z $DEBUGFLAG ]; then
			DEBUGFLAG="4"
		fi
		if [ $DEBUGFLAG == 0 ] ; then
				#echo -e "\e[96m[ $DATELOG ]\e[39m Very Silent Provisioning  \e[92m Pass"
				WPCLI="wp --allow-root --no-color --path=$ROOTWWW/$NAME/web --quiet "
				MYSQL="mysql --silent "
				CURL="curl --silent "
				RETURNSCREEN="> /dev/null"
		elif [ $DEBUGFLAG == 1 ]; then
				echo -e "\e[96m[ $DATELOG ]\e[39m Debug 1 Actived\e[92m Pass"
				WPCLI="wp --allow-root --no-color --path=$ROOTWWW/$NAME/web --quiet "
				MYSQL="mysql --silent "
				CURL="curl --silent "
				RETURNSCREEN=""
		elif [ $DEBUGFLAG == 2 ]; then
				echo -e "\e[96m[ $DATELOG ]\e[39m Debug 2 Actived\e[92m Pass"
				WPCLI="wp --allow-root --no-color --path=$ROOTWWW/$NAME/web "
				MYSQL="mysql -v "
				CURL="curl --verbose "
				RETURNSCREEN=""
		elif [ $DEBUGFLAG == 3 ]; then
				echo -e "\e[96m[ $DATELOG ]\e[39m Debug 3 Actived\e[92m Pass"
				WPCLI="wp --allow-root --no-color --path=$ROOTWWW/$NAME/web "
				MYSQL="mysql -v "
				CURL="curl --verbose "
				set -x
				RETURNSCREEN=""
		else
				echo -e "\e[96m[ $DATELOG ]\e[39m Normal Provisioning view\e[92m Pass"
				RETURNSCREEN=""
				WPCLI="wp --allow-root --no-color --path=$ROOTWWW/$NAME/web --quiet "
				MYSQL="mysql --silent "
				CURL="curl --silent "
		fi
		echo -e "██████╗ ██████╗  ██████╗ ██╗   ██╗██╗███████╗██╗ ██████╗ ███╗   ██╗██╗███╗   ██╗ ██████╗                   " $RETURNSCREEN
		echo -e "██╔══██╗██╔══██╗██╔═══██╗██║   ██║██║██╔════╝██║██╔═══██╗████╗  ██║██║████╗  ██║██╔════╝                   " $RETURNSCREEN
		echo -e "██████╔╝██████╔╝██║   ██║██║   ██║██║███████╗██║██║   ██║██╔██╗ ██║██║██╔██╗ ██║██║  ███╗                  " $RETURNSCREEN
		echo -e "██╔═══╝ ██╔══██╗██║   ██║╚██╗ ██╔╝██║╚════██║██║██║   ██║██║╚██╗██║██║██║╚██╗██║██║   ██║                  " $RETURNSCREEN
		echo -e "██║     ██║  ██║╚██████╔╝ ╚████╔╝ ██║███████║██║╚██████╔╝██║ ╚████║██║██║ ╚████║╚██████╔╝                  " $RETURNSCREEN
		echo -e "╚═╝     ╚═╝  ╚═╝ ╚═════╝   ╚═══╝  ╚═╝╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝╚═╝  ╚═══╝ ╚═════╝                   " $RETURNSCREEN
		echo -e "                                                                                                           " $RETURNSCREEN
		echo -e " █████╗ ██████╗ ██╗  ██╗ ██████╗ ███████╗████████╗██╗███╗   ██╗ ██████╗ ██╗      █████╗ ███╗   ███╗██████╗ " $RETURNSCREEN
		echo -e "██╔══██╗╚════██╗██║  ██║██╔═══██╗██╔════╝╚══██╔══╝██║████╗  ██║██╔════╝ ██║     ██╔══██╗████╗ ████║██╔══██╗" $RETURNSCREEN
		echo -e "███████║ █████╔╝███████║██║   ██║███████╗   ██║   ██║██╔██╗ ██║██║  ███╗██║     ███████║██╔████╔██║██████╔╝" $RETURNSCREEN
		echo -e "██╔══██║██╔═══╝ ██╔══██║██║   ██║╚════██║   ██║   ██║██║╚██╗██║██║   ██║██║     ██╔══██║██║╚██╔╝██║██╔═══╝ " $RETURNSCREEN
		echo -e "██║  ██║███████╗██║  ██║╚██████╔╝███████║   ██║   ██║██║ ╚████║╚██████╔╝███████╗██║  ██║██║ ╚═╝ ██║██║     " $RETURNSCREEN
		echo -e "╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝   ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝     " $RETURNSCREEN
		echo -e ""                                                                                                           
		echo -e "\e[39m						$PROGNAME | $REVISION" $RETURNSCREEN
		echo -e "\e[39m						$AUTHOR" $RETURNSCREEN
		echo -e "" $RETURNSCREEN
        if [ -z $DOMAIN ]; then
                echo -e '\e[96m[ $DATELOG ]\e[39m Domain not found, please use help. \e[91mAborting. \e[39m ' $RETURNSCREEN
				echo -e 'So, please check  use --help ' $RETURNSCREEN
                exit 1
        fi
        if [ -z $NAME ]; then
                echo -e '\e[96m[ $DATELOG ]\e[39m Name not found, please use help. \e[91mAborting. \e[39m ' $RETURNSCREEN
				echo -e 'So, please check  use --help ' $RETURNSCREEN
                exit 1
        fi

        ONE=1
        VALUE=`echo $DOMAIN | awk '{if(length($0)<=253 && $0 !~ /\.$/ && $0 !~ /^[[:digit:]]/ && $0 !~ /^-/ && $0 !~ /-$/ && $0 !~ /[[:space:]]/ && $0 !~ /[[:punct:]]/ && $0 !~ /[[:cntrl:]]/)      {
                                num=split($0, A,"."); if(num==1){ print 1
                                          }
                                else      {
                                                for(i=1;i<=num;i++){
                                                    if(length(A[i])<=63){
                                                                                                                k++
                                                    }
                                                };
                                          }
          } if(k==num){  print 1
                       }
          }'`
        if [[ $VALUE == $ONE ]] ; then
                        echo -e "\e[96m[ $DATELOG ]\e[39m You have entered domain name $DOMAIN\e[92m Pass" $RETURNSCREEN
                else
                        echo -e "\e[96m[ $DATELOG ]\e[39m Please enter corect name as it is NOT matching the standards.\e[91mAborting. \e[39m " $RETURNSCREEN
                        exit 1
                fi
        if [[ "$NAME" =~ [^a-zA-Z0-9] ]]; then
                        echo -e '\e[96m[ $DATELOG ]\e[39m Name is only Alphanumeric. \e[91mAborting. \e[39m ' $RETURNSCREEN
                        exit 1
        fi
        if [ -z $WPREQUEST ]; then
                        WPREQUEST="none"
        fi
        if [ $WPREQUEST == "none" ]; then
                        echo -e "\e[96m[ $DATELOG ]\e[39m Not provisioning Wordpress.\e[92m Pass" $RETURNSCREEN
        elif  [ $WPREQUEST == "minimal" ]; then
                        DB="yes"
                        echo -e "\e[96m[ $DATELOG ]\e[39m Ok, order Provisioning Wordpress minimal\e[92m Pass" $RETURNSCREEN
        elif  [ $WPREQUEST == "minimalexemple" ]; then
                        DB="yes"
                        echo -e "\e[96m[ $DATELOG ]\e[39m Ok, order Provisioning Wordpress minimal and demo content\e[92m Pass" $RETURNSCREEN
        elif  [ $WPREQUEST == "full" ]; then
                        DB="yes"
                        echo -e "\e[96m[ $DATELOG ]\e[39m Ok, order Provisioning Wordpress full\e[92m Pass" $RETURNSCREEN
        elif  [ $WPREQUEST == "fullexemple" ]; then
                        DB="yes"
                        echo -e "\e[96m[ $DATELOG ]\e[39m Ok, order Provisioning Wordpress full and demo content\e[92m Pass" $RETURNSCREEN
        else
                        echo -e "\e[96m[ $DATELOG ]\e[39m I am not reconize your wp Request. So, please check and try again or use --help \e[91mAborting. \e[39m " $RETURNSCREEN
                        exit 1
        fi
        if [ -z $DB ]; then
                        DB="no"
        fi
        if [ $DB == "yes" ]; then
                        echo -e "\e[96m[ $DATELOG ]\e[39m Ok I am provisionging DB For your Website.\e[92m Pass" $RETURNSCREEN
        elif  [ $DB == "no" ]; then
                        echo -e "\e[96m[ $DATELOG ]\e[39m I am not provisionging DB. Value is empty or no\e[92m Pass" $RETURNSCREEN
        else
                        echo -e "\e[96m[ $DATELOG ]\e[39m ERROR!!! I am not reconize your DB Request. So, please check and try again or use --help\e[91mAborting.\e[39m " $RETURNSCREEN
                        exit 1
        fi
        if [ -z $ROOTMYSQL ]; then
                        echo -e "\e[96m[ $DATELOG ]\e[39m ERROR!!!  not user define in script, testing by root user\e[92m Pass" $RETURNSCREEN
                        ROOTMYSQL="root"
        fi
        if [ -z $PWDENCRYPTEDMYSQL ]; then
                        echo -e "\e[96m[ $DATELOG ]\e[39m ERROR!!! not password define in script, please define root password Mysql/MariaDB.\e[91mAborting.\e[39m " $RETURNSCREEN
                        exit 1
        fi		
        if [ ! -z $ROOTMYSQL ]; then
                        echo -e "\e[96m[ $DATELOG ]\e[39m Ok, let me decrypt pwd Mysql admin for use.\e[92m Pass" $RETURNSCREEN
                        PWDMYSQL=`echo $PWDENCRYPTEDMYSQL | base64 --decode`
        fi
}

# Print revision
print_revision() {
        echo -e "Script  : $PROGNAME"
        echo -e "Version : $REVISION"
}

# Print Usage
print_usage() {
        echo -e "Usage: $PROGNAME -domain exemple.com -name exemple -db yes -wordpress full -debug 0"
        echo -e "      -domain exemple.com or www.exemple.com"
        echo -e "      -name exemple not use dot or special charts"
        echo -e "      -db yes|no (default no) creating user/db for website"
        echo -e "      -wordpress minimal|full|minimalexemple|fullexemple"
        echo -e "          -debug 0|1|2|3 (verbose) default 1 (0 very silent"
        echo -e ""
        echo -e "          minimal : Wordpress lastupdate minimal"
        echo -e "          minimalexemple : Wordpress minimal and content exemple"
        echo -e "          full : Wordpress fullinstall and jetpack"
        echo -e "          fullexemple : Wordpress fullinstall/jetpack and content exemple"
        echo -e ""
        echo -e "Usage: $PROGNAME --help"
}

# Print Help
print_help() {
        # print_revision $PROGNAME $REVISION
        echo -e ""
        echo -e "Provisioning Apache2 LAMP Hosting"
        echo -e ""
        print_usage
        echo -e ""
        echo -e "https://github.com/libre/linux-collection | 2020"
        echo -e ""
        exit 0
}

# Update datelog .
datelog() {
        DATELOG=`date "+%Y-%m-%d %H:%M:%S"`
}

# Function Création DB For Website.
provmysql() {
        datelog
        if [ $DB == "yes" ]; then
                echo -e "\e[96m[ $DATELOG ]\e[39m Provisioning  DB db_$NAME \e[32m Wait" $RETURNSCREEN
                DBNAME="db_$NAME"
                DBUSER="db_$NAME"
                DBPASS=`tr -cd '[:alnum:]' < /dev/urandom | fold -w12 | head -n1`
                TMPSQL=$(mktemp /tmp/sqljob.XXXXXX)
                echo -e "CREATE DATABASE $DBNAME;" >> $TMPSQL
                echo -e "GRANT ALL PRIVILEGES ON $DBNAME.* TO \"$DBUSER\"@\"localhost\" IDENTIFIED BY \"$DBPASS\";" >> $TMPSQL
                echo -e "FLUSH PRIVILEGES;" >> $TMPSQL
                $MYSQL -u $ROOTMYSQL -p$PWDMYSQL < $TMPSQL
                datelog
                echo -e "\e[96m[ $DATELOG ]\e[39m $MYSQLDB $DBNAME \e[92m DB and User Created" $RETURNSCREEN
        fi
}

# Function Création Directory Website.
provdir() {
        datelog
        DIRECTORYWEB="$ROOTWWW/$NAME"
        echo -e "\e[96m[ $DATELOG ]\e[39m Provisioning directory for website \e[32m Wait" $RETURNSCREEN
        if [ ! -d "$DIRECTORYWEB" ] ; then
                useradd -s /bin/bash -m -d /home/$NAME
				usermod -a -G $NAME www-data
				mkdir "$DIRECTORYWEB" ;
                mkdir -m o-rwx "$DIRECTORYWEB/web";
                chmod -m o-rwx $DIRECTORYWEB/web
                mkdir -m o-rwx "$DIRECTORYWEB/log";
                mkdir -m o-rwx "$DIRECTORYWEB/backup";
                chmod +755 -R $DIRECTORYWEB/backup
                chown -R $NAME. $DIRECTORYWEB/web
                chown -R $NAME. $DIRECTORYWEB/log
				FTPPASS=`tr -cd '[:alnum:]' < /dev/urandom | fold -w14 | head -n1`
				echo -e "$FTPPASS\n$FTPPASS" | (passwd ${NAME})
                find $DIRECTORYWEB/web -type f -exec chmod 644 {} +
                find $DIRECTORYWEB/web -type d -exec chmod 755 {} +
        echo -e "\e[96m[ $DATELOG ]\e[39m Directory for website \e[92m Created" $RETURNSCREEN				
        else
                datelog
                echo -e "\e[96m[ $DATELOG ]\e[39m Directory Existe ! \e[91mAborting." $RETURNSCREEN
                echo -e "\e[96m[ $DATELOG ]\e[39m UNKNOWN: Folder existe \e[91mAborting."
                exit 1
        fi
}

# Function création Vhost Apache2 SSL
provapache() {
        datelog
        echo -e "\e[96m[ $DATELOG ]\e[39m Provisioning Apache2 Vhost \e[32m Wait" $RETURNSCREEN
        VHOSTAPACHE="/etc/apache2/sites-available/$NAME.conf"
        vhost_template
        #ln -s /etc/apache2/sites-available/$NAME.conf /etc/apache2/sites-enabled/$NAME.conf
        # Add hostname to vhost machine.
        datelog
        echo "$IP $DOMAIN" >> /etc/hosts
        a2ensite $NAME.conf > /dev/null
        apachectl -k graceful > /dev/null 
        datelog
        echo -e "\e[96m[ $DATELOG ]\e[39m Activation vHost \e[92m Created" $RETURNSCREEN
}

# Function Création Wordpress Option
provfirstwp() {
        datelog
        if [ ${WPREQUEST} == "minimal" ] || [ ${WPREQUEST} == "minimalexemple" ]; then
                DIRECTORYWEB="$ROOTWWW/$NAME/web"
                cd $DIRECTORYWEB
                WEBURL=`echo -e "https://$DOMAIN"`
                TITLE=`echo -e "$NAME"`
                WPUSER="webmaster"
                WPPASS=`tr -cd '[:alnum:]' < /dev/urandom | fold -w12 | head -n1`
                echo -e "\e[96m[ $DATELOG ]\e[39m Provisioning Wordpress base for $WEBURL \e[32m Wait" $RETURNSCREEN
                cd $DIRECTORYWEB
                $WPCLI core download --force
                $WPCLI core config --dbname=$DBNAME --dbuser=$DBUSER --dbpass=$DBPASS --skip-check
                $WPCLI core install --url=$WEBURL --title=$TITLE --admin_user=$WPUSER --admin_email=webmaster@$DOMAIN --admin_password=$WPPASS
                #$WPCLI language core install fr_FR
                #$WPCLI site switch-language fr_FR
                datelog
                htaccess_template
				fixpermwp
                echo -e "\e[96m[ $DATELOG ]\e[39m Provisioning Wordpress base for $WEBURL \e[92m Created" $RETURNSCREEN
        elif [ ${WPREQUEST} == "full" ] || [ ${WPREQUEST} == "fullexemple" ]; then
                DIRECTORYWEB="$ROOTWWW/$NAME/web"
                WEBURL=`echo -e "https://$DOMAIN"`
                TITLE=`echo -e "$NAME"`
                WPUSER="webmaster"
                WPPASS=`tr -cd '[:alnum:]' < /dev/urandom | fold -w12 | head -n1`
                echo -e "\e[96m[ $DATELOG ]\e[39m Provisioning Wordpress base for $WEBURL \e[32m Wait" $RETURNSCREEN
                cd $DIRECTORYWEB
                $WPCLI core download --locale=fr_FR --force
                $WPCLI core config --dbname=$DBNAME --dbuser=$DBUSER --dbpass=$DBPASS --skip-check
                $WPCLI core install --url=$WEBURL --title=$TITLE --admin_user=$WPUSER --admin_email=webmaster@$DOMAIN --admin_password=$WPPASS
                echo -e "\e[96m[ $DATELOG ]\e[39m Provisioning Wordpress base for $WEBURL \e[92m Installed" $RETURNSCREEN				
                datelog
				htaccess_template
				fixpermwp
				echo -e "\e[96m[ $DATELOG ]\e[39m Provisioning Best Plugin for Stats / Protection base for $WEBURL \e[32m Wait" $RETURNSCREEN
				$WPCLI plugin install google-analytics-for-wordpress $RETURNSCREEN
				$WPCLI plugin install wp-cloudflare-page-cache $RETURNSCREEN
				$WPCLI plugin install login-recaptcha $RETURNSCREEN
				echo -e "\e[96m[ $DATELOG ]\e[39m Provisioning Best Plugin for Stats / Protection base for $WEBURL \e[92m Installed" $RETURNSCREEN				
				echo -e "\e[96m[ $DATELOG ]\e[39m Provisioning Best Plugin for Stats / Protection base for $WEBURL \e[32m Wait" $RETURNSCREEN							
				$WPCLI plugin install loginizer $RETURNSCREEN
				$WPCLI plugin install wp-limit-login-attempts $RETURNSCREEN
				$WPCLI plugin install hide-my-wp $RETURNSCREEN
				$WPCLI plugin install wpforms-lite $RETURNSCREEN
				$WPCLI plugin install hide-page-and-post-title $RETURNSCREEN
				$WPCLI plugin install hide-metadata  $RETURNSCREEN
				$WPCLI plugin activate loginizer $RETURNSCREEN
				$WPCLI plugin activate wp-limit-login-attempts $RETURNSCREEN
				$WPCLI plugin activate hide-my-wp $RETURNSCREEN
				$WPCLI plugin activate wpforms-lite $RETURNSCREEN
				$WPCLI plugin activate hide-page-and-post-title $RETURNSCREEN
				$WPCLI plugin activate hide-metadata  $RETURNSCREEN
				echo -e "\e[96m[ $DATELOG ]\e[39m Provisioning Best Plugin for Security WP base for $WEBURL \e[92m Installed" $RETURNSCREEN					
				echo -e "\e[96m[ $DATELOG ]\e[39m Provisioning Jetpack Plugin WP base for $WEBURL \e[32m Wait" $RETURNSCREEN
				$WPCLI plugin install jetpack $RETURNSCREEN
				$WPCLI plugin install jetpack-module-control $RETURNSCREEN 
				$WPCLI plugin install hide-jetpack-promotions $RETURNSCREEN
				$WPCLI plugin install post-views-for-jetpack $RETURNSCREEN 
				$WPCLI plugin activate jetpack $RETURNSCREEN
				$WPCLI plugin activate jetpack-module-control $RETURNSCREEN 
				$WPCLI plugin activate hide-jetpack-promotions $RETURNSCREEN
				$WPCLI plugin activate post-views-for-jetpack $RETURNSCREEN 				
				echo -e "\e[96m[ $DATELOG ]\e[39m Provisioning Jetpack Plugin WP base for $WEBURL \e[92m Installed" $RETURNSCREEN				
				echo -e "\e[96m[ $DATELOG ]\e[39m Provisioning Best Bootstrap Themes WP base for $WEBURL \e[32m Wait" $RETURNSCREEN				
				$WPCLI theme install ultrabootstrap $RETURNSCREEN
				$WPCLI theme activate ultrabootstrap $RETURNSCREEN
				$WPCLI theme install innofit $RETURNSCREEN
				$WPCLI theme install screenr $RETURNSCREEN
				$WPCLI theme install integral $RETURNSCREEN
				$WPCLI theme install vw-one-page $RETURNSCREEN 
				echo -e "\e[96m[ $DATELOG ]\e[39m Provisioning Best Bootstrap Themes WP base for $WEBURL \e[92m Installed" $RETURNSCREEN				
				#$WPCLI language core install fr_FR
                #$WPCLI site switch-language fr_FR
                datelog
        fi
}

# Function fix permissions.
fixpermwp() {
	echo -e "\e[96m[ $DATELOG ]\e[39m Check Permissions WP \e[32m Wait" $RETURNSCREEN
	DIRECTORYWEB="$ROOTWWW/$NAME/web"
	cd $DIRECTORYWEB
	WP_ROOT=`echo $NAME`  # &lt;-- wordpress root directory
	WS_GROUP=`echo $NAME` # &lt;-- webserver group
	WP_OWNER=`echo $NAME` # &lt;-- wordpress owner
	#I add this condition because if the folder does not exist, you completely block your system until you can no longer start.! 
	#I wanted to share the experience with you because I had the case with a cron job which blocked a system because the folder no longer existed ....
	if [ ! -d ${WP_ROOT} ]; then 
		echo -e "\e[39mSTOP, The folder Wordpress not found !"
		echo -e "\e[39mPlease check the path"
		exit 1
	fi
	# reset to safe defaults
	find ${WP_ROOT} -exec chown ${WP_OWNER}:${WP_GROUP} {} \;
	find ${WP_ROOT} -type d -exec chmod 755 {} \;
	find ${WP_ROOT} -type f -exec chmod 644 {} \;
	 
	# allow wordpress to manage wp-config.php (but prevent world access)
	chgrp ${WS_GROUP} ${WP_ROOT}/wp-config.php
	chmod 660 ${WP_ROOT}/wp-config.php
	 
	# allow wordpress to manage .htaccess
	touch ${WP_ROOT}/.htaccess
	chgrp ${WS_GROUP} ${WP_ROOT}/.htaccess
	chmod 664 ${WP_ROOT}/.htaccess
	 
	# allow wordpress to manage wp-content
	find ${WP_ROOT}/wp-content -exec chgrp ${WS_GROUP} {} \;
	find ${WP_ROOT}/wp-content -type d -exec chmod 775 {} \;
	find ${WP_ROOT}/wp-content -type f -exec chmod 664 {} \;
	echo -e "\e[96m[ $DATELOG ]\e[39m Check Permissions WP \e[92m Checked" $RETURNSCREEN	
}

# Function Add Content to Wordpress
provcontent() {
        datelog
        if [ $WPREQUEST == "minimalexemple" ] || [ $WPREQUEST == "fullexemple" ] ; then
                DIRECTORYWEB="$ROOTWWW/$NAME/web"
                cd $DIRECTORYWEB
                # Create standard pages
                echo -e "\e[96m[ $DATELOG ]\e[39m Je crée les pages habituelles (Accueil, blog, contact...) \e[32m Wait" $RETURNSCREEN
                $WPCLI post create --post_type=page --post_title='Accueil' --post_status=publish
                $WPCLI post create --post_type=page --post_title='Blog' --post_status=publish
                $WPCLI post create --post_type=page --post_title='Contact' --post_status=publish
                $WPCLI post create --post_type=page --post_title='Mentions Légales' --post_status=publish
                datelog
                echo -e "\e[96m[ $DATELOG ]\e[39m Je crée les pages habituelles (Accueil, blog, contact...) \e[92m Created" $RETURNSCREEN				
                # Create fake posts
                echo -e "\e[96m[ $DATELOG ]\e[39m Je crée quelques faux articles \e[32m Wait" $RETURNSCREEN
                $CURL http://loripsum.net/api/5 | $WPCLI post generate --post_content --count=5
                datelog
				echo -e "\e[96m[ $DATELOG ]\e[39m Je crée quelques faux articles \e[92m Created" $RETURNSCREEN
                # Change Homepage
                echo -e "\e[96m[ $DATELOG ]\e[39m Je change la page d'accueil et la page des articles \e[32m Wait" $RETURNSCREEN
                $WPCLI option update show_on_front page
                $WPCLI option update page_on_front 3
                $WPCLI option update page_for_posts 4
                datelog
				echo -e "\e[96m[ $DATELOG ]\e[39m Je change la page d'accueil et la page des articles \e[92m Modified" $RETURNSCREEN
                # Menu  stuff
                echo -e "\e[96m[ $DATELOG ]\e[39m Je crée le menu principal, assigne les pages, et je lie l'emplacement du thème. \e[32m Wait" $RETURNSCREEN
                $WPCLI menu create "Menu Principal"
                $WPCLI menu item add-post menu-principal 3
                $WPCLI menu item add-post menu-principal 4
                $WPCLI menu item add-post menu-principal 5
                $WPCLI menu location assign menu-principal primary
				echo -e "\e[96m[ $DATELOG ]\e[39m Je crée le menu principal, assigne les pages, et je lie l'emplacement du thème. \e[92m Modified" $RETURNSCREEN				
                datelog
                # Misc cleanup
                echo -e "\e[96m[ $DATELOG ]\e[39m Je supprime Hello Dolly, les thèmes de base et les articles exemples \e[32m Wait" $RETURNSCREEN
                $WPCLI post delete 1 --force # Article exemple - no trash. Comment is also deleted
                $WPCLI post delete 2 --force # page exemple
                $WPCLI plugin delete hello
                $WPCLI theme delete twentytwelve
                $WPCLI theme delete twentythirteen
                $WPCLI theme delete twentyfourteen
                $WPCLI option update blogdescription ''
                datelog
                echo -e "\e[96m[ $DATELOG ]\e[39m Je supprime Hello Dolly, les thèmes de base et les articles exemples \e[92m Clean OK" $RETURNSCREEN				
                # Permalinks to /%postname%/
                echo -e "\e[96m[ $DATELOG ]\e[39m J'active la structure des permaliens \e[32m Wait" $RETURNSCREEN
                $WPCLI rewrite structure "/%postname%/" --hard
                $WPCLI rewrite flush --hard
                datelog
				echo -e "\e[96m[ $DATELOG ]\e[39m J'active la structure des permaliens  \e[92m Actived" $RETURNSCREEN
                # cat and tag base update
                $WPCLI option update category_base theme
                $WPCLI option update tag_base sujet
		fi
} 


# If we have arguments, process them.
#
exitstatus=$STATE_WARNING #default

while test -n "$1"; do
        case "$1" in
                        -domain)
                                DOMAIN=$2;
                                shift;
                                ;;
                        -name)
                                NAME=$2;
                                shift;
                                ;;
                        -db)
                                DB=$2;
                                shift;
                                ;;
                        -wordpress)
                                WPREQUEST=$2;
                                shift;
                                ;;
                        -debug)
                                DEBUGFLAG=$2;
                                shift;
                                ;;
                        --help)
                                        print_help
                                        exit $STATE_OK
                                        ;;
                        -h)
                                        print_help
                                        exit $STATE_OK
                                        ;;
                        --version)
                                        print_revision
                                        exit $STATE_OK
                                        ;;
                        -V)
                                        print_revision
                                        exit $STATE_OK
                                        ;;
                        *)
                                        echo -e "Unknown argument: $1"
                                        print_usage
                                        exit $STATE_UNKNOWN
                                        ;;
        esac
        shift
done

init
provdir
provapache
provmysql
provfirstwp
provcontent
datelog

rm -rf $TMPSQL
rm -rf ~/.wp-cli/cache
echo -e "\e[39m	"
echo -e "\e[39m	$DATELOG Job finished"
echo -e "\e[39m	"
echo -e "\e[91m/!\ \e[97m Please save information, not data saved in server \e[91m/!\ "
echo -e ""
echo -e "\e[97m------ [ $DATELOG ] ----------------------------"
echo -e "\e[39m	Date                 : $DATELOG"
echo -e "\e[39m	Site Name            : $NAME"
echo -e "\e[39m	Domain               : $DOMAIN"
echo -e "\e[39m	Folder Web           : $DIRECTORYWEB"
echo -e "\e[39m	"
echo -e "\e[39m	FTP USER             : $NAME"
echo -e "\e[39m	FTP Password         : $FTPPASS"
echo -e "\e[39m	"
echo -e "\e[39m	DB Provisioning      : $DB"
echo -e "\e[39m	DB Name              : $DBNAME"
echo -e "\e[39m	DB User              : $DBUSER"
echo -e "\e[39m	DB Password          : $DBPASS"
echo -e "\e[39m	"
echo -e "\e[39m	WPProvisioning       : $WPREQUEST"
echo -e "\e[39m	WPURL                : $WEBURL"
echo -e "\e[39m	WPUSER               : $WPUSER"
echo -e "\e[39m	WPMAIL               : webmaster@$DOMAIN"
echo -e "\e[39m	WPPASSWORD           : $WPPASS"
echo -e "\e[39m	"
echo -e "\e[39m	"
echo -e "\e[97m--- [ Provisioning Apache2 LAMP $REVISION ] ----"
echo -e "\e[39m	 Enjoy ;)"
exit 0
