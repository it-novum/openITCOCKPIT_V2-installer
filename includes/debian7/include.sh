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
  echo ""
}

itc_copy () {
	chown root:root $basicpath/${subpath}/itcpackage/* -R
	chmod 664 $basicpath/${subpath}/itcpackage/* -R
	find $basicpath/${subpath}/itcpackage -type d -print0 |/usr/bin/xargs -0 /bin/chmod 775
	cp -aHL $basicpath/${subpath}/itcpackage/etc/apache2/conf.d/itc.conf /etc/apache2/sites-available/itc
	cp -aHL $basicpath/${subpath}/itcpackage/etc/apache2/conf.d/nagvis.conf /etc/apache2/sites-available/nagvis
	cp -aHL $basicpath/${subpath}/itcpackage/etc/apache2/conf.d/pnp4nagios.conf /etc/apache2/sites-available/pnp4nagios
	a2ensite itc
	a2ensite nagvis
	a2ensite pnp4nagios
  mv /etc/init.d/rrdcached /etc/init.d/rrdcached.old
	find $basicpath/${subpath}/openitc_install/source/orig-init-skripts -type f -exec sed -i 's/www/www-data/' \{\} \;
	chmod 775 $basicpath/${subpath}/openitc_install/source/orig-init-skripts/*
	cp -aHL $basicpath/${subpath}/openitc_install/source/orig-init-skripts/* /etc/init.d/
	ln -s /etc/init.d/rrdcached.init /etc/init.d/rrdcached
	cp -aHL $basicpath/${subpath}/itcpackage/opt/openitc/nagios/share/main/login/favicon.ico /var/www/
	cp -aHL $basicpath/${subpath}/itcpackage/opt /
  cp -aHL $basicpath/${subpath}/itcpackage/var/spool/cron/tabs/* /var/spool/cron/crontabs
  mv /var/spool/cron/crontabs/wwwrun /var/spool/cron/crontabs/www-data
	cp -aHL $basicpath/${subpath}/itcpackage/srv/www/htdocs/* /var/www
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
	apt-get -y install apache2 libapache2-mod-perl2 libapache2-mod-php5 libapache2-mod-python automake bison libcairo2 libcairo2-dev dialog flex libfltk1.1 fping  libfreeradius2 libfreetype6 build-essential libgd2-xpm libgd2-xpm-dev libpango1.0-dev libxml2-dev libgif4 gnuplot libgnutls26 gnutls-bin joe php5 php5-dev php5-cgi php5-cli php-date php5-gd php-gettext php5-ldap php5-mcrypt php5-mysql php-pear php5-snmp php5-sqlite php5-xsl php5-dev php-xml-parser php5-xmlrpc php-xml-serializer rrdtool rrdcached sudo sysstat zlib1g zlib1g-dev mc mrtg libpng12-0 libpng12-dev mysql-server libmysqlclient15-dev libpcap0.8 libpcap0.8-dev libmcrypt4 libmcrypt-dev nmap mc snmp snmpd libsnmp15 libsnmp-dev libldap-2.4-2 libldap2-dev libssl-dev  libssl1.0.0 libalgorithm-diff-perl libdbd-mysql-perl libnet-dns-perl libnet-daemon-perl libnet-ip-perl libnet-snmp-perl libnet-server-perl libnet-telnet-perl libsnmp-perl libxml-libxml-perl libxml-regexp-perl vim
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

