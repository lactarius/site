######### Settings & Defaults #########
declare DEV_PATH="$HOME/virt"	# Projects directory
declare DOC_ROOT="www"			# Default Document Root
declare SITE_USER="$USER"		# FPM pool defaults
declare SITE_GROUP="$USER"		#
declare LISTEN_OWNER='www-data'	#
declare LISTEN_GROUP='www-data'	#
declare LOCALHOST='127.0.0.1'	#
declare CFG_EXT='.conf'			# Config files extension
declare -i COLOR=1				# Colored output
######### Paths #######################
declare CONF_PATH="/etc"							# System settings
declare LOG_PATH="/var/log/nginx"                   # HTTP Server log path
declare HTTP_PATH="$CONF_PATH/nginx"				# HTTP Server settings
declare HTTP_AVAILABLE="$HTTP_PATH/sites-available"	# Available sites
declare HTTP_ENABLED="$HTTP_PATH/sites-enabled"     # Enabled sites
declare HTTP_EXT_PATH="$HTTP_PATH/common"			# Extemded settings directory
declare PHP_PATH="$CONF_PATH/php"                   # PHP settings directory
declare PHP_LIST=($(ls $PHP_PATH))                  # Installed PHP versions list
declare DNS_PATH="$CONF_PATH/hosts"                 # Local DNS file
######### Opts ########################
declare CMD NAME URLNAME PHPV ROOT
declare -i FORCE

######### Templates ###################
# NginX
# common
common_tpl() {
    cat <<'EOT'
index index.html index.htm;

error_page   500 502 503 504  /50x.html;
location = /50x.html {
	root   html;
}

#location ~ \.(js|ico|gif|jpg|png|css|rar|zip|tar\.gz)$ { }

location ~ /\.(ht|gitignore) { # deny access to .htaccess files, if Apache's document root concurs with nginx's one
    deny all;
}

location ~ \.(neon|ini|log|yml)$ { # deny access to configuration files
    deny all;
}

location = /robots.txt  { access_log off; log_not_found off; }
location = /humans.txt  { access_log off; log_not_found off; }
location = /favicon.ico { access_log off; log_not_found off; }

proxy_buffer_size   128k;
proxy_buffers   4 256k;
proxy_busy_buffers_size   256k;

fastcgi_buffers 8 16k; fastcgi_buffer_size 32k;

client_max_body_size 45M;
client_body_buffer_size 128k;
EOT
}

# nette
nette_tpl() {
    cat <<'EOT'
try_files $uri $uri/ /index.php?$args;
EOT
}

# php
php_tpl() {
    cat <<'EOT'
index index.php index.html index.htm;

location ~ \.php$ {
	fastcgi_send_timeout 1800;
	fastcgi_read_timeout 1800;
	fastcgi_connect_timeout 1800;
	#fastcgi_pass	127.0.0.1:9000;
	fastcgi_pass	unix:/run/php/$server_name.sock;
	fastcgi_index	index.php;
    fastcgi_param	SCRIPT_FILENAME $document_root$fastcgi_script_name;
	include		fastcgi_params;
}
EOT
}

# site definition
# $1 - site name
# $2 - document root path
# $3 - log path
site_tpl() {
    cat <<EOT
server {
	listen 80;
	server_name $1;
	charset     utf-8;

	root $2;

	error_log   $3/$1.error.log;
	access_log  $3/$1.access.log;

    include common/common.conf;
    include common/php.conf;
    include common/nette.conf;
}
EOT
}

# testing index.php file
index_tpl() {
    cat <<EOT
<?php phpinfo();
EOT
}

# fpm pool
# $1 - site name
# $2 - user
# $3 - group
# #4 - listen owner
# #5 - listen group
pool_tpl() {
    cat <<EOT
[$1]
user = $2
group = $3
listen = /run/php/$1.sock
listen.owner = $4
listen.group = $5

pm = dynamic
pm.start_servers = 3
pm.max_children = 5
pm.min_spare_servers = 2
pm.max_spare_servers = 4
chdir = /
EOT
}

# SITE banner
banner_tpl() {
	cat <<EOT
  _____ _____ _______ ______
 / ____|_   _|__   __|  ____|
| (___   | |    | |  | |__
 \___ \  | |    | |  |  __|
 ____) |_| |_   | |  | |____
|_____/|_____|  |_|  |______|

    Webdeveloper helper
         ( LEMP )
https://github.com/lactarius/site

EOT
}

######### Utilities ###################
# is string an IPv4 address?
# $1 - tested string
is_ip4() {
    [[ $1 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

# is string an IPv6 address?
# $1 - tested string
is_ip6() {
    [[ $1 =~ ^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$ ]]
}

# sort array alphabetically
# $1 - array name
sort_array() {
    local -n array=$1
    IFS=$'\n' array=($(sort <<<"${array[*]}"))
    unset IFS
}

# search value in array
# $1 - needle
# $2 - array haystack name
# $3 - options (isf)
# options:	def. return - value, i - index
#			def. compare - as string, r - regular, n - numeric
#			def. quantity - none, f - first match, m - multiple matches, a - add to existing results
# $4 - result name
searcharray() {
	declare needle=$1 opt=$3 item chk
	declare -n haystack=$2 result=${4:-chk}
	declare -i i found=1

	[[ $opt =~ m ]] && result=()
    for ((i = 0; i < ${#haystack[@]}; i++)); do
        item="${haystack[$i]}"
        if [[ $opt =~ n && $item -eq $needle ]] || [[ $opt =~ r && $item =~ $needle ]] ||
        	[[ $item == $needle ]]; then
				found=0 ; [[ $opt =~ i ]] && item=$i
				[[ $opt =~ f ]] && result=$item
				[[ $opt =~ a|m ]] && result+=($item) || break
        fi
    done
    return $found
}

# Fill array with dirlist
# $1 - array name
# $2 - path (.)
# $3 - type f - files d - dirs (files)
# $4 - file extension ($CFG_EXT)
getdir() {
	declare -n array=$1
	declare path="${2:-.}" type=${3:-f} ext=${4:-$CFG_EXT} wc=*

	[[ $type == d ]] && wc=*/
	# load listing
	array=("$path/"$wc)
	# files => trailing .ext, dirs => trailing /
	[[ $type == f ]] && array=("${array[@]%$ext}") || array=("${array[@]%/}")
	# remove path
	array=("${array[@]##*/}")
	# empty dir
	array=("${array[@]%\*}")
}

# write text to file
# $1 - content
# $2 - file
write() {
    declare text="$1" file="$2"
    if [[ -w $(dirname $file) ]]; then
        printf '%s\n' "$text" >"$file"
    else
        printf '%s\n' "$text" | sudo tee "$file" >/dev/null 2>&1
    fi
}

# PHP current version number
# PHP 8.0.3 (cli) => 8.0
phpver() {
    php -v | sed -e '/^PHP/!d' -e 's/.* \([0-9]\+\.[0-9]\+\).*$/\1/'
}

# PHP version without period
# $1 - PHP version
# 7.4 => 74
phpversim() {
    echo "${1//./}"
}

# PHP default version switcher
# $1 - new default version
phpsw() {
    sudo update-alternatives --set php /usr/bin/php$1
    php -v
}

######### User interface ##############

# Color output
# Reset
Color_Off='\033[0m'       # Text Reset
# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White
# High Intensity
IBlack='\033[0;90m'       # Black
IRed='\033[0;91m'         # Red
IGreen='\033[0;92m'       # Green
IYellow='\033[0;93m'      # Yellow
IBlue='\033[0;94m'        # Blue
IPurple='\033[0;95m'      # Purple
ICyan='\033[0;96m'        # Cyan
IWhite='\033[0;97m'       # White

# Color parser
# $1 - source text
# $2 - no color
parsecolor() {
	declare result="$1"
	declare -i i color=${2:-$COLOR}
	declare -a colsource=('#b' '#B' '#c' '#C' '#g' '#G' '#p' '#P' '#r' '#R' '#w' '#W' '#y' '#Y') colcoded=($Blue $IBlue $Cyan $ICyan $Green $IGreen $Purple $IPurple $Red $IRed $White $IWhite $Yellow $IYellow)
	for (( i = 0; i < ${#colsource[@]}; i++ )); do
		((color)) && result="${result//${colsource[$i]}/${colcoded[$i]}}" ||
			result="${result//${colsource[$i]}/}"
	done
	((color)) && result+=$Color_Off
	echo "$result"
}

######### Messages & lists ############
declare TITLE_COL="$Yellow" UI_LINE
declare -i MST_COMMON=0 MST_ERROR=1 ECN LCN LSS_ON=0 LSS_OFF=1
declare -a MSG MST LST LSS SVC SVS SVO

# Generate & print dash
# $1 - length
# $2 - pattern (-)
# $3 - color (none) - TODO
pdash() {
	declare -i length=$1
	declare pattern=${2:--}
	(($1)) && printf -v UI_LINE "%.0s${pattern}" $(seq 1 $length)
	printf '%s\n' "$UI_LINE"
}

# Print text line
# $1 - text
# $2 - color
pline() {
	declare text="$(parsecolor "$1")"
	((COLOR)) && printf "${2}%b\n" "$text" || printf '%s\n' "$text"
}

# Print list item
# $1 - text
# $2 - status
# colors
# flags
pitem() {
	declare text="$1"
	declare -i status=$2
	declare -n colors=$3 flags=$4
	((COLOR)) && pline "$text" "${colors[$status]}" || pline "${flags[$status]} $text"
}

# Clear message stack
clrmsg() { MST=() ; MSG=() ; ECN=0 ; }

# Clear list
clrlst() { LSS=() ; LST=() ; LCN=0 ; }

# Add message
# $1 - message
# $2 - type (common)
addmsg() {
	declare -i type=${2:-$MST_COMMON}
	MSG+=("$1") ; MST+=($type) ; ((type)) && ECN+=1 ; return 0
}

# Add list item
# $1 - item
# $2 - item status (on)
additem() {
	declare -i status=${2:-$LSS_ON}
	LST+=("$1") ; LSS+=($status) ; LCN+=1
}

# Print messages
# $1 - title
msgout() {
	declare title="${1:-Notification}" text flag
	declare -i i
	declare -a col=("$Green" "$Red") flg=('-' 'E')

	pline "$title" "$TITLE_COL"
	pdash 40
	for (( i = 0; i < ${#MSG[@]}; i++ )); do
		pitem "${MSG[$i]}" ${MST[$i]} col flg
	done
	pdash
}

# Print list
# $1 - title
lstout() {
	declare title="${1:-List}"
	declare -i i
	declare -a col=("$Red" "$Green") flg=('-' '+')

	pline "$title" "$TITLE_COL"
	pdash 30
	for (( i = 0; i < LCN; i++ )); do
		pitem "${LST[$i]}" ${LSS[$i]} col flg
	done
	pdash
}

# print services
svcout() {
    declare op text
    declare -i i
	declare -a col=("$Red" "$Green") flg=('-' '+')

    pline "Service status" "$TITLE_COL"
	pdash 30
    if ((${#SVO[@]})); then
        for op in "${SVO[@]}"; do
			pline "$op" "$IYellow"
        done
        pdash
        SVO=()
    fi
    for ((i = 0; i < ${#SVC[@]}; i++)); do
		pitem "${SVC[$i]}" ${SVS[$i]} col flg
    done
    pdash
}

######### Site ########################
site_help() {
	echo -e "$(parsecolor "	#gSITE
	#w----------------------------------------------------------------------------------------------
	#ysite #Y[cmd] #y[name] [arg]\n
	#gCreate site\n
	#Yadd #y<name>\t\t\t#wCreate site #Wname #wwith default docroot #W$DOC_ROOT #won default #WPHP$(phpver)
	#Yadd #y<name> #Y--root src/www\t#wCreate site #Wname #wwith docroot #Wsrc/www #won default #WPHP$(phpver)
	#Yadd #y<name> #Y--php 7.3\t\t#wCreate site #Wname #wextension #Wname73 #won #WPHP7.3\n
	#gRemove site\n
	#Yrm #y<name>\t\t\t#wRemove site #Wname
	#Yrm #y<name> #Y--php 7.3\t\t#wRemove site #Wname #wextension #Wname73
	#Yrm #y<name> #Y--force\t\t#wRemove site #Wname #wwith sources\n
	#gOther\n
	#Ydis #y<name>\t\t\t#wDisable site #Wname
	#Yena #y<name>\t\t\t#wEnable site #Wname
	#Ylist\t\t\t\t#wList sites
	#Ysetup\t\t\t\t#wSetup environment
	#Yunset\t\t\t\t#wRemove environment
	#Yunset --force\t\t\t#wRemove #Wall existing projects #wand environment\n
	#gShorter notation\n
	#Yadd #y<name> #Y--root src/www #w= #Ya #y<name> #Y-r #ysrc/www #wetc...
	#w----------------------------------------------------------------------------------------------")"
}

# check SITE
checksite() {
	if [[ ! -d $DEV_PATH || ! -d $HTTP_EXT_PATH ]]; then
		[[ -z $1 ]] && addmsg "The #RSITE #ris not installed." $MST_ERROR
		return 1
	fi
}

# DNS records management
# $1 - operation (0:add, 1:delete) (add)
# $2 - subject site
# $3 - base site
host() {
	declare -i op=${1:-0} found basefound
    declare subject=${2:-$URLNAME} base=${3:-$NAME} line newline ip site msg
    declare -a list newlist words inline ip6 cache

	# load hosts
    mapfile -t list <"$DNS_PATH"
    for line in "${list[@]}"; do
        read -ra words <<<"$line"
        ip="${words[0]}"
        # IP address => parse line
        if is_ip4 "$ip" || is_ip6 "$ip"; then
            inline=()
            for site in "${words[@]:1}"; do
                [[ $site == $subject ]] && found=1 || inline+=($site)
            done
            if ((${#inline[@]})); then
                printf -v newline '%s\t%s' "$ip" "${inline[*]}"
				cache+=("$newline")
				is_ip6 $ip && ip6+=("${cache[@]}") || newlist+=("${cache[@]}")
				cache=()
            fi

        elif [[ $ip == '#'* ]]; then
            cache+=("$line")
        fi
    done

    # add new host
    if ((!op)); then
        printf -v newline '%s\t%s' $LOCALHOST $subject
        is_ip6 $LOCALHOST && ip6+=("$newline") || newlist+=("$newline")
    fi
	((${#ip6[@]})) && newlist+=('' "${ip6[@]}")
	((${#cache[@]})) && newlist+=("${cache[@]}")
	# operation
	if ((!op && !found || op && found)); then
		printf -v newline '%s\n' "${newlist[@]}"
		msg="Host '#G$subject#g' "
		((!op)) && msg+='added.' || msg+='removed.'
		write "${newline%$'\n'}" "$DNS_PATH" && addmsg "$msg"
	fi
    return 0
}

# enable site
_site_ena() {
	checksite || return 1
	declare name="$URLNAME$CFG_EXT"
    [[ -f $HTTP_AVAILABLE/$name && ! -L $HTTP_ENABLED/$name ]] &&
		sudo ln -s "$HTTP_AVAILABLE/$name" "$HTTP_ENABLED" &&
		addmsg "#gSite '#G$URLNAME#g' enabled."
}

# disable site
_site_dis() {
	checksite || return 1
	declare name="$URLNAME$CFG_EXT"
    [[ -L $HTTP_ENABLED/$name ]] && sudo rm "$HTTP_ENABLED/$name" &&
		addmsg "#gSite '#G$URLNAME#g' disabled."
}

# add site
_site_add() {
	checksite || return 1
    declare docroot="$(readlink -m "$DEV_PATH/$NAME/$ROOT")"
    declare poolpath="$PHP_PATH/$PHPV/fpm/pool.d"
    declare sitepath="$HTTP_AVAILABLE/$URLNAME$CFG_EXT"
    declare indexpath sitedef pooldef

    [[ -z $NAME ]] && addmsg "Site name not given." $MST_ERROR
    [[ -f $sitepath ]] && addmsg "Site '#R$URLNAME#r' HTTP definition already exists." $MST_ERROR
    [[ ! -d $poolpath ]] && addmsg "PHP version '#R$PHPV#r' isn't installed or is awkward." $MST_ERROR
    [[ -f $poolpath/$NAME$CFG_EXT ]] && addmsg "Pool '#R$NAME#r' FPM definition for #RPHP$PHPV #ralready exists." $MST_ERROR
    ((ECN > 0)) && return 1

    # project development path
    if [[ -d $DEV_PATH/$NAME ]]; then
        indexpath=$(find "$DEV_PATH/$NAME" -name 'index.php')
        [[ -n $indexpath && $FORCE -ne 1 ]] && docroot="$(dirname $indexpath)"
    else
        mkdir "$DEV_PATH/$NAME" && addmsg "Site '#G$NAME#g' project path added."
    fi

    # document root
    [[ ! -d $docroot ]] && mkdir -p "$docroot" &&
		addmsg "Site '#G$NAME#g' document root path '#G$docroot#g' created."
    # index.php file
    [[ -z $indexpath || $FORCE -eq 1 ]] &&
        write "$(index_tpl)" "$docroot/index.php" &&
        addmsg "Site '#G$NAME#g' testing #Gindex.php #gfile added."
    # add site HTTP definition
    sitedef="$(site_tpl "$URLNAME" "$docroot" "$LOG_PATH")"
    write "$sitedef" "$sitepath" && addmsg "Site '#G$URLNAME#g' HTTP definition added."
	# add site FPM pool
    pooldef="$(pool_tpl "$URLNAME" "$SITE_USER" "$SITE_GROUP" "$LISTEN_OWNER" "$LISTEN_GROUP")"
    write "$pooldef" "$poolpath/$NAME$CFG_EXT" &&
        addmsg "Pool '#G$NAME#g' FPM definition for #GPHP$PHPV #gadded."
	# add DNS record
	host
	# enable
	_site_ena
}

# remove HTTP & FPM defs & DNS record
_server_rm() {
	declare poolpath="$PHP_PATH/$PHPV/fpm/pool.d/$NAME$CFG_EXT"
    declare sitepath="$HTTP_AVAILABLE/$URLNAME$CFG_EXT"

	# disable
	_site_dis
	# DNS record remove
	host 1
    # fpm definition remove
    [[ -f $poolpath ]] && sudo rm "$poolpath" && addmsg "Pool '#G$NAME#g' FPM definition for #GPHP$PHPV #gremoved."
    # http definition remove
    [[ -f $sitepath ]] && sudo rm "$sitepath" && addmsg "Site '#G$URLNAME#g' HTTP definition removed."
}

# remove site sources
_site_rm() {
	checksite || return 1
    declare devpath="$DEV_PATH/$NAME"

	# trying to remove extended site sources
	[[ ! -d $devpath ]] && addmsg "Site '#R$NAME#r' is not a base site." $MST_ERROR && return 1
	# remove server definitions
	if ((FORCE)); then
		for PHPV in "${PHP_LIST[@]}"; do
			[[ $PHPV == $(phpver) ]] && URLNAME=$NAME || URLNAME="$NAME$(phpversim $PHPV)"
			_server_rm
		done
		# sources remove
		rm -r "$devpath" && addmsg "Site '#G$NAME#g' development path removed."
	else
		_server_rm
	fi
}

# remove all projects
_site_rm_all() {
	declare -a sites
	declare -i count

	getdir sites "$DEV_PATH" d
	count=${#sites[@]}
	((!count)) && return 0
	if ((FORCE)); then
		for NAME in "${sites[@]}"; do
			_site_rm
		done
	else
		addmsg "#R$count #rproject(s) remaining !" $MST_ERROR
		return 1
	fi
}

# list sites
_site_list() {
	checksite || return 1
	declare cur="$PWD" site
	declare -i i
	clrlst
	cd "$HTTP_AVAILABLE"
	LST=($(ls *$CFG_EXT | sed "s/$CFG_EXT$//"))
	echo "${LST[@]}"
	LCN=${#LST[@]}
	cd "$cur"
	for site in "${LST[@]}"; do
		[[ -L $HTTP_ENABLED/$site$CFG_EXT ]] && LSS+=(1) || LSS+=(0)
	done
	lstout "Site list"
}

######### Environment #################
# prepare environment
_envi_setup() {
	checksite 1 && addmsg "The #RSITE #ris already installed." $MST_ERROR && return 1
    sudo mkdir "$HTTP_EXT_PATH" &&
        write "$(common_tpl)" "$HTTP_EXT_PATH/common.conf" &&
        write "$(nette_tpl)" "$HTTP_EXT_PATH/nette.conf" &&
        write "$(php_tpl)" "$HTTP_EXT_PATH/php.conf" &&
        addmsg "#GNginX extended settings #gadded."
    mkdir "$DEV_PATH" && addmsg "The #Gdevelopment path #gcreated."
	addmsg "#GSITE #ginstalled."
	banner_tpl
}

# cancel environment
_envi_unset() {
	checksite || return 1
	# remove remaining projects if forced
	if _site_rm_all; then
		[[ -d $DEV_PATH ]] && rm -r "$DEV_PATH" && addmsg "#gThe #Gdevelopment path #gremoved."
	    [[ -d $HTTP_PATH/common ]] && sudo rm -r "$HTTP_PATH/common" &&
	        addmsg "#GNginX extended settings #gremoved."
		addmsg "#GSITE #guninstalled."
		banner_tpl
	fi
}

# site management
# $1 - command
# $2-X - arguments
site() {
    declare title
	declare -a posarg
	declare -i nposarg

	FORCE=0 ; NAME= ; PHPV=$(phpver) ; ROOT="$DOC_ROOT"
    while (($# > 0)); do
        case $1 in
            -f | --force)			FORCE=1 ;;
            -n | --name)	shift ; NAME=$1 ;;
            -p | --php)		shift ; PHPV=$1 ;;
            -r | --root)	shift ; ROOT=$1 ;;
			*)				posarg+=($1) ;;
        esac
		shift
    done

	nposarg=${#posarg[@]}
	# command word 1. positional
	((nposarg)) && CMD=${posarg[0]}
	# site name can be 2. positional
	[[ $nposarg -gt 1 && -z $NAME ]] && NAME=${posarg[1]}
    # not system default php version - extended site
    [[ $PHPV != $(phpver) ]] && URLNAME="$NAME$(phpversim $PHPV)" || URLNAME=$NAME

	clrmsg
    case $CMD in
        a | add)	title="Adding site #Y$URLNAME" ; _site_add ;;
        r | rm)		title="Removing site #Y$URLNAME" ; _site_rm ;;
        e | ena)	title="Enabling site #Y$URLNAME" ; _site_ena ;;
        d | dis)	title="Disabling site #Y$URLNAME" ; _site_dis ;;
		setup)		title="SITE setup" ; _envi_setup ;;
		unset)		title="SITE clear away" ; _envi_unset ;;
        l | list)	_site_list ; return 0 ;;
        *)			site_help ; return 0 ;;
    esac
    msgout "$title"
}

######### Services ####################
svc_help() {
	echo -e "$(parsecolor "	#gSERVICES
	#w----------------------------------------------------------------------------------------------
	#ysvc #Y[cmd] #y[srv]..[srv]\n
	#Y-\t\t\t#wList services
	#Yp\t#ystop\t\t#wStop all services / certain service(s)
	#Yr\t#yrestart\t\t#wRestart all services / certain service(s)
	#Ys\t#ystart\t\t#wStart all services / certain service(s)
	#Yv\t#yswitch\t\t#wSwitch default PHP to version x.y
	#w----------------------------------------------------------------------------------------------")"
}

# Load status
_svc_load() {
    declare selection line name
    declare -a table

    selection=$(sudo systemctl list-units --type service --all | grep -E 'mariadb|nginx|fpm')
    mapfile -t table <<<"$selection"
    SVC=() ; SVS=()
    for line in "${table[@]}"; do
        name="${line%%.service*}"
        SVC+=("${name:2}")
        [[ $line =~ 'running' ]] && SVS+=(1) || SVS+=(0)
    done
}

# service controller
# $1 - command
# $2-X - service(s)
svc() {
    declare cmd=${1:-l} service name
    declare -a sel=("${@:2}") svcact

    case $cmd in
        v) phpsw "${sel[0]}" ; return 0 ;;
        p) cmd=stop ;;
        r) cmd=restart ;;
        s) cmd=start ;;
		h) svc_help ; return 0 ;;
		-) pline "#wMeant #rnothing#w, not a #rdash#w..." ; return 0 ;;
        *) cmd=list ;;
    esac
    _svc_load
    if [[ $cmd != list ]]; then
        if ((${#sel[@]})); then
            svcact=()
            for name in "${sel[@]}"; do
                searcharray $name SVC ra svcact
            done
        else
            svcact=("${SVC[@]}")
        fi
        SVO=()
        for service in "${svcact[@]}"; do
            SVO+=("$cmd $service")
            sudo systemctl $cmd $service
        done
        _svc_load
    fi
    svcout
}

######### Composer ####################
cps_help() {
	echo -e "$(parsecolor "	#gCOMPOSER SHORTCUTS
	#w----------------------------------------------------------------------------------------------
	#ycps #Y<cmd> #y[vendor/package]\n
	#gUpdate\n
	#Yu\t#yupdate [v/p] | [v/*]\t\t#wUpdate all packages / Update package / Update vendor
	#Yud\t#yupdate --with-dependencies\t#wUpdate all packages with dependencies
	#Yul\t#yupdate --lock\t\t\t#wUpdate #Wcomposer.lock
	#Ysu\t#yself-update\t\t\t#wUpdate composer\n
	#gAdd\n
	#Ya\t#yrequire <v/p>\t\t\t#wAdd package
	#Yad\t#yrequire <v/p> --dev\t\t#wAdd package to #Wrequire-dev #wsection\n
	#gRemove\n
	#Yr\t#yremove <v/p>\t\t\t#wRemove package\n
	#gInstall dependencies\n
	#Yi\t#yinstall\t\t\t\t#wInstall all dependencies
	#Yid\t#yinstall --dry-run\t\t#wSimulate installing dependencies\n
	#gSpecial\n
	#Ycp\t#ycreate-project <v/p>\t\t#wCreate project
	#w----------------------------------------------------------------------------------------------")"
}

# composer shortcuts
# $1 - command
# $2 - package
cps() {
	declare cmdline='composer ' cmd=${1:-h} pkg=$2

	case $cmd in
		u)	cmdline+="update $pkg" ;;
		ud)	cmdline+="update --with-dependencies" ;;
		ul)	cmdline+="update --lock" ;;
		su)	cmdline="sudo composer self-update" ;;
		i)	cmdline+="install" ;;
		id)	cmdline+="install --dry-run" ;;
		a)	cmdline+="require" ;;
		ad)	cmdline+="require --dev" ;;
		r)	cmdline+="remove" ;;
		cp)	cmdline+="create-project" ;;
		-)	pline "#wMeant #rnothing#w, not a #rdash#w..." ; return 0 ;;
		*)	cps_help ; return 0 ;;
	esac

	read -e -p "$(echo -e -n "$(parsecolor "#yComposer")"): " -i "$cmdline" cmdline

	eval "$cmdline"
}
