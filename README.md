# SITE
LEMP with multiversion PHP project manager

#### Load SITE helper
```
. site.sh
```
#### Setup the environment
```
site setup
```
#### Remove the environment
```
site unset
```
#### Create new site
```
site a | add website [ --root | -r PATH ] [ --php | -p X.Y ] [ --force | -f ]
```
* --root - project doc root relative path (index.php)
* --php	- PHP version - setting another than default system version, EXTENDED site with name websiteXY will be created beside the default version site.
* --force - create **new** index.php in **new** docroot
#### Remove site
```
site r | rm website [ --php | -p X.Y ] [ --force | -f ]
```
* --php - PHP version - when set, only the selected EXTENDED site will be removed.
* --force - all EXTENDED sites, base site + source code will be removed.
#### Disable / enable site
```
site d | dis / e | ena website
```
#### List sites
```
site l | list
```
#### Services
```
svc [ p | r | s  service(s) ][ v X.Y ]
```
* p - stop
* r - restart
* s - start
* v - switch default PHP version

#### Examples
_Create empty site **webarchive**_
```
site add webarchive
```
* docroot **www**
* PHP **current** version

_Create EXTENDED site beside **webarchive**_
```
site add webarchive --php 7.0
```
* site URL - **webarchive70**
* PHP7.0

_Create site **stack** from existing source_
```
site add stack
```
* docroot **original** (obtained)

_Restart **NginX** and **MariaDB** servers_
```
svc r ng db
```
_Stop all **PHP-FPM** services_
```
svc p php
```
_Switch default **PHP** version to **7.0**_
```
svc v 7.0
```
