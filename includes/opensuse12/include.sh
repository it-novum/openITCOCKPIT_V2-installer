#########################
#
#   include variable
#
#########################

www_user="wwwrun"
www_group="www"
htpasswd_bin="/usr/bin/htpasswd2"


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
	cp -aHL $basicpath/${subpath}/itcpackage/opt/openitc/nagios/share/main/login/favicon.ico /srv/www/htdocs/
	cp -aHL $basicpath/${subpath}/itcpackage/* /
  chown $www_user:$www_group /srv/www/htdocs/* -R
	find /srv/www/htdocs -type d -print0 |/usr/bin/xargs -0 /bin/chmod 775
	chmod 775 /usr/bin/itc-rights
	ln -s /etc/init.d/rrdcached.init /etc/init.d/rrdcached
	chmod 775 /etc/init.d/rrdcached.init
	SuSEconfig --module permissions
}

paketinstall () {
	echo -e "\033[44;37m"
	clear
	echo -e "\033[44m\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\c"
	echo -e "     \033[47;1;37m┌────────────────────────────────────────────────────────┐\033[44m"
	echo -e "     \033[47;1;37m│\033[22;30m                                                        │\033[44m"
	echo -e "     \033[47;1;37m│\033[22;30m Start YAST this may take a while                       │\033[44m"
	echo -e "     \033[47;1;37m│\033[22;30m                                                        │\033[44m"
	echo -e "     \033[47;1;37m└\033[22;30m────────────────────────────────────────────────────────┘\033[44m"
	echo -e "\n\c"
  yast -i apache2 apache2-mod_perl apache2-mod_php5 automake bison cairo dialog dejavu dos2unix flex fltk fping freetype gcc gcc-c++ gd gd-devel giflib glibc gmp-devel gnuplot gnutls gnutls-devel gtk2 joe libmcrypt libmcrypt-devel libmysqlclient-devel libpcap libpng-devel mailx make mc mysql-community-server libmysqlclient18 libmysqld-devel net-snmp net-snmp-devel nmap openldap2-client openldap2-devel openssl-devel perl-Algorithm-Diff perl-DBD-mysql perl-Net-DNS perl-Net-Daemon perl-Net-IP perl-Net-SNMP perl-Net-Server perl-Net-Telnet perl-SNMP perl-XML-LibXML perl-XML-RegExp php5 php5-devel php5-dom php5-gd php5-gettext php5-iconv php5-ldap php5-mbstring php5-mcrypt php5-mysql php5-pear php5-snmp php5-sockets php5-xsl php5-xmlreader php5-xmlrpc php5-zlib rrdtool sysstat xorg-x11-fonts zlib
	if [ $? != 0 ]; then
		unimsg "ERR: A problem was detected by the execution of yast -i"
	fi
	echo -e "\033[0m"
}

sys_user_add () {
	/usr/sbin/groupadd nagios
	/usr/sbin/useradd -m -g $www_group -G nagios nagios -p `perl -e 'print crypt("$ITCPASS","Gfwtr"),"\n"'`
	/usr/sbin/useradd -m -g $www_group -G nagios itcockpit -p `perl -e 'print crypt("$ITCPASS","Gfwtr"),"\n"'`
}




