# SaaS Manager by Shell.sh
SaaS Manager by Shell Lamp is a provisioning script intended for development use. 
It allows to deploy a Web space, DB and Wordpress in a few seconds and completely automatic.

## Functional 
- Backup Management
- Manage Vhosts
- Userspace separation Apache2 ITK
- Creating Host, user, ftp, db and Wordpress install. 

## Functional dependencies

- OS: Ubuntu LTS / Debian
  - Webservice Apache2 + Modules : SSL, HEADERS, REWRITE, ITK
  - PHP 7.X : Mod PHP or FPM
  - wp-cli
  - curl
  - vsftpd
  - sendmail
  - mariadb (Mysql).

* Tested : *
- Ubuntu 18.04.4 LTS (bionic)


## Screenshot 
<p align="center">
  <img src="https://raw.githubusercontent.com/libre/saasweb-by-shell/main/scrennshot.png" width="450" title="Screenshot">
</p>

## Installation

The script checks for dependencies and stops if there is a problem with your system. 
So just download the script and make it executable. It is necessary to have root or sudo rights.
 
```
cd /usr/src/
git clone https://github.com/libre/saasweb-by-shell.git
cd saasweb-by-shell/saasmanager/
chmod +x *
cp * /usr/local/bin/
```

## Usage

```
Usage: saasprovisioning.sh -domain exemple.com -name exemple -db yes -wordpress full -debug 0
-domain exemple.com or www.exemple.com
-name exemple not use dot or special charts
-db yes|no (default no) creating user/db for website
-wordpress minimal|full|minimalexemple|fullexemple
-debug 0|1|2|3 (verbose) default 1 (0 very silent

minimal : Wordpress lastupdate minimal
minimalexemple : Wordpress minimal and content exemple
full : Wordpress fullinstall and jetpack
fullexemple : Wordpress fullinstall/jetpack and content exemple

Usage: saasprovisioning.sh --help
```

If you specify the Wordpress option, you do not need to provide the db option. It will be created automatically.
The Full version, includes Jetpack and several plugins essential for security, statistics and performance. Also, the full function includes several bootstrap theme selections.


## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.
Please make sure to update tests as appropriate.

## License

[GPLv3](https://www.gnu.org/licenses/gpl-3.0.html)