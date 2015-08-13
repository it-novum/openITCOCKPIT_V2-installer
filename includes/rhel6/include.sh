#########################
#
#   include variable
#
#########################

www_user="apache"
www_group="apache"
htpasswd_bin="/usr/bin/htpasswd"
MYSQLINIT=/etc/init.d/mysqld
HTTPDINIT=/etc/init.d/httpd
PHP=/usr/bin/php

#########################
#
#   include functions
#
#########################

pre_pear () {
  echo ""
}

itc_copy () {
	 # for now I'll disable SE Linux
        # Otherwise new context is required for:
        #  /opt/openitc/nagios/*
        #  /opt/openitc/nagios/share/3rd/nagvis/share
        #  /opt/openitc/nagios/share/pnp
	# TODO: richtige semange contexte erzeugen
        #  use: semanage fcontext 
        setenforce 0
        sed -i -e 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config

	## iptables is blocking port 80/443
	# when enabling SE Linux proper iptables setting required
	# for now I disable iptables generally
   	service iptables stop
	chkconfig iptables off

	# Make Compatibility Link for php5 & sed
	# Nicht hübsch aber effektiv
	( cd /usr/bin; ln -sf php php5; ln -s /bin/sed . )
	
        chown root:root $basicpath/${subpath}/itcpackage/* -R
        chmod 664 $basicpath/${subpath}/itcpackage/* -R
        find $basicpath/${subpath}/itcpackage -type d -print0 |/usr/bin/xargs -0 /bin/chmod 775

	# HTTPD CONFIG
        cp -aHL $basicpath/${subpath}/itcpackage/etc/apache2/conf.d/itc.conf /etc/httpd/conf.d/itc.conf
        cp -aHL $basicpath/${subpath}/itcpackage/etc/apache2/conf.d/nagvis.conf /etc/httpd/conf.d/nagvis.conf 
        cp -aHL $basicpath/${subpath}/itcpackage/etc/apache2/conf.d/pnp4nagios.conf /etc/httpd/conf.d/pnp4nagios.conf
	restorecon -vvR /etc/httpd/conf.d
	
	# INIT Scripte
	[ -f /etc/init.d/rrdcached ] && mv /etc/init.d/rrdcached /etc/init.d/rrdcached.old
        find $basicpath/${subpath}/openitc_install/source/orig-init-skripts -type f -exec sed -i 's/www/apache/' \{\} \;
        chmod 775 $basicpath/${subpath}/openitc_install/source/orig-init-skripts/*
        cp -aHL $basicpath/${subpath}/openitc_install/source/orig-init-skripts/* /etc/init.d/
        ln -s /etc/init.d/rrdcached.init /etc/init.d/rrdcached

	restorecon -vvR /etc/init.d

	# Rest
        cp -aHL $basicpath/${subpath}/itcpackage/opt/openitc/nagios/share/main/login/favicon.ico /var/www/html/
        cp -aHL $basicpath/${subpath}/itcpackage/opt /
	cp -aHL $basicpath/${subpath}/itcpackage/var/spool/cron/tabs/* /var/spool/cron/
	mv /var/spool/cron/wwwrun /var/spool/cron/${www_user}
	restorecon -vvR /var/spool/cron

        cp -aHL $basicpath/${subpath}/itcpackage/srv/www/htdocs/* /var/www/html/
	chown $www_user:$www_group /var/www/html/* -R
        find /var/www/html -type d -print0 |/usr/bin/xargs -0 /bin/chmod 775
        cp -aHL $basicpath/includes/$systype/itc-rights /usr/bin/
	#TODO: semange fcontext (für executables setzen)
	restorecon -vvR /var/www/html

        chmod 775 /usr/bin/itc-rights
}


paketinstall () {
set -x
	# required repositories in RHEL6/Centos6
	# base, optional
	# Comment: IBM Java 1.4 is in 
	echo -e "\033[44;37m"
	clear
	echo -e "\033[44m\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\c"
	echo -e "     \033[47;1;37m┌────────────────────────────────────────────────────────┐\033[44m"
	echo -e "     \033[47;1;37m│\033[22;30m                                                        │\033[44m"
	echo -e "     \033[47;1;37m│\033[22;30m Start yum. This may take a while                       │\033[44m"
	echo -e "     \033[47;1;37m│\033[22;30m                                                        │\033[44m"
	echo -e "     \033[47;1;37m└\033[22;30m────────────────────────────────────────────────────────┘\033[44m"
	echo -e "\n\c"
	yum -y install httpd mod_perl mod_auth_kerb mod_auth_mysql mod_authz_ldap mod_nss mod_perl mod_revocator mod_ssl mod_wsgi automake bison cairo cairo-devel dialog flex freetype \
                gcc gcc-c++ gd giflib glibc gmp-devel gnuplot gnutls gnutls-devel gtk2 gtk2-devel java-1.5.0-gcj kernel-devel kernel-headers libgcrypt libgcrypt-devel libpcap \
                libpng-devel mc mysql mysql-server mysql-devel rsyslog-mysql net-snmp net-snmp-devel nmap openldap-clients openldap-devel openssl-devel \
		net-snmp-perl perl-Archive-Tar perl-Class-MethodMaker perl-Compress-Zlib perl-CPAN perl-DBD-MySQL perl-Digest-SHA1 perl-ExtUtils-CBuilder perl-ExtUtils-MakeMaker \
		perl-ExtUtils-ParseXS perl-HTML-Parser perl-IO-Compress-Base perl-Module-Build perl-Module-CoreList perl-Module-Load-Conditional perl-Module-Loaded perl-Module-Load \
		perl-Module-Pluggable perl-Mozilla-LDAP perl-Net-DNS perl-Net-LibIDN perl-Net-SSLeay perl-Object-Accessor perl-Params-Validate perl-Pod-Escapes \
		perl-Readonly-XS perl-Socket6 perl-TermReadKey perl-Unicode-String perl-XML-Parser sysstat zlib \
		php php-bcmath php-cli php-common php-dba php-gd php-imap  php-ldap php-ldap php-mbstring php-mysql php-odbc php-pdo php-pecl-apc \
		php-pecl-memcache php-pgsql php-process php-pspell php-recode php-snmp php-soap php-tidy php-xml php-xmlrpc atk-devel apr apr-devl apr-util dialog \
		libxml2 python-lxml xml-commons-apis xml-commons-resolver policycoreutils-python \
 		net-snmp net-snmp-devel net-snmp-perl net-snmp-utils php-snmp rrdtool rrdtool-php rrdtool-perl rrdtool-devel dejavu-sans-fonts dejavu-serif-fonts
	if [ $? != 0 ]; then
		unimsg "ERR: A problem was detected by the execution of yum install. Check if base and optional repository is enabled"
	fi
	echo -e "\033[0m"
}

sys_user_add () {
	/usr/sbin/groupadd nagios
	/usr/sbin/useradd -m -g $www_group -G nagios nagios -p `perl -e 'print crypt("$ITCPASS","Gfwtr"),"\n"'`
	/usr/sbin/useradd -m -g $www_group -G nagios itcockpit -p `perl -e 'print crypt("$ITCPASS","Gfwtr"),"\n"'`
}




