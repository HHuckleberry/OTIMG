#!/bin/bash
#ensure prereqs are installed
apt-get update
apt-get install -y autoconf gcc libc6 make wget unzip apache2 apache2-utils php libgd-dev
apt-get install openssl libssl-dev

#nagioscore install direction https://support.nagios.com/kb/article/nagios-core-installing-nagios-core-from-source-96.html#Debian
#script slightly modified
cd /tmp
wget -O nagioscore.tar.gz https://github.com/NagiosEnterprises/nagioscore/archive/nagios-4.4.6.tar.gz
tar xzf nagioscore.tar.gz

cd /tmp/nagioscore-nagios-4.4.6/
./configure --with-httpd-conf=/etc/apache2/sites-enabled
make all
#create user and group
make install-groups-users
usermod -a -G nagios www-data
#binary
make install

make install-daemoninit

make install-commandmode

make install-config

make install-webconf
a2enmod rewrite
a2enmod cgi



iptables -I INPUT -p tcp --destination-port 80 -j ACCEPT
apt-get install -y iptables-persistent

htpasswd -c /usr/local/nagios/etc/htpasswd.users nagiosadmin

#nagois Plusins 
apt-get install -y autoconf gcc libc6 libmcrypt-dev make libssl-dev wget bc gawk dc build-essential snmp libnet-snmp-perl gettext

cd /tmp
wget --no-check-certificate -O nagios-plugins.tar.gz https://github.com/nagios-plugins/nagios-plugins/archive/release-2.3.3.tar.gz
tar zxf nagios-plugins.tar.gz

cd /tmp/nagios-plugins-release-2.3.3/
./tools/setup
./configure
make
make install