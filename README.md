# SITE
Project manager for LEMP server\
(NginX, MariaDB, PHP-FPM) with multiversion PHP

### Installation example
- Web server
```
# apt install nginx
```
- Database server
```
# apt install mariadb-server
# mysql_secure_installation
# mysql
```
- SQL init statement
```
GRANT ALL ON *.* TO 'root'@'localhost' IDENTIFIED BY 'root' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EXIT;
```
- PHP multiversion

/etc/apt/sources.list.d/php.list:

deb https://packages.sury.org/php/ bullseye main
```
# wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
# apt update
# apt install php{8.1,8.0,7.4}-{fpm,mbstring,gd,intl,xml,curl,mysql}
```
- Prepare SITE helper
```
$ cp site.sh ~/.local/lib/
```
- End of the **~/.profile** file:
```
. $HOME/.local/lib/site.sh
```
- Restart shell, setup
```
$ site setup
```
### How to use
#### Remove the environment
```
$ site unset [ --force | -f ]
```
#### Create new site
```
$ site a | add website [ --root | -r PATH ] [ --php | -p X.Y ] [ --force | -f ]
```
- --root - project doc root relative path (index.php)
- --php	- PHP version - setting another than default system version, EXTENDED site with name websiteXY will be created beside the default version site.
- --force - create **new** index.php in **new** docroot
#### Remove site
```
$ site r | rm website [ --php | -p X.Y ] [ --force | -f ]
```
* --php - PHP version - when set, only the selected EXTENDED site will be removed.
* --force - all EXTENDED sites, base site + source code will be removed.
#### Disable / enable site
```
$ site d | dis / e | ena website
```
#### List sites
```
$ site l | list
```
#### Help
```
$ site -
```
#### Services
```
$ svc [ p | r | s  service(s) ][ v X.Y ]
```
* p - stop
* r - restart
* s - start
* v - switch default PHP version
* \- - list services
* h - help
#### Composer
```
$ (cd project_directory...)
$ cps [ a | i | u | r package ]
```
* a - _require_	- add package
* i - _install_	- install dependency
* u - _update_ - update package
* r - _remove_ - remove package
* \- - list shortcuts
#### Clear cache
```
$ (cd project_directory...)
$ clc
```
#### Examples
_Create empty site **webarchive**_
```
$ site add webarchive
```
* docroot **www**
* PHP **current** version

_Create EXTENDED site beside **webarchive**_
```
$ site add webarchive --php 7.0
```
* site URL - **webarchive70**
* PHP7.0

_Create site **stack** from existing source_
```
$ site add stack
```
* docroot **original** (obtained)

_Restart **NginX** and **MariaDB** servers_
```
$ svc r ng db
```
_Stop all **PHP-FPM** services_
```
$ svc p php
```
_Switch default **PHP** version to **7.0**_
```
$ svc v 7.0
```
_Create project_
```
$ cd ~/virt
$ cps cp nette/web-project sandbox	# composer create project
$ site add sandbox									# setup web application
$ site add sandbox --php 7.4				# setup extension for PHP7.4
$ svc r g 1 4												# restart services nginx, php8.1, php7.4
```
