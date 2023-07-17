#!/bin/bash
#installation script built from instructions at https://greenbone.github.io/docs/latest/22.4/source-build/index.html#choosing-an-install-prefix
#create clean parameter to clean installation and try again

#check if already installed



#check if running as sudo
if [[ "$EUID" != 0 ]]
then
  # exit if not sudo or root
      echo "Run script with sudo"
      exit 1
fi


#create user
echo "Creating gvm user.."
sudo useradd -r -M -U -G sudo -s /usr/sbin/nologin gvm
sudo usermod -aG gvm $USER
#login to make group change effetive then exit root. 
su $USER -c 'exit'
#choose install prefix
echo "Setting up directories.."
export INSTALL_PREFIX=/usr/local
#set PATH
export PATH=$PATH:$INSTALL_PREFIX/sbin
#source dir
export SOURCE_DIR=$HOME/source
mkdir -p $SOURCE_DIR
#build dir
export BUILD_DIR=$HOME/build
mkdir -p $BUILD_DIR
#install dir
export INSTALL_DIR=$HOME/install
mkdir -p $INSTALL_DIR

sudo apt update 
sudo apt install --no-install-recommends --assume-yes \
  build-essential \
  curl \
  cmake \
  pkg-config \
  python3 \
  python3-pip \
  gnupg 


#import signing keys
curl -f -L https://www.greenbone.net/GBCommunitySigningKey.asc -o /tmp/GBCommunitySigningKey.asc
gpg --import /tmp/GBCommunitySigningKey.asc
#fully trust signing key - 
echo "8AE4BE429B60A59B311C2E739823FAA60ED1E580:6:" | gpg --import-ownertrust
echo
echo

#set version
export GVM_VERSION=22.4.1
# setting up GVM_LIBS
echo "Setting up GVM_LIBS.."
export GVM_LIBS_VERSION=22.6.3
sudo apt update
sudo apt install -y \
  libglib2.0-dev \
  libgpgme-dev \
  libgnutls28-dev \
  uuid-dev \
  libssh-gcrypt-dev \
  libhiredis-dev \
  libxml2-dev \
  libpcap-dev \
  libnet1-dev \
  libpaho-mqtt-dev \
  doxygen

sudo apt install -y \
  libldap2-dev \
  libradcli-dev
  

#downlaod gvm-libs sources
curl -f -L https://github.com/greenbone/gvm-libs/archive/refs/tags/v$GVM_LIBS_VERSION.tar.gz -o $SOURCE_DIR/gvm-libs-$GVM_LIBS_VERSION.tar.gz
curl -f -L https://github.com/greenbone/gvm-libs/releases/download/v$GVM_LIBS_VERSION/gvm-libs-$GVM_LIBS_VERSION.tar.gz.asc -o $SOURCE_DIR/gvm-libs-$GVM_LIBS_VERSION.tar.gz.asc
#check to ensure signature is valid
gpg --verify $SOURCE_DIR/gvm-libs-$GVM_LIBS_VERSION.tar.gz.asc $SOURCE_DIR/gvm-libs-$GVM_LIBS_VERSION.tar.gz
tar -C $SOURCE_DIR -xvzf $SOURCE_DIR/gvm-libs-$GVM_LIBS_VERSION.tar.gz

#build gvm-libs
echo "Building gvm-libs.."
mkdir -p $BUILD_DIR/gvm-libs && cd $BUILD_DIR/gvm-libs

sudo cmake $SOURCE_DIR/gvm-libs-$GVM_LIBS_VERSION \
  -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
  -DCMAKE_BUILD_TYPE=Release \
  -DSYSCONFDIR=/etc \
  -DLOCALSTATEDIR=/var

sudo make -j$(nproc)


#install gvm-libs
mkdir -p $INSTALL_DIR/gvm-libs

sudo make DESTDIR=$INSTALL_DIR/gvm-libs install

sudo cp -r $INSTALL_DIR/gvm-libs/* /


#export gvmd version
export GVMD_VERSION=22.5.1
#install depends for gvmd
sudo apt install -y \
  libglib2.0-dev \
  libgnutls28-dev \
  libpq-dev \
  postgresql-server-dev-13 \
  libical-dev \
  xsltproc \
  rsync \
  libbsd-dev \
  libgpgme-dev

# install optional depends 
sudo apt install -y --no-install-recommends \
  texlive-latex-extra \
  texlive-fonts-recommended \
  xmlstarlet \
  zip \
  rpm \
  fakeroot \
  dpkg \
  nsis \
  gnupg \
  gpgsm \
  wget \
  sshpass \
  openssh-client \
  socat \
  snmp \
  python3 \
  smbclient \
  python3-lxml \
  gnutls-bin \
  xml-twig-tools \
  libical-dev \
  libgpgme11 

curl -f -L https://github.com/greenbone/gvmd/archive/refs/tags/v$GVMD_VERSION.tar.gz -o $SOURCE_DIR/gvmd-$GVMD_VERSION.tar.gz
curl -f -L https://github.com/greenbone/gvmd/releases/download/v$GVMD_VERSION/gvmd-$GVMD_VERSION.tar.gz.asc -o $SOURCE_DIR/gvmd-$GVMD_VERSION.tar.gz.asc
gpg --verify $SOURCE_DIR/gvmd-$GVMD_VERSION.tar.gz.asc $SOURCE_DIR/gvmd-$GVMD_VERSION.tar.gz
tar -C $SOURCE_DIR -xvzf $SOURCE_DIR/gvmd-$GVMD_VERSION.tar.gz

#build gvmd
mkdir -p $BUILD_DIR/gvmd && cd $BUILD_DIR/gvmd

sudo cmake $SOURCE_DIR/gvmd-$GVMD_VERSION \
  -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
  -DCMAKE_BUILD_TYPE=Release \
  -DLOCALSTATEDIR=/var \
  -DSYSCONFDIR=/etc \
  -DGVM_DATA_DIR=/var \
  -DGVMD_RUN_DIR=/run/gvmd \
  -DOPENVAS_DEFAULT_SOCKET=/run/ospd/ospd-openvas.sock \
  -DGVM_FEED_LOCK_PATH=/var/lib/gvm/feed-update.lock \
  -DSYSTEMD_SERVICE_DIR=/lib/systemd/system \
  -DLOGROTATE_DIR=/etc/logrotate.d

sudo make -j$(nproc)

#install gvmd
mkdir -p $INSTALL_DIR/gvmd

sudo make DESTDIR=$INSTALL_DIR/gvmd install

sudo cp -r $INSTALL_DIR/gvmd/* /


#pg-gvm
export PG_GVM_VERSION=22.5.1

sudo apt install -y \
  libglib2.0-dev \
  postgresql-server-dev-13 \
  libical-dev



curl -f -L https://github.com/greenbone/pg-gvm/archive/refs/tags/v$PG_GVM_VERSION.tar.gz -o $SOURCE_DIR/pg-gvm-$PG_GVM_VERSION.tar.gz
curl -f -L https://github.com/greenbone/pg-gvm/releases/download/v$PG_GVM_VERSION/pg-gvm-$PG_GVM_VERSION.tar.gz.asc -o $SOURCE_DIR/pg-gvm-$PG_GVM_VERSION.tar.gz.asc
tar -C $SOURCE_DIR -xvzf $SOURCE_DIR/pg-gvm-$PG_GVM_VERSION.tar.gz
#build pg-gvm
mkdir -p $BUILD_DIR/pg-gvm && cd $BUILD_DIR/pg-gvm

sudo cmake $SOURCE_DIR/pg-gvm-$PG_GVM_VERSION \
  -DCMAKE_BUILD_TYPE=Release

sudo make -j$(nproc)
#installing pg-gvm
mkdir -p $INSTALL_DIR/pg-gvm

sudo make DESTDIR=$INSTALL_DIR/pg-gvm install

sudo cp -r $INSTALL_DIR/pg-gvm/* /



#greenbone security assistant
export GSA_VERSION=$GVM_VERSION
curl -f -L https://github.com/greenbone/gsa/releases/download/v$GSA_VERSION/gsa-dist-$GSA_VERSION.tar.gz -o $SOURCE_DIR/gsa-$GSA_VERSION.tar.gz
curl -f -L https://github.com/greenbone/gsa/releases/download/v$GSA_VERSION/gsa-dist-$GSA_VERSION.tar.gz.asc -o $SOURCE_DIR/gsa-$GSA_VERSION.tar.gz.asc

mkdir -p $SOURCE_DIR/gsa-$GSA_VERSION
tar -C $SOURCE_DIR/gsa-$GSA_VERSION -xvzf $SOURCE_DIR/gsa-$GSA_VERSION.tar.gz
#install gsa 
sudo mkdir -p $INSTALL_PREFIX/share/gvm/gsad/web/
sudo cp -r $SOURCE_DIR/gsa-$GSA_VERSION/* $INSTALL_PREFIX/share/gvm/gsad/web/


#gsad
export GSAD_VERSION=22.5.0
sudo apt install -y \
  libmicrohttpd-dev \
  libxml2-dev \
  libglib2.0-dev \
  libgnutls28-dev \
  xmltoman


curl -f -L https://github.com/greenbone/gsad/archive/refs/tags/v$GSAD_VERSION.tar.gz -o $SOURCE_DIR/gsad-$GSAD_VERSION.tar.gz
curl -f -L https://github.com/greenbone/gsad/releases/download/v$GSAD_VERSION/gsad-$GSAD_VERSION.tar.gz.asc -o $SOURCE_DIR/gsad-$GSAD_VERSION.tar.gz.asc

tar -C $SOURCE_DIR -xvzf $SOURCE_DIR/gsad-$GSAD_VERSION.tar.gz
#build gsad
mkdir -p $BUILD_DIR/gsad && cd $BUILD_DIR/gsad

sudo cmake $SOURCE_DIR/gsad-$GSAD_VERSION \
  -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
  -DCMAKE_BUILD_TYPE=Release \
  -DSYSCONFDIR=/etc \
  -DLOCALSTATEDIR=/var \
  -DGVMD_RUN_DIR=/run/gvmd \
  -DGSAD_RUN_DIR=/run/gsad \
  -DLOGROTATE_DIR=/etc/logrotate.d

sudo make -j$(nproc)

#install gsad
mkdir -p $INSTALL_DIR/gsad

sudo make DESTDIR=$INSTALL_DIR/gsad install

sudo cp -r $INSTALL_DIR/gsad/* /
#get error about not able to overwrite non-drecitory lib in /home/[user]/install/gsad/lib


#openvas-smb 
export OPENVAS_SMB_VERSION=22.5.3

sudo apt install -y \
  gcc-mingw-w64 \
  libgnutls28-dev \
  libglib2.0-dev \
  libpopt-dev \
  libunistring-dev \
  heimdal-dev \
  perl-base

curl -f -L https://github.com/greenbone/openvas-smb/archive/refs/tags/v$OPENVAS_SMB_VERSION.tar.gz -o $SOURCE_DIR/openvas-smb-$OPENVAS_SMB_VERSION.tar.gz
curl -f -L https://github.com/greenbone/openvas-smb/releases/download/v$OPENVAS_SMB_VERSION/openvas-smb-v$OPENVAS_SMB_VERSION.tar.gz.asc -o $SOURCE_DIR/openvas-smb-$OPENVAS_SMB_VERSION.tar.gz.asc

tar -C $SOURCE_DIR -xvzf $SOURCE_DIR/openvas-smb-$OPENVAS_SMB_VERSION.tar.gz


mkdir -p $BUILD_DIR/openvas-smb && cd $BUILD_DIR/openvas-smb

sudo cmake $SOURCE_DIR/openvas-smb-$OPENVAS_SMB_VERSION \
  -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
  -DCMAKE_BUILD_TYPE=Release

sudo make -j$(nproc)


mkdir -p $INSTALL_DIR/openvas-smb

sudo make DESTDIR=$INSTALL_DIR/openvas-smb install

sudo cp -r $INSTALL_DIR/openvas-smb/* /


#openvas-scanner  
export OPENVAS_SCANNER_VERSION=22.7.2

sudo apt install -y \
  bison \
  libglib2.0-dev \
  libgnutls28-dev \
  libgcrypt20-dev \
  libpcap-dev \
  libgpgme-dev \
  libksba-dev \
  rsync \
  nmap \
  libjson-glib-dev \
  libbsd-dev \
  pandoc

  sudo apt install -y \
  python3-impacket \
  libsnmp-dev

curl -f -L https://github.com/greenbone/openvas-scanner/archive/refs/tags/v$OPENVAS_SCANNER_VERSION.tar.gz -o $SOURCE_DIR/openvas-scanner-$OPENVAS_SCANNER_VERSION.tar.gz
curl -f -L https://github.com/greenbone/openvas-scanner/releases/download/v$OPENVAS_SCANNER_VERSION/openvas-scanner-v$OPENVAS_SCANNER_VERSION.tar.gz.asc -o $SOURCE_DIR/openvas-scanner-$OPENVAS_SCANNER_VERSION.tar.gz.asc

tar -C $SOURCE_DIR -xvzf $SOURCE_DIR/openvas-scanner-$OPENVAS_SCANNER_VERSION.tar.gz

#build openvas scanner
mkdir -p $BUILD_DIR/openvas-scanner && cd $BUILD_DIR/openvas-scanner

sudo cmake $SOURCE_DIR/openvas-scanner-$OPENVAS_SCANNER_VERSION \
  -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
  -DCMAKE_BUILD_TYPE=Release \
  -DINSTALL_OLD_SYNC_SCRIPT=OFF \
  -DSYSCONFDIR=/etc \
  -DLOCALSTATEDIR=/var \
  -DOPENVAS_FEED_LOCK_PATH=/var/lib/openvas/feed-update.lock \
  -DOPENVAS_RUN_DIR=/run/ospd

sudo make -j$(nproc)

#install openvas scanner
mkdir -p $INSTALL_DIR/openvas-scanner

sudo make DESTDIR=$INSTALL_DIR/openvas-scanner install

sudo cp -r $INSTALL_DIR/openvas-scanner/* /

#ospd-openvas
export OSPD_OPENVAS_VERSION=22.5.1
sudo apt install -y \
  python3 \
  python3-pip \
  python3-setuptools \
  python3-packaging \
  python3-wrapt \
  python3-cffi \
  python3-psutil \
  python3-lxml \
  python3-defusedxml \
  python3-paramiko \
  python3-redis \
  python3-gnupg \
  python3-paho-mqtt

curl -f -L https://github.com/greenbone/ospd-openvas/archive/refs/tags/v$OSPD_OPENVAS_VERSION.tar.gz -o $SOURCE_DIR/ospd-openvas-$OSPD_OPENVAS_VERSION.tar.gz
curl -f -L https://github.com/greenbone/ospd-openvas/releases/download/v$OSPD_OPENVAS_VERSION/ospd-openvas-v$OSPD_OPENVAS_VERSION.tar.gz.asc -o $SOURCE_DIR/ospd-openvas-$OSPD_OPENVAS_VERSION.tar.gz.asc

tar -C $SOURCE_DIR -xvzf $SOURCE_DIR/ospd-openvas-$OSPD_OPENVAS_VERSION.tar.gz

#installing ospd-openvas
cd $SOURCE_DIR/ospd-openvas-$OSPD_OPENVAS_VERSION

mkdir -p $INSTALL_DIR/ospd-openvas

python3 -m pip install --root=$INSTALL_DIR/ospd-openvas --no-warn-script-location .

sudo cp -r $INSTALL_DIR/ospd-openvas/* /

#notus-scanner
export NOTUS_VERSION=22.5.0
sudo apt install -y \
  python3 \
  python3-pip \
  python3-setuptools \
  python3-paho-mqtt \
  python3-psutil \
  python3-gnupg

curl -f -L https://github.com/greenbone/notus-scanner/archive/refs/tags/v$NOTUS_VERSION.tar.gz -o $SOURCE_DIR/notus-scanner-$NOTUS_VERSION.tar.gz
curl -f -L https://github.com/greenbone/notus-scanner/releases/download/v$NOTUS_VERSION/notus-scanner-$NOTUS_VERSION.tar.gz.asc -o $SOURCE_DIR/notus-scanner-$NOTUS_VERSION.tar.gz.asc

tar -C $SOURCE_DIR -xvzf $SOURCE_DIR/notus-scanner-$NOTUS_VERSION.tar.gz

#installing notus-scanner
cd $SOURCE_DIR/notus-scanner-$NOTUS_VERSION

mkdir -p $INSTALL_DIR/notus-scanner

python3 -m pip install --root=$INSTALL_DIR/notus-scanner --no-warn-script-location .

sudo cp -r $INSTALL_DIR/notus-scanner/* /

#greenbone-feed-sync
sudo apt install -y \
  python3 \
  python3-pip

mkdir -p $INSTALL_DIR/greenbone-feed-sync

python3 -m pip install --root=$INSTALL_DIR/greenbone-feed-sync --no-warn-script-location greenbone-feed-sync
#puts greeenbone-feed-sync in at $USER/.local/
sudo cp -r $INSTALL_DIR/greenbone-feed-sync/* /
#
#gvm-tools
sudo apt install -y \
  python3 \
  python3-pip \
  python3-venv \
  python3-setuptools \
  python3-packaging \
  python3-lxml \
  python3-defusedxml \
  python3-paramiko

mkdir -p $INSTALL_DIR/gvm-tools

python3 -m pip install --root=$INSTALL_DIR/gvm-tools --no-warn-script-location gvm-tools

sudo cp -r $INSTALL_DIR/gvm-tools/* /


#Perfoming system setup

#move all .local/bin to /usr
sudo cp -r ~/.local/* /usr/

#redis data store
sudo apt install -y redis-server
sudo cp $SOURCE_DIR/openvas-scanner-$OPENVAS_SCANNER_VERSION/config/redis-openvas.conf /etc/redis/
sudo chown redis:redis /etc/redis/redis-openvas.conf
echo "db_address = /run/redis-openvas/redis.sock" | sudo tee -a /etc/openvas/openvas.conf
sudo systemctl start redis-server@openvas.service
sudo systemctl enable redis-server@openvas.service
sudo usermod -aG redis gvm


#setup mosquitto mqtt broker

sudo usermod -aG redis gvm
sudo apt install -y mosquitto
sudo systemctl start mosquitto.service
sudo systemctl enable mosquitto.service
echo -e "mqtt_server_uri = localhost:1883\ntable_driven_lsc = yes" | sudo tee -a /etc/openvas/openvas.conf

sudo mkdir -p /var/lib/notus
sudo mkdir -p /run/gvmd

sudo chown -R gvm:gvm /var/lib/gvm
sudo chown -R gvm:gvm /var/lib/openvas
sudo chown -R gvm:gvm /var/lib/notus
sudo chown -R gvm:gvm /var/log/gvm
sudo chown -R gvm:gvm /run/gvmd

sudo chmod -R g+srw /var/lib/gvm
sudo chmod -R g+srw /var/lib/openvas
sudo chmod -R g+srw /var/log/gvm

sudo chown gvm:gvm /usr/local/sbin/gvmd
sudo chmod 6750 /usr/local/sbin/gvmd

#feed validation for community feed
#create keyring
curl -f -L https://www.greenbone.net/GBCommunitySigningKey.asc -o /tmp/GBCommunitySigningKey.asc

export GNUPGHOME=/tmp/openvas-gnupg
mkdir -p $GNUPGHOME

gpg --import /tmp/GBCommunitySigningKey.asc
echo "8AE4BE429B60A59B311C2E739823FAA60ED1E580:6:" | gpg --import-ownertrust

export OPENVAS_GNUPG_HOME=/etc/openvas/gnupg
sudo mkdir -p $OPENVAS_GNUPG_HOME
sudo cp -r /tmp/openvas-gnupg/* $OPENVAS_GNUPG_HOME/
sudo chown -R gvm:gvm $OPENVAS_GNUPG_HOME

#setup sudo for scanning
echo "%gvm  ALL=NOPASSWD: /usr/local/sbin/openvas" >> /etc/sudoers

#setting up PostgreSQL
sudo apt install -y postgresql
sudo systemctl start postgresql@13-main

sudo -u postgres bash << EOF 
cd
createuser -DRS gvm
createdb -O gvm gvmd
psql gvmd -c "create role dba with superuser noinherit; grant dba to gvm;"

exit
EOF

#ask for password
while true; do
 echo
 echo
 echo
 echo "Enter Password for Greenbone admin: " 
 read password
 echo
 echo
 echo "Confirm Password: "
  read password2
  echo
  [ "$password" = "$password2" ] && break
  echo "Please try again"
done

/usr/local/sbin/gvmd --create-user=admin --password=$password

#feed import
/usr/local/sbin/gvmd --modify-setting 78eceaec-3385-11ea-b237-28d24461215b --value `/usr/local/sbin/gvmd --get-users --verbose | grep admin | awk '{print $2}'`

cat << EOF > $BUILD_DIR/ospd-openvas.service
[Unit]
Description=OSPd Wrapper for the OpenVAS Scanner (ospd-openvas)
Documentation=man:ospd-openvas(8) man:openvas(8)
After=network.target networking.service redis-server@openvas.service mosquitto.service
Wants=redis-server@openvas.service mosquitto.service notus-scanner.service
ConditionKernelCommandLine=!recovery

[Service]
Type=exec
User=gvm
Group=gvm
RuntimeDirectory=ospd
RuntimeDirectoryMode=2775
PIDFile=/run/ospd/ospd-openvas.pid
ExecStart=/usr/local/bin/ospd-openvas --foreground --unix-socket /run/ospd/ospd-openvas.sock --pid-file /run/ospd/ospd-openvas.pid --log-file /var/log/gvm/ospd-openvas.log --lock-file-dir /var/lib/openvas --socket-mode 0o770 --mqtt-broker-address localhost --mqtt-broker-port 1883 --notus-feed-dir /var/lib/notus/advisories
SuccessExitStatus=SIGKILL
Restart=always
RestartSec=60

[Install]
WantedBy=multi-user.target
EOF

sudo cp -v $BUILD_DIR/ospd-openvas.service /etc/systemd/system/

cat << EOF > $BUILD_DIR/notus-scanner.service
[Unit]
Description=Notus Scanner
Documentation=https://github.com/greenbone/notus-scanner
After=mosquitto.service
Wants=mosquitto.service
ConditionKernelCommandLine=!recovery

[Service]
Type=exec
User=gvm
RuntimeDirectory=notus-scanner
RuntimeDirectoryMode=2775
PIDFile=/run/notus-scanner/notus-scanner.pid
ExecStart=/usr/local/bin/notus-scanner --foreground --products-directory /var/lib/notus/products --log-file /var/log/gvm/notus-scanner.log
SuccessExitStatus=SIGKILL
Restart=always
RestartSec=60

[Install]
WantedBy=multi-user.target
EOF

sudo cp -v $BUILD_DIR/notus-scanner.service /etc/systemd/system/

cat << EOF > $BUILD_DIR/gvmd.service
[Unit]
Description=Greenbone Vulnerability Manager daemon (gvmd)
After=network.target networking.service postgresql.service ospd-openvas.service
Wants=postgresql.service ospd-openvas.service
Documentation=man:gvmd(8)
ConditionKernelCommandLine=!recovery

[Service]
Type=exec
User=gvm
Group=gvm
PIDFile=/run/gvmd/gvmd.pid
RuntimeDirectory=gvmd
RuntimeDirectoryMode=2775
ExecStart=/usr/local/sbin/gvmd --foreground --osp-vt-update=/run/ospd/ospd-openvas.sock --listen-group=gvm
Restart=always
TimeoutStopSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo cp -v $BUILD_DIR/gvmd.service /etc/systemd/system/

cat << EOF > $BUILD_DIR/gsad.service
[Unit]
Description=Greenbone Security Assistant daemon (gsad)
Documentation=man:gsad(8) https://www.greenbone.net
After=network.target gvmd.service
Wants=gvmd.service

[Service]
Type=exec
User=gvm
Group=gvm
RuntimeDirectory=gsad
RuntimeDirectoryMode=2775
PIDFile=/run/gsad/gsad.pid
ExecStart=/usr/local/sbin/gsad --foreground --listen=127.0.0.1 --port=9392 --http-only
Restart=always
TimeoutStopSec=10

[Install]
WantedBy=multi-user.target
Alias=greenbone-security-assistant.service
EOF

sudo cp -v $BUILD_DIR/gsad.service /etc/systemd/system/

sudo systemctl daemon-reload
#download data for feed


sudo /usr/local/bin/greenbone-feed-sync


#start service
sudo systemctl start notus-scanner
sudo systemctl start ospd-openvas
sudo systemctl start gvmd
sudo systemctl start gsad

sudo systemctl enable notus-scanner
sudo systemctl enable ospd-openvas
sudo systemctl enable gvmd
sudo systemctl enable gsad



# run checks to ensure installation is successful. 


#change desktop icon to launch browser to location
cat > /usr/share/applications/greenbone.desktop <<EOF 
[Desktop Entry]
Name=Greenbone Community Edition
StartupWMClass=greenbone
Encoding=UTF-8
Exec=xdg-open "http://127.0.0.1:9392"
StartupNotify=true
Terminal=false
Type=Application
Icon=/usr/share/icons/dist/greenbone.png
Categories=Security, Utilities
EOF

xdg-open "http://127.0.0.1:9392" 2>/dev/null >/dev/null &



