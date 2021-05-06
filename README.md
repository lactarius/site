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
# mysql_secure_installation ... (initialize server)
```
- PHP multiversion
```
# wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
# apt update
# apt install php{8.0,7.4,7.0}-{fpm,mbstring,gd,intl,xml,curl,mysql}
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
$ cps [ a | i | u | r package ]
```
* a - _require_	- add package
* i - _install_	- install dependency
* u - _update_ - update package
* r - _remove_ - remove package
* \- - list shortcuts
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
$ cps c
: nette/web-project nette-blog
$ site add nette-blog
$ svc r ng 8
```
