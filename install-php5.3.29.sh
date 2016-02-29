#!/bin/sh

apt-get install build-essential
apt-get install libfcgi-dev libfcgi0ldbl libjpeg62-turbo-dbg libmcrypt-dev libssl-dev libc-client2007e libc-client2007e-dev libxml2-dev libbz2-dev libcurl4-openssl-dev libjpeg-dev libpng12-dev libfreetype6-dev libkrb5-dev libpq-dev libxml2-dev libxslt1-dev
ln -s /usr/lib/libc-client.a /usr/lib/x86_64-linux-gnu/libc-client.a


mkdir -p /opt/php-5.3.29
mkdir /usr/local/src/php5-build
cd /usr/local/src/php5-build
wget http://de1.php.net/get/php-5.3.29.tar.bz2/from/this/mirror -O php-5.3.29.tar.bz2
tar jxf php-5.3.29.tar.bz2
cd php-5.3.29/
./configure --help
./configure --prefix=/opt/php-5.3.29 --with-pdo-pgsql --with-zlib-dir --with-freetype-dir --enable-mbstring --with-libxml-dir=/usr --enable-soap --enable-calendar --with-curl --with-mcrypt --with-zlib --with-gd --with-pgsql --disable-rpath --enable-inline-optimization --with-bz2 --with-zlib --enable-sockets --enable-sysvsem --enable-sysvshm --enable-pcntl --enable-mbregex --enable-exif --enable-bcmath --with-mhash --enable-zip --with-pcre-regex --with-pdo-mysql --with-mysqli --with-mysql-sock=/var/run/mysqld/mysqld.sock --with-jpeg-dir=/usr --with-png-dir=/usr --enable-gd-native-ttf --with-openssl --with-fpm-user=www-data --with-fpm-group=www-data --with-libdir=/lib/x86_64-linux-gnu --enable-ftp --with-imap --with-imap-ssl --with-kerberos --with-gettext --with-xmlrpc --with-xsl --enable-opcache --enable-fpm
make
make install
cp /usr/local/src/php5-build/php-5.3.29/php.ini-production /opt/php-5.3.29/lib/php.ini
cp /opt/php-5.3.29/etc/php-fpm.conf.default /opt/php-5.3.29/etc/php-fpm.conf
mkdir /opt/php-5.3.29/etc/php-fpm.d
echo "include=/opt/php-5.3.29/etc/php-fpm.d/*.conf" >> /opt/php-5.3.29/etc/php-fpm.conf
cp /opt/php-5.3.29/etc/php-fpm.conf.default /opt/php-5.3.29/etc/php-fpm.d/www.conf
sed -i 's/9000/9014/g' /opt/php-5.3.29/etc/php-fpm.d/www.conf

cat <<EOF >/etc/init.d/php-5.3.29-fpm
#! /bin/sh
### BEGIN INIT INFO
# Provides:          php-5.3.29-fpm
# Required-Start:    $all
# Required-Stop:     $all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts php-5.3.29-fpm
# Description:       starts the PHP FastCGI Process Manager daemon
### END INIT INFO
php_fpm_BIN=/opt/php-5.3.29/sbin/php-fpm
php_fpm_CONF=/opt/php-5.3.29/etc/php-fpm.conf
php_fpm_PID=/opt/php-5.3.29/var/run/php-fpm.pid
php_opts="--fpm-config $php_fpm_CONF"
wait_for_pid () {
        try=0
        while test $try -lt 35 ; do
                case "$1" in
                        'created')
                        if [ -f "$2" ] ; then
                                try=''
                                break
                        fi
                        ;;
                        'removed')
                        if [ ! -f "$2" ] ; then
                                try=''
                                break
                        fi
                        ;;
                esac
                echo -n .
                try=`expr $try + 1`
                sleep 1
        done
}
case "$1" in
        start)
                echo -n "Starting php-fpm "
                $php_fpm_BIN $php_opts
                if [ "$?" != 0 ] ; then
                        echo " failed"
                        exit 1
                fi
                wait_for_pid created $php_fpm_PID
                if [ -n "$try" ] ; then
                        echo " failed"
                        exit 1
                else
                        echo " done"
                fi
        ;;
        stop)
                echo -n "Gracefully shutting down php-fpm "
                if [ ! -r $php_fpm_PID ] ; then
                        echo "warning, no pid file found - php-fpm is not running ?"
                        exit 1
                fi
                kill -QUIT `cat $php_fpm_PID`
                wait_for_pid removed $php_fpm_PID
                if [ -n "$try" ] ; then
                        echo " failed. Use force-exit"
                        exit 1
                else
                        echo " done"
                       echo " done"
                fi
        ;;
        force-quit)
                echo -n "Terminating php-fpm "
                if [ ! -r $php_fpm_PID ] ; then
                        echo "warning, no pid file found - php-fpm is not running ?"
                        exit 1
                fi
                kill -TERM `cat $php_fpm_PID`
                wait_for_pid removed $php_fpm_PID
                if [ -n "$try" ] ; then
                        echo " failed"
                        exit 1
                else
                        echo " done"
                fi
        ;;
        restart)
                $0 stop
                $0 start
        ;;
        reload)
                echo -n "Reload service php-fpm "
                if [ ! -r $php_fpm_PID ] ; then
                        echo "warning, no pid file found - php-fpm is not running ?"
                        exit 1
                fi
                kill -USR2 `cat $php_fpm_PID`
                echo " done"
        ;;
        *)
                echo "Usage: $0 {start|stop|force-quit|restart|reload}"
                exit 1
        ;;
esac
EOF



chmod 755 /etc/init.d/php-5.3.29-fpm
insserv php-5.3.29-fpm

cat <<EOF >/lib/systemd/system/php-5.3.29-fpm.service
[Unit]
Description=The PHP 5 FastCGI Process Manager
After=network.target

[Service]
Type=simple
PIDFile=/opt/php-5.3.29/var/run/php-fpm.pid
ExecStart=/opt/php-5.3.29/sbin/php-fpm --nodaemonize --fpm-config /opt/php-5.3.29/etc/php-fpm.conf
ExecReload=/bin/kill -USR2 $MAINPID

[Install]
WantedBy=multi-user.target
EOF




systemctl enable php-5.3.29-fpm.service
systemctl daemon-reload

systemctl start php-5.3.29-fpm.service
