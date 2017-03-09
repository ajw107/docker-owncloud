#!/usr/bin/with-contenv bash

# make folders if required
mkdir -p config/{nginx/site-confs,www,log/mysql,log/nginx,keys} /var/run/{php,mysqld}

# configure mariadb
find /etc/mysql -type f -iname "*.cnf" -exec sed -i 's/key_buffer\b/key_buffer_size/g' "{}" \;
find /etc/mysql -type f -iname "*.cnf" -exec sed -ri 's/^(bind-address|skip-networking)/;\1/' "{}" \;
find /etc/mysql -type f -iname "*.cnf" -exec sed -i s#/var/log/mysql#/config/log/mysql#g "{}" \;
find /etc/mysql -type f -iname "*.cnf" -exec sed -i -e 's/\(user.*=\).*/\1 abc/g' "{}" \;
find /etc/mysql -type f -iname "*.cnf" -exec sed -i -e "s#\(datadir.*=\).*#\1 $DATADIR#g" "{}" \;
sed -i "s/user='mysql'/user='abc'/g" /usr/bin/mysqld_safe

# setup custom cnf file
[[ ! -f /config/custom.cnf ]] && cp /defaults/my.cnf /config/custom.cnf
[[ ! -L /etc/mysql/conf.d/custom.cnf && -f /etc/mysql/conf.d/custom.cnf ]] && rm /etc/mysql/conf.d/custom.cnf
[[ ! -L /etc/mysql/conf.d/custom.cnf ]] && ln -s /config/custom.cnf /etc/mysql/conf.d/custom.cnf


# configure nginx
[[ ! -f /config/nginx/nginx.conf ]] && cp /defaults/nginx.conf /config/nginx/nginx.conf
[[ ! -f /config/nginx/nginx-fpm.conf ]] && cp /defaults/nginx-fpm.conf /config/nginx/nginx-fpm.conf
[[ ! -f /config/nginx/site-confs/default ]] && cp /defaults/default /config/nginx/site-confs/default

chown abc:abc /data
chown -R abc:abc /config /var/run/php
chmod -R 777 /var/run/mysqld



