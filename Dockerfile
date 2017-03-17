FROM lsiobase/xenial

MAINTAINER Sparklyballs <sparklyballs@linuxserver.io>, ajw107 (Alex Wood)

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"

# set owncloud initial install version and mariadb folders
ARG DEBIAN_FRONTEND="noninteractive"
ENV DEBUG="TRUE"
ENV USER="abc"
ENV GROUP="abc"
ENV OC_DIR="/var/www/owncloud"
ENV CONFIG_DIR="/config"
ENV MYSQL_DIR="${CONFIG_DIR}/database"
ENV DATA_DIR="/data"
#make life easy for yourself
ENV TERM=xterm-color
ENV OWNCLOUD_VER="9.1.4"
ENV DB_PASSWORD="owncloud"

ENV BUILD_APTLIST="php7.0-dev"
#libmysqlclient18 libpcre3-dev libsmbclient.dev nano nginx openssl php-apcu php7.0-bz2 php7.0-cli \
ENV APTLIST="exim4 exim4-base exim4-config exim4-daemon-light git-core heirloom-mailx jq libaio1 libapr1 \
libaprutil1 libaprutil1-dbd-sqlite3 libaprutil1-ldap libdbd-mysql-perl libdbi-perl libfreetype6 \
libpcre3-dev libsmbclient.dev nano nginx openssl php-apcu php7.0-bz2 php7.0-cli \
php7.0-common php7.0-curl php7.0-fpm php7.0-gd php7.0-gmp php7.0-imap php7.0-intl php7.0-ldap \
php7.0-mbstring php7.0-mcrypt php7.0-mysql php7.0-opcache php7.0-xml php7.0-xmlrpc php7.0-zip \
php-imagick pkg-config smbclient re2c ssl-cert"
ENV DB_APTLIST="mysql-server mysqltuner"

# add repositories
RUN apt-get update -q && \
apt-get install -qy software-properties-common wget debconf-utils sudo cron
#RUN \
  # mariadb
#apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8 && \
#add-apt-repository -y 'deb http://lon1.mirrors.digitalocean.com/mariadb/repo/10.2/ubuntu xenial main'
 # nginx
RUN add-apt-repository -s -y ppa:nginx/development
 # php7
#echo "deb http://ppa.launchpad.net/ondrej/php/ubuntu trusty main" >> /etc/apt/sources.list.d/php7.list && \
#echo "deb-src http://ppa.launchpad.net/ondrej/php/ubuntu trusty main" >> /etc/apt/sources.list.d/php7.list && \
#apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 4F4EA0AAE5267A6C && \
RUN LC_ALL=C.UTF-8 add-apt-repository -s -y ppa:ondrej/php
 # python this repo is now out dated, just use ubuntu
#RUN add-apt-repository -s -y ppa:fkrull/deadsnakes-python2.7
 # owncloud
RUN curl https://download.owncloud.org/download/repositories/9.1/Ubuntu_16.04/Release.key | apt-key add - && \
add-apt-repository 'deb http://download.owncloud.org/download/repositories/9.1/Ubuntu_16.04/ /'

# install packages
#RUN echo "mariadb-server mysql-server/root_password password ${DB_PASSWORD}" | debconf-set-selections && \
#echo "mariadb-server mysql-server/root_password_again password ${DB_PASSWORD}" | debconf-set-selections && \
#apt-get install -qy ${DB_APTLIST} -o pkg::Options::="--force-confdef" -o pkg::Options::="--force-confold" --fix-missing
RUN apt-get install -qy ${DB_APTLIST}

RUN apt-get update -q && \
apt-get install -qy owncloud $APTLIST $BUILD_APTLIST

# build libsmbclient support
RUN git clone git://github.com/eduardok/libsmbclient-php.git /tmp/smbclient && \
cd /tmp/smbclient && \
phpize && \
./configure && \
make && \
make install && \
echo "extension=smbclient.so" > /etc/php/7.0/mods-available/smbclient.ini

# install apcu
RUN git clone https://github.com/krakjoe/apcu /tmp/apcu && \
cd /tmp/apcu && \
phpize && \
./configure && \
make && \
make install && \
echo "extension=apcu.so" > /etc/php/7.0/mods-available/apcu.ini

# cleanup
RUN cd / && \
apt-get purge --remove $BUILD_APTLIST -y && \
apt-get autoremove -y && \
apt-get clean -y && \
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/lib/mysql && \
mkdir -p /var/lib/mysql

# add some files
COPY root/ /
RUN chmod +x /usr/bin/ll
COPY services/ /etc/services.d/
COPY  defaults/ /defaults/
COPY init/ /etc/cont-init.d/
RUN chmod -v +x /etc/services.d/*/run /etc/cont-init.d/*.sh && \

# configure fpm for owncloud
echo "env[PATH] = /usr/local/bin:/usr/bin:/bin" >> /defaults/nginx-fpm.conf

# expose ports
EXPOSE 443

# set volumes
VOLUME ${CONFIG_DIR} ${DATA_DIR}

