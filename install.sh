#!/bin/bash
#
# Copyright (C) 2011-2022 it-novum GmbH
#
# This program is free software; you can redistribute it and/or modify it 
# under the terms of the GNU General Public License version 2 as published 
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, 
# but WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
# See the GNU General Public License for more details.
#
# openITCOCKPIT-Installer
# This program will install openITCOCKPIT
# Written by Bjoern Richter 2011
#
#    CHANGELOG
#    2011-03-11 (bjoern.richter@it-novum.com)
#     - created (v0.1)
#    2012-03-02 (bjoern.richter@it-novum.com)
#     - created (v0.2)
#    2012-03-09 (bjoern.richter@it-novum.com)
#     - BugFixes(v0.2.1)
#    2013-02-28 (daniel@open-itcockpit.org)
#     - Changes for openITCOCKPIT V_2.7.18 (v0.3.5)
#    2014-05-06 (Christian.Michel@it-novum.com)
#     - Ubuntu14.04 LTS support (v0.3.6)
#    2015-04-15 (Christian.Michel@it-novum.com)
#     - Ubuntu14.04.2 LTS support (v0.3.7)

# toDo:
#	even more error-interception
#	RedHat Support


#########################
#
#      function
#
#########################

helpmsg() {
	clear
	echo "Copyright (C) 2011-2022 it-novum GmbH"
	echo ""
	echo "This program is free software; you can redistribute it and/or modify it"
	echo "under the terms of the GNU General Public License version 2 as published"
	echo "by the Free Software Foundation."
	echo ""
	echo "This program is distributed in the hope that it will be useful,"
	echo "but WITHOUT ANY WARRANTY; without even the implied warranty of"
	echo "MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE."
	echo "See the GNU General Public License for more details."
	echo ""
	echo "openITCOCKPIT-Installer $version"
	echo "This program will install openITCOCKPIT"
	echo "Written by Bjoern Richter 2011"
	echo ""
	usage
}

usage() {
	echo -e "Usage: $0 \t\t\tstarts the installer"
	echo -e "Usage: $0 -h|-?|--help\tshows this screen"
	exit 1
}

unimsg (){
        echo -e "\033[0m"
	clear
	echo -e "$1"
	exit 2
}

processmsg(){
  echo "########################################################"
  echo "########################################################"
  echo "##"
  echo -e "##  $1"
  echo "##"
  echo "########################################################"
  echo "########################################################"
}

rootdetect (){
  shell_user_id=`id -ru`
  if [ $shell_user_id != 0 ]; then
    echo "Please start this installer as root!"
    exit 2
  fi
}

systemdetection (){
	lsb_release -a 2>&1>/dev/null
	if [ $? != 0 ]; then
		yast --help 2>&1>/dev/null
		if [ $? == 0 ]; then
			yast -i lsb
		else
			apt-get --help 2>&1>/dev/null
			if [ $? == 0 ]; then
				apt-get -y install lsb
			fi
		fi
	fi
	systype=`lsb_release -d 2>/dev/null|cut -f2`
	sysbit=`uname -m`
	case "$sysbit" in
		'i686')
			sysbit="32"
		;;
		'x86_64')
			sysbit="64"
		;;
		*)
			unimsg "Could not detect if your server is a 32bit or 64bit system"
		;;
	esac
        
}

get_distri_assignment () {
  # create a new filedescriptor (22)
  if [ -e $basicpath/distribution.cfg ]; then
    exec 22<$basicpath/distribution.cfg
    let count=0
    while read -u 22 LINE; do
      if [ "`awk '/^[^#]|[\w\.[:blank:]\(\)]+\=[\w\.[:blank:]]+$/{print}'<<<$LINE`" != "" ]; then  # filter all unnecessary lines
        from_sysname[$count]=`awk -F'=' '{print $1}'<<<$LINE`
        to_sysname[$count]=`awk -F'=' '{print $2}'<<<$LINE`
        ((count++)) 
      fi
    done
    # close filedescriptor 22
    exec 22<&-
  else
    unimsg "Could not find $basicpath/distribution.cfg!"
    exit 2
  fi 
}

inettest (){
  wget www.it-novum.com 2>&1>/dev/null
	if [ $? != 0 ]; then
		dialog --backtitle "Internet-Connection-Test" \
		       --title "Internet-Connection-Test" \
		       --msgbox "\nThe Internet-Connection-Test has failed.\nwww.it-novum.com could not be reached.\n\nPlease enter your proxy connection data" 10 45
		proxyq
	fi    
  rm -f $basicpath/index* 
}

proxyq (){
	proxyhost="127.0.0.1"
	proxyport="8080"

	exec 3>&1
	PROXY_VALUES=$(dialog --ok-label "Submit" \
		  --cancel-label "Cancel" \
		  --backtitle "Proxy-Connection" \
		  --title "Proxy-Connection" \
		  --form "Connect to Proxy" 10 40 0 \
		"IP-Address:" 1 1	"$proxyhost" 	1 14 16 0 \
		"Port:" 2 1	"$proxyport"  	2 14 5 0 \
	2>&1 1>&3)
	if [ $? != 0 ]; then
		unimsg "You have aborted the installation of openITCOCKPIT."
	fi

	PROXY_VALUES=`echo $PROXY_VALUES| tr '\n' ';' |tr ' ' ';'`
	proxyhost=`echo $PROXY_VALUES|cut -d ';' -f1`
	proxyport=`echo $PROXY_VALUES|cut -d ';' -f2`
	exec 3>&-
  export http_proxy="http://${proxyhost}:${proxyport}"
  export https_proxy="http://${proxyhost}:${proxyport}"
  export ftp_proxy="http://${proxyhost}:${proxyport}"
 	inettest
}

dbconnect () {
	dbhost="127.0.0.1"
	dbport="3306"
	dbuser="root"

	dialog --backtitle "DB-Connection" \
	       --title "DB-Connection" \
	       --msgbox "\nThe oITC-Installer needs an adminitrative Account to connect to your MySQL-Database.\n" 9 45

	exec 3>&1

	DB_VALUES=$(dialog --ok-label "Submit" \
		  --cancel-label "Cancel" \
		  --backtitle "DB-Connection" \
		  --title "DB-Connection" \
		  --form "Connect to MySQL" 10 40 0 \
		"IP-Address:" 1 1	"$dbhost" 	1 14 16 0 \
		"Port:" 2 1	"$dbport"  	2 14 5 0 \
		"User:" 3 1	"$dbuser"  	3 14 20 0 \
	2>&1 1>&3)
	if [ $? != 0 ]; then
		unimsg "You have aborted the installation of openITCOCKPIT."
	fi

	DB_VALUES=`echo $DB_VALUES| tr '\n' ';' |tr ' ' ';'`
	dbhost=`echo $DB_VALUES|cut -d ';' -f1`
	dbport=`echo $DB_VALUES|cut -d ';' -f2`
	dbuser=`echo $DB_VALUES|cut -d ';' -f3`

	dbpass=$(dialog --ok-label "Submit" \
		  --cancel-label "Cancel" \
		  --backtitle "DB-Password" \
		  --title "DB-Password" \
		  --insecure \
		  --passwordbox "Password:" 10 40 \
	2>&1 1>&3)
	if [ $? != 0 ]; then
		unimsg "You have aborted the installation of openITCOCKPIT."
	fi
	exec 3>&-
}

itc_user_add () {
	itcuser="admin"
	itcpass=""
	 
	dialog --backtitle "openITCOCKPIT Installation" \
	       --title "oITC-ADD-User" \
	       --msgbox "\nIn the following forms you can enter\nyour initial oITC-User and its password." 8 45

	exec 3>&1
	itcuser=$(dialog --ok-label "Submit" \
		  --cancel-label "Cancel" \
		  --backtitle "openITCOCKPIT Installation" \
		  --title "oITC-User" \
		  --inputbox "Username" 10 40 $itcuser \
	2>&1 1>&3)
	if [ $? != 0 ]; then
		unimsg "You have aborted the installation of openITCOCKPIT."
	fi

	itcpass=$(dialog --ok-label "Submit" \
		  --cancel-label "Cancel" \
		  --backtitle "openITCOCKPIT Installation" \
		  --title "oITC-Password" \
		  --insecure \
		  --passwordbox "Password:" 10 40 \
	2>&1 1>&3)
	if [ $? != 0 ]; then
		unimsg "You have aborted the installation of openITCOCKPIT."
	fi

  re_itcpass=$(dialog --ok-label "Submit" \
		  --cancel-label "Cancel" \
		  --backtitle "openITCOCKPIT Installation" \
		  --title "retype oITC-Password" \
		  --insecure \
		  --passwordbox "Password:" 10 40 \
	2>&1 1>&3)
	if [ $? != 0 ]; then
		unimsg "You have aborted the installation of openITCOCKPIT."
	fi
	exec 3>&-

  if [ "${itcpass}" != "${re_itcpass}" ]; then
	  dialog --backtitle "openITCOCKPIT Installation" \
	         --title "oITC wrong Password" \
	         --msgbox "\nPassword does not match! Please try again." 7 46
    itc_user_add
  fi 

  if [ "${itcpass}" == "" ]; then
	  dialog --backtitle "openITCOCKPIT Installation" \
	         --title "oITC empty Password" \
	         --msgbox "\nEmpty passwords are not allowed! Please try again." 7 46
    itc_user_add
  fi 
}

welcomemsg () {
	echo -e "\033[44m"
	clear
	echo -e "\033[44m\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\c"
	echo -e "     \033[47;1;37m┌────────────────────────────────────────────────────────────────────┐\033[44m"
	echo -e "     \033[47;1;37m│\033[22;30m openITCOCKPIT Installer ($version)                                    │\033[44m"
	echo -e "     \033[47;1;37m│\033[22;30m                                                                    │\033[44m"
	echo -e "     \033[47;1;37m│\033[22;30m This script installs an openITCOCKPIT-Server in /opt/openitc.      │\033[44m"
	echo -e "     \033[47;1;37m│\033[22;30m In the first step all required packages will be installed          │\033[44m"
	echo -e "     \033[47;1;37m│\033[22;30m via your packagemanager.                                           │\033[44m"
	echo -e "     \033[47;1;37m│\033[22;30m Please be sure that your system has a working Internet connection  │\033[44m"
	echo -e "     \033[47;1;37m│\033[22;30m or access to corresponding local repositories !                    │\033[44m"
	echo -e "     \033[47;1;37m│\033[22;30m                                                                    │\033[44m"
	echo -e "     \033[47;1;37m│\033[22;30m Press any key to continue                                          │\033[44m"
	echo -e "     \033[47;1;37m└\033[22;30m────────────────────────────────────────────────────────────────────┘\033[44m"
	echo -e "\n\c"
	read -n1 INPUT
}

welcomewait () {
	echo -e "\033[44m"
	clear
	echo -e "\033[44m\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\c"
	echo -e "     \033[47;1;37m┌────────────────────────────────────────────────────────────────────┐\033[44m"
	echo -e "     \033[47;1;37m│\033[22;30m openITCOCKPIT Installer ($version)                                    │\033[44m"
	echo -e "     \033[47;1;37m│\033[22;30m                                                                    │\033[44m"
	echo -e "     \033[47;1;37m│\033[22;30m                                                                    │\033[44m"
	echo -e "     \033[47;1;37m│\033[22;30m      please wait .......                                           │\033[44m"
	echo -e "     \033[47;1;37m│\033[22;30m                                                                    │\033[44m"
	echo -e "     \033[47;1;37m│\033[22;30m                                                                    │\033[44m"
	echo -e "     \033[47;1;37m│\033[22;30m                                                                    │\033[44m"
	echo -e "     \033[47;1;37m│\033[22;30m                                                                    │\033[44m"
	echo -e "     \033[47;1;37m└\033[22;30m────────────────────────────────────────────────────────────────────┘\033[44m"
	echo -e "\n\c"
}

licence () {
	dialog --exit-label Accept \
	       --backtitle "License agreement" \
	       --title "License agreement" \
	       --textbox $basicpath/${subpath}/openitc_install/LICENSE_en.txt 40 70
}

itctargzq () {
	dialog --backtitle "openITCOCKPIT Installation" \
               --title "Online Installation" \
	       --msgbox "\nIn the next step you can choose between\n\nonline installation (default)\n(get the basic oITC package from Nezztek)\n\noffline installation\n(you need an oITC package on this System)." 13 45 
	dialog --yes-label online \
	       --no-label offline \
	       --backtitle "openITCOCKPIT Installation" \
	       --title "Online Installation" \
	       --yesno "Do you want to carry out an online install of openITCOCKPIT?" 6 45 
	itctargzq=$?
	if [ $itctargzq = 0 ]; then
     # Internet-Connection-Test
     inettest
     echo -e "\033[44m"
 		 clear
		 if [ -f $basicpath/openITCOCKPIT-Installer.tar.gz ]; then
		 	rm -f $basicpath/openITCOCKPIT-Installer.tar.gz
		 fi
     wget http://openitcockpit.org/fileadmin/user_upload/downloads/openITCOCKPIT_V2.7.15.tar.gz -P ${basicpath}
		itctargzfile="${basicpath}/openITCOCKPIT-Installer.tar.gz"
		echo -e "\033[0m"
	else
  		itctargzfile
	fi
}

itctargzfile () {
	dialog --backtitle "openITCOCKPIT Installation" \
               --title "Offline Installation" \
	       --msgbox "\nIn the next step you have to locate your oITC Package file.\n\nYou can move around with your arrowkeys and enter\return. To select a file, simply use space." 12 45 
	exec 3>&1
	itctargzfile=$(dialog --ok-label "Submit" \
		  --cancel-label "Cancel" \
		  --backtitle "openITCOCKPIT Installation" \
		  --title "openITCOCKPIT-Installer-tar.gz" \
		  --fselect ${basicpath}/openITCOCKPIT-Installer.tar.gz 10 40 \
	2>&1 1>&3)
	if [ $? != 0 ]; then
		unimsg "You have aborted the installation of openITCOCKPIT."
	fi
	exec 3>&-
}

beginn_install () {
	dialog --yes-label yes \
	       --no-label no \
	       --backtitle "openITCOCKPIT Installation" \
	       --title "Install start" \
	       --yesno "Do you want to install openITCOCKPIT now?" 6 45 
	installq=$?
	if [ $installq != 0 ]; then
		unimsg "You have aborted the installation of openITCOCKPIT."
	fi
}

info_beginn_install () {
	dialog --backtitle "openITCOCKPIT Installation" \
	       --title "Finish" \
	       --infobox "\noITC installation in progress.\nThis will take a moment.\n\nPlease wait..." 8 45
}

setdbpwq (){
  dialog --yes-label yes \
	       --no-label no \
	       --backtitle "openITCOCKPIT Installation" \
	       --title "Set DB password" \
	       --yesno "Your database root password is blank right now!\n\nDo you want to set it now?" 8 45 
	installq=$?
	if [ $installq == 0 ]; then
		setdbpw
	fi
}

setdbpw (){
	exec 3>&1
	dbpass=$(dialog --ok-label "Submit" \
		  --cancel-label "Cancel" \
		  --backtitle "DB-Password" \
		  --title "DB-Password" \
		  --insecure \
		  --passwordbox "Password:" 9 40 \
	2>&1 1>&3)
	exec 3>&-
  mysqladmin -u root password "$dbpass"
  if [ $? != 0 ];then
    processmsg "Something went wrong! Your DB-password is probably still blank!"
  fi
}

db_install () {
	if [ "$dbpass" != "" ];then
		mysql -h$dbhost -u$dbuser -p$dbpass < $basicpath/${subpath}/openitc_install/sql/mysql-myisam_inkl_createdb.sql
		mysql -h$dbhost -u$dbuser -p$dbpass < $basicpath/${subpath}/openitc_install/sql/quickstart_itcockpit_inkl_createdb.sql
		mysql -h$dbhost -u$dbuser -p$dbpass < $basicpath/${subpath}/openitc_install/sql/quickstart_nagios_archiv_inkl_createdb.sql
		mysql -h$dbhost -u$dbuser -p$dbpass -e 'CREATE USER nagios@localhost IDENTIFIED BY "'${oitcdbpwd}'" ; GRANT ALL PRIVILEGES ON nagios.* TO nagios@localhost WITH GRANT OPTION; GRANT ALL PRIVILEGES ON itcockpit.* TO nagios@localhost WITH GRANT OPTION; GRANT ALL PRIVILEGES ON nagios_archiv.* TO nagios@localhost WITH GRANT OPTION; CREATE USER smsbox@localhost IDENTIFIED BY "smsbox";'
		mysql -h$dbhost -u$dbuser -p$dbpass -e "UPDATE itcockpit.sys_user SET username = '$itcuser', pass = MD5( '$itcpass' ) WHERE sys_user.id_user =50;"
	else
		mysql -h$dbhost -u$dbuser < $basicpath/${subpath}/openitc_install/sql/mysql-myisam_inkl_createdb.sql
		mysql -h$dbhost -u$dbuser < $basicpath/${subpath}/openitc_install/sql/quickstart_itcockpit_inkl_createdb.sql
		mysql -h$dbhost -u$dbuser < $basicpath/${subpath}/openitc_install/sql/quickstart_nagios_archiv_inkl_createdb.sql
		mysql -h$dbhost -u$dbuser -e 'CREATE USER nagios@localhost IDENTIFIED BY "'${oitcdbpwd}'" ; GRANT ALL PRIVILEGES ON nagios.* TO nagios@localhost WITH GRANT OPTION; GRANT ALL PRIVILEGES ON itcockpit.* TO nagios@localhost WITH GRANT OPTION; GRANT ALL PRIVILEGES ON nagios_archiv.* TO nagios@localhost WITH GRANT OPTION; CREATE USER smsbox@localhost IDENTIFIED BY "smsbox";'
		mysql -h$dbhost -u$dbuser -e "UPDATE itcockpit.sys_user SET username = '$itcuser', pass = MD5( '$itcpass' ) WHERE sys_user.id_user =50;"
	fi
}

compile_nagios () {
	RES=0
	ARES=0
	chmod 777 $basicpath/${subpath}/openitc_install/source/nagios/configure
	cd $basicpath/${subpath}/openitc_install/source/nagios/

	#  Nagios configure command

	echo -e "\n\n####################\n#\n# Configure-Nagios \n#\n####################\n\n"

	./configure --prefix=/opt/openitc/nagios --with-cgiurl=/openitc/cgi-bin --with-htmurl=/openitc/old --datadir=/opt/openitc/nagios/share/old --with-nagios-user=nagios --with-nagios-group=$www_group --with-command-user=$www_group --with-command-group=$www_group

	ARES=`echo $?`
	if [ $ARES -ge $RES ]; then
		RES=$ARES
	fi

	#  Nagios compile command

	echo -e "\n\n####################\n#\n# Make-Nagios \n#\n####################\n\n"
	make all
	ARES=`echo $?`
	if [ $ARES -ge $RES ]; then
		RES=$ARES
	fi

	#  Nagios install command

	echo -e "\n\n####################\n#\n# Install-Nagios \n#\n####################\n\n"
	make install
	ARES=`echo $?`
	if [ $ARES -ge $RES ]; then
		RES=$ARES
	fi

	echo -e "\n\n####################\n#\n# Nagios Installation ready\n#\n####################\n\n"
}


compile_nagios_plugins () {
	RES=0
	ARES=0
	chmod 777 $basicpath/${subpath}/openitc_install/source/nagios-plugins/configure
	cd $basicpath/${subpath}/openitc_install/source/nagios-plugins/

	#  Nagios-Plugins configure command
	echo -e "\n\n####################\n#\n# Configure-Nagios-Plugins \n#\n####################\n\n"
	./configure --prefix=/opt/openitc/nagios

	ARES=`echo $?`
	if [ $ARES -ge $RES ]; then
		RES=$ARES
	fi


	#  Nagios-Plugins  compile command

	echo -e "\n\n####################\n#\n# Make-Nagios-Plugins \n#\n####################\n\n"
	make all
	ARES=`echo $?`
	if [ $ARES -ge $RES ]; then
		RES=$ARES
	fi

	#  Nagios-Plugins  install command

	echo -e "\n\n####################\n#\n# Install-Nagios-Plugins \n#\n####################\n\n"
	make install
	ARES=`echo $?`
	if [ $ARES -ge $RES ]; then
		RES=$ARES
	fi

	echo -e "\n\n####################\n#\n# Nagios-Plugins Installation ready\n#\n####################\n\n"
}

compile_ndo () {
	RES=0
	ARES=0
	chmod 777 $basicpath/${subpath}/openitc_install/source/ndoutils/configure
	cd $basicpath/${subpath}/openitc_install/source/ndoutils/


	#  NDO configure command
	echo -e "\n\n####################\n#\n# Configure-NDO \n#\n####################\n\n"
	./configure

	ARES=`echo $?`
	if [ $ARES -ge $RES ]; then
		RES=$ARES
	fi

	#  NDO compile command

	echo -e "\n\n####################\n#\n# Make-NDO \n#\n####################\n\n"
	make
	ARES=`echo $?`
	if [ $ARES -ge $RES ]; then
		RES=$ARES
	fi

	#  NDO install command

	echo -e "\n\n####################\n#\n# Copy-NDO \n#\n####################\n\n"
	cp src/ndomod-3x.o /opt/openitc/nagios/bin/ndomod.o
	ARES=`echo $?`
	if [ $ARES -ge $RES ]; then
	   RES=$ARES
	fi

	cp src/ndo2db-3x /opt/openitc/nagios/bin/ndo2db
	ARES=`echo $?`
	if [ $ARES -ge $RES ]; then
		RES=$ARES
	fi

	echo -e "\n\n####################\n#\n# NDO Installation ready\n#\n####################\n\n"
}

compile_rrdtool () {
	RES=0
	ARES=0
	chmod 777 $basicpath/${subpath}/openitc_install/source/rrdtool/configure
	cd $basicpath/${subpath}/openitc_install/source/rrdtool/


	#  RRDtool configure command
	echo -e "\n\n####################\n#\n# Configure-RRDtool \n#\n####################\n\n"


	if [ $sysbit == "64" ]; then
		echo -e "\n\n####################\n#\n#   64 bit version detected\n#\n####################\n\n"
		./configure --prefix=/usr --libdir=/usr/lib64 CFLAGS="-O3 -fPIC"
		ARES=`echo $?`
		if [ $ARES -ge $RES ]; then
		   RES=$ARES
		fi
	else
		echo -e "\n\n####################\n#\n#   32 bit version detected\n#\n####################\n\n"
		./configure --prefix=/usr
		ARES=`echo $?`
		if [ $ARES -ge $RES ]; then
		   RES=$ARES
		fi
	fi

	#  RRDtool compile command
	echo -e "\033[44m"
	echo -e "\n\n####################\n#\n# Make-RRDtool \n#\n####################\n\n"
	make
	ARES=`echo $?`
	if [ $ARES -ge $RES ]; then
		RES=$ARES
	fi

	#  RRDtool install command

	echo -e "\n\n####################\n#\n# Copy-RRDtool \n#\n####################\n\n"
	make install
	ARES=`echo $?`
	if [ $ARES -ge $RES ]; then
		RES=$ARES
	fi

	echo -e "\n\n####################\n#\n# RRDtool Installation ready\n#\n####################\n\n"
}

compile_pnp () {
	RES=0
	ARES=0
	chmod 777 $basicpath/${subpath}/openitc_install/source/pnp/configure
	cd $basicpath/${subpath}/openitc_install/source/pnp/


	#  PNP configure command
	echo -e "\n\n####################\n#\n# Configure-PNP \n#\n####################\n\n"
	./configure --prefix=/opt/openitc/nagios/3rd/pnp --with-nagios-group=$www_group --datarootdir=/opt/openitc/nagios/share/pnp --sysconfdir=/opt/openitc/nagios/etc/pnp --with-perfdata-dir=/opt/openitc/nagios/share/perfdata --bindir=/opt/openitc/nagios/bin --sbindir=/opt/openitc/nagios/bin --libexecdir=/opt/openitc/nagios/libexec --localstatedir=/opt/openitc/nagios/var

	ARES=`echo $?`
	if [ $ARES -ge $RES ]; then
		RES=$ARES
	fi

	#  PNP compile command

	echo -e "\n\n####################\n#\n# Make-PNP \n#\n####################\n\n"
	make all
	make install
	ARES=`echo $?`
	if [ $ARES -ge $RES ]; then
		RES=$ARES
	fi

	#  PNP install command

	echo -e "\n\n####################\n#\n# Copy-PNP \n#\n####################\n\n"
	cp src/npcd src/npcdmod.o /opt/openitc/nagios/bin/
	ARES=`echo $?`
	if [ $ARES -ge $RES ]; then
	   RES=$ARES
	fi

	cp scripts/*.pl /opt/openitc/nagios/libexec/
	rm /opt/openitc/nagios/share/pnp/install.php
	ARES=`echo $?`
	if [ $ARES -ge $RES ]; then
		RES=$ARES
	fi

	echo -e "\n\n####################\n#\n# PNP Installation ready\n#\n####################\n\n"

}

end_install () {
	dialog --backtitle "openITCOCKPIT Installation" \
               --title "Finish" \
	       --msgbox "\nITC is now installed on your system\n\nPlease connect with your Browser to the Server." 10 45 
}


#########################
#
#      variable
#
#########################

basicpath=`pwd`
version="0.3.7"
oitcdbpwd="open2itc"
declare -a to_sysname
declare -a from_sysname

#########################
#
#      options
#
#########################

while [ "$#" != 0 ]; do
    case "$1" in
	      --help)
		      helpmsg
		    ;;
	      -help)
		      helpmsg
		    ;;
	      --h)
		      helpmsg
		    ;;
	      -h)
		      helpmsg
		    ;;
	      -?)
		      helpmsg
		    ;;
        *)
          unimsg "Unknown Option: $1"
        ;;
    esac
    shift 1
done

#########################
#
#        main
#
#########################

rootdetect

welcomemsg

welcomewait

# detect the system you are using
systemdetection

get_distri_assignment

if [ ${#from_sysname[@]} -eq 0 ]; then
  unimsg "Could not find any assignment in distribution.cfg!"
fi
distri_ammount=`echo "${#from_sysname[@]}-1"|bc -l`

for((c=0;c<${#from_sysname[@]};c++)); do 
  if [ "$systype" == "${from_sysname[$c]}" ]; then
    systype=${to_sysname[$c]}
    c=${#from_sysname[@]}
  else
    if [ $c -eq $distri_ammount ];then
      unimsg "Could not find your distribution \"$systype\" in $basicpath/distribution.cfg! You may want to add it there."
      exit 2
    fi
  fi
done

source $basicpath/includes/$systype/include.sh

# install requiered packages
paketinstall

# locate nezztek installer
RES=1
while [ $RES != 0 ]; do
 itctargzq
 dialog --backtitle "openITCOCKPIT Installation" \
        --title "Extracting" \
	--infobox "\nExtracting the ITC-Package.\nThis will take a moment.\n\nPlease wait..." 8 45
 subpath=`tar -tzf $itctargzfile| awk '/itcpackage\/$/ {print}'| awk 'sub(/\/itcpackage\/$/,"") {print}'`
 tar -xzf $itctargzfile -C .
 if [ -f ${basicpath}/${subpath}/openitc_install/LICENSE_en.txt ]; then
   RES=0 
 fi
done

#Licence Agreement
licence

# DB Connection
/etc/init.d/mysql status 2>&1>/dev/null
if [ $? == 3 ]; then
	/etc/init.d/mysql start
fi
RES=1
while [ $RES != 0 ]; do
dbconnect
if [ "$dbpass" != "" ];then
  mysql -h$dbhost -u$dbuser -p$dbpass -e 'show databases;'
  RES=$?
else
  mysql -h$dbhost -u$dbuser -e 'show databases;'
  RES=$?
  if [ $RES == 0 ];then
    setdbpwq
  fi
fi
done

# add itc-user
itc_user_add

# Main Install
beginn_install
info_beginn_install

echo -e "\033[44m"

# pear install
pre_pear
${basicpath}/includes/exec/pear_install.sh "${basicpath}/${subpath}"

# DB install
db_install

# copy
clear
echo -e "\n\n####################\n#\n# ITC-Copy-Job \n#\n####################\n\n"
itc_copy

# sysuser ADD
echo -e "\n\n####################\n#\n# Add-System-User \n#\n####################\n\n"
sys_user_add

# compile
echo -e "\n\n####################\n#\n# Compiling-Nagios-NDO-Plugins \n#\n####################\n\n"
compile_nagios
compile_ndo
compile_nagios_plugins
compile_pnp

if [ $systype != "debian6" ];then
	echo -e "\n\n####################\n#\n# Compiling-RRD-Tools \n#\n####################\n\n"
	compile_rrdtool
fi

cd $basicpath/

# Configfile change www to $www_group
find /opt/openitc/nagios/etc -type f -exec sed -i "s/www/$www_group/" \{\} \;

# sudoers $www_group
echo -e "Cmnd_Alias NAG = /bin/bash *, /etc/init.d/nagios, /opt/openitc/nagios/bin/nagios, /bin/kill, /usr/bin/killall, /opt/openitc/nagios/bin/webrestart.sh, /usr/bin/nmap, /opt/openitc/nagios/3rd/check_mk/bin/check_mk, /usr/bin/itc-rights-perfdata\n$www_user ALL = (root) NOPASSWD: NAG" >> /etc/sudoers

#itc-rights
itc-rights

#prozess start
/etc/init.d/apache2 restart
/etc/init.d/ndo start
/etc/init.d/rrdcached start
/etc/init.d/npcd start

#itc-user-htpasswd
$htpasswd_bin -D /opt/openitc/.htpasswd itnc
$htpasswd_bin -b /opt/openitc/.htpasswd $itcuser $itcpass
pass_hash=`$htpasswd_bin -nb ${itcuser} ${itcpass}|cut -d ':' -f2`
echo "${itcuser}:${pass_hash}:initial Administrator:root@localhost:user,admin" >> /opt/openitc/nagios/share/3rd/wiki/conf/users.auth.php

#itc-user-NagVis-DB
php5 ${basicpath}/includes/exec/create_nagvis_user.php $itcuser

# reset terminal color
echo -e "\033[0m"

#final notice
end_install
	
clear
















