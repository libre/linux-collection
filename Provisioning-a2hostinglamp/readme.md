# A2hostinglamp.sh
A2 Hosting Lamp is a provisioning script intended for development use. It allows to deploy a Web space, DB and Wordpress in a few seconds and completely automatic.

## Functional dependencies

- OS: Ubuntu LTS / Debian
  - Webservice Apache2 + Modules : SSL, HEADERS, REWRITE 
  - PHP 7.X : Mod PHP or FPM
  - wp-cli
  - curl
  - sendmail
  - mariadb (Mysql).

* Tested : *
- Ubuntu 18.04.4 LTS (bionic)


## Screenshot 
<p align="center">
  <img src="screenshot.png" width="350" title="Screenshot">
</p>

## Installation

The script checks for dependencies and stops if there is a problem with your system. 
So just download the script and make it executable. It is necessary to have root or sudo rights.
 
```
cd /usr/src/
curl "https://raw.githubusercontent.com/libre/linux-collection/Provisioning-a2hostinglamp/prov_a2hostinglamp.sh"
cp prov_a2hostinglamp.sh /usr/local/sbin
chown +x /usr/local/sbin/prov_a2hostinglamp.sh
```

## Usage


```
Usage: prov_a2hostinglamp.sh -domain exemple.com -name exemple -db yes -wordpress full -debug 0
-domain exemple.com or www.exemple.com
-name exemple not use dot or special charts
-db yes|no (default no) creating user/db for website
-wordpress minimal|full|minimalexemple|fullexemple
-debug 0|1|2|3 (verbose) default 1 (0 very silent

minimal : Wordpress lastupdate minimal
minimalexemple : Wordpress minimal and content exemple
full : Wordpress fullinstall and jetpack
fullexemple : Wordpress fullinstall/jetpack and content exemple

Usage: prov_a2hostinglamp.sh --help
```

If you specify the Wordpress option, you do not need to provide the db option. It will be created automatically.
The Full version, includes Jetpack and several plugins essential for security, statistics and performance. Also, the full function includes several bootstrap theme selections.


## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.
Please make sure to update tests as appropriate.

## License

[GPLv3](https://www.gnu.org/licenses/gpl-3.0.html)