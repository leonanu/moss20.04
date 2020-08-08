#!/bin/bash
## php-7.4.x
if ! grep '^PHP$' ${INST_LOG} > /dev/null 2>&1 ;then

## check proc
    proc_exist php-fpm
    if [ ${PROC_FOUND} -eq 1 ];then
        fail_msg "PHP FactCGI is running on this host!"
    fi

## install pkgs
    apt install -y \
    libbz2-dev \
    libxml2-dev \
    libldap2-dev \
    libsasl2-dev \
    libsqlite3-dev \
    libsystemd-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    libpng-dev \
    libwebp-dev \
    libjpeg-dev \
    libxpm-dev \
    libfreetype6-dev \
    libgmp-dev \
    libonig-dev \
    libzip-dev \
    zlib1g-dev

## handle source packages
    file_proc ${PHP_SRC}
    get_file
    unpack

    CONFIG="./configure \
            --prefix=${INST_DIR}/${SRC_DIR} \
            --with-config-file-path=/usr/local/php/etc \
            --with-bz2 \
            --with-curl \
            --with-mysqli=mysqlnd \
            --with-pdo-mysql=mysqlnd \
            --with-ldap \
            --with-ldap-sasl \
            --with-openssl \
            --with-zip \
            --with-zlib \
            --with-jpeg \
            --with-webp \
            --with-xpm \
            --with-gettext \
            --with-freetype \
            --with-mhash \
            --with-gmp \
            --with-xmlrpc \
            --with-fpm-systemd \
            --with-fpm-user=www-data \
            --with-fpm-group=www-data \
            --enable-mysqlnd \
            --enable-fpm \
            --enable-gd \
            --enable-gd-jis-conv \
            --enable-ftp \
            --enable-bcmath \
            --enable-calendar \
            --enable-exif \
            --enable-sockets \
            --enable-calendar \
            --enable-soap \
            --enable-shmop \
            --enable-mbstring \
            --enable-sysvmsg \
            --enable-sysvsem \
            --enable-sysvshm \
            --disable-short-tags \
            --disable-cgi \
            --disable-phar \
            --disable-rpath"

## for compile
    MAKE='make'
    INSTALL='make install'
    SYMLINK='/usr/local/php'
    compile
    
    mkdir ${INST_DIR}/${SRC_DIR}/ext

## for install config files
        succ_msg "Begin to install ${SRC_DIR} config files"
        ## conf
        install -m 0644 ${TOP_DIR}/conf/php/php.ini ${INST_DIR}/${SRC_DIR}/etc/php.ini
        install -m 0644 ${TOP_DIR}/conf/php/php-fpm.conf ${INST_DIR}/${SRC_DIR}/etc/php-fpm.conf
        install -m 0644 ${TOP_DIR}/conf/php/php-fpm-default.conf ${INST_DIR}/${SRC_DIR}/etc/php-fpm.d/default.conf
        ## log
        [ ! -d "/var/log/php" ] && mkdir -m 0755 -p /var/log/php
        [ ! -d "/usr/local/etc/logrotate" ] && mkdir -m 0755 -p /usr/local/etc/logrotate
        chown www-data:www-data -R /var/log/php
        install -m 0644 ${TOP_DIR}/conf/php/php-fpm.logrotate /usr/local/etc/logrotate/php-fpm
        ## cron job
        echo '' >> /var/spool/cron/crontabs/root
        echo '# Logrotate - PHP-FPM' >> /var/spool/cron/crontabs/root
        echo '0 0 * * * /usr/sbin/logrotate -f /usr/local/etc/logrotate/php-fpm > /dev/null 2>&1' >> /var/spool/cron/crontabs/root
        ## opcache
        OPCACHE=$(find ${INST_DIR}/${SRC_DIR}/ -name 'opcache.so')
        mv -f ${OPCACHE} ${INST_DIR}/${SRC_DIR}/ext/ 
        ## security
        #sed -i "s#^open_basedir.*#open_basedir = "${NGX_DOCROOT},/tmp"#" /usr/local/php/etc/php.ini
        ## init scripts
        install -m 0644 ${TOP_DIR}/conf/php/php-fpm.service /usr/lib/systemd/system/php-fpm.service
        systemctl daemon-reload
        systemctl enable php-fpm.service
        ## start
        systemctl start php-fpm.service
        sleep 3

## check proc
    proc_exist php-fpm
    if [ ${PROC_FOUND} -eq 0 ];then
        fail_msg "PHP-FPM fail to start!"
    fi

## record installed tag
    echo 'PHP' >> ${INST_LOG}
else
    succ_msg "PHP already installed!"
fi
