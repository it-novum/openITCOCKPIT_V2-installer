#########################
#
#   include variable
#
#########################

www_user="www-data"
www_group="www-data"
htpasswd_bin="/usr/bin/htpasswd"


#########################
#
#   include functions
#
#########################

pre_pear () {
  cat /etc/php5/conf.d/sqlite.ini|sed 's/^extension=sqlite.so/;extension=sqlite.so/g' > /etc/php5/conf.d/sqlite.ini
}

itc_copy () {
	chown root:root $basicpath/${subpath}/itcpackage/* -R
	chmod 664 $basicpath/${subpath}/itcpackage/* -R
	find $basicpath/${subpath}/itcpackage -type d -print0 |/usr/bin/xargs -0 /bin/chmod 775
        cp -aHL $basicpath/${subpath}/itcpackage/etc/profile.d/openITCOCKPIT.sh /etc/profile.d/openITCOCKPIT.sh
	cp -aHL $basicpath/${subpath}/itcpackage/etc/apache2/conf.d/itc.conf /etc/apache2/sites-available/itc.conf
	cp -aHL $basicpath/${subpath}/itcpackage/etc/apache2/conf.d/nagvis.conf /etc/apache2/sites-available/nagvis.conf
	cp -aHL $basicpath/${subpath}/itcpackage/etc/apache2/conf.d/pnp4nagios.conf /etc/apache2/sites-available/pnp4nagios.conf
	a2ensite itc
	a2ensite nagvis
	a2ensite pnp4nagios
	find $basicpath/${subpath}/openitc_install/source/orig-init-skripts -type f -exec sed -i 's/www/www-data/' \{\} \;
	chmod 775 $basicpath/${subpath}/openitc_install/source/orig-init-skripts/*
	cp -aHL $basicpath/${subpath}/openitc_install/source/orig-init-skripts/* /etc/init.d/
	ln -s /etc/init.d/rrdcached.init /etc/init.d/rrdcached
	cp -aHL $basicpath/${subpath}/itcpackage/opt/openitc/nagios/share/main/login/favicon.ico /var/www/
	cp -aHL $basicpath/${subpath}/itcpackage/opt /
  cp -aHL $basicpath/${subpath}/itcpackage/var/spool/cron/tabs/* /var/spool/cron/crontabs
  mv /var/spool/cron/crontabs/wwwrun /var/spool/cron/crontabs/www-data
	cp -aHL $basicpath/${subpath}/itcpackage/srv/www/htdocs/* /var/www/html/
  chown $www_user:$www_group /var/www/* -R
	find /var/www -type d -print0 |/usr/bin/xargs -0 /bin/chmod 775
	cp -aHL $basicpath/includes/$systype/itc-rights* /usr/bin/
	chmod 775 /usr/bin/itc-rights*
}

paketinstall () {
	echo -e "\033[44;37m"
	clear
	apt-get update
	if [ $? != 0 ]; then
		unimsg "ERR: A problem was detected by the execution of apt-get" 
	fi
	apt-get -y install apache2 automake bison build-essential dialog flex fping gnuplot gnutls-bin joe libalgorithm-diff-perl libapache2-mod-perl2 libapache2-mod-php5 libapache2-mod-python libcairo2 libcairo2-dev libdbd-mysql-perl libfltk1.1 libfreeradius2 libfreetype6 libgd2-xpm-dev libgif4 libgnutls26 libldap-2.4-2 libldap2-dev libmcrypt4 libmcrypt-dev libmysqlclient15-dev libnet-daemon-perl libnet-dns-perl libnet-ip-perl libnet-server-perl libnet-snmp-perl libnet-telnet-perl libpango1.0-dev libpcap0.8 libpcap0.8-dev libpng12-0 libpng12-dev libsnmp30 libsnmp-dev libsnmp-perl libssl0.9.8 libssl-dev libxml2-dev libxml-libxml-perl libxml-regexp-perl mc mc mrtg mysql-server nmap php5 php5-cgi php5-cli php5-dev php5-dev php5-gd php5-ldap php5-mcrypt php5-mysql php5-snmp php5-sqlite php5-xmlrpc php5-xsl php-date php-gettext php-pear php-xml-parser php-xml-serializer snmp snmpd sudo sysstat vim zlib1g zlib1g-dev librrds-perl librrdp-perl librrd-simple-perl rrdtool
	if [ $? != 0 ]; then
		unimsg "ERR: A problem was detected by the execution of apt-get"
	fi
	echo -e "\033[0m"
}

sys_user_add () {
	addgroup nagios
	/usr/sbin/useradd -m -g $www_group -G nagios nagios -p `perl -e 'print crypt("$ITCPASS","Gfwtr"),"\n"'`
	/usr/sbin/useradd -m -g $www_group -G nagios itcockpit -p `perl -e 'print crypt("$ITCPASS","Gfwtr"),"\n"'`
}

