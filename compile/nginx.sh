#!/bin/bash
## nginx-1.19.x
if ! grep '^NGINX$' ${INST_LOG} > /dev/null 2>&1 ;then

## check proc
    proc_exist nginx
    if [ ${PROC_FOUND} -eq 1 ];then
        fail_msg "There already have Nginx running!"
    fi

## check settings
    [ -z ${NGX_HOSTNAME} ] && NGX_HOSTNAME='www.foo.com'
    [ -z ${NGX_DOCROOT} ] && NGX_DOCROOT="/data/wwwroot/${NGX_HOSTNAME}"
    [ -z ${NGX_LOGDIR} ] && NGX_LOGDIR='/var/log/nginx'

## nginx 
    file_proc ${NGINX_SRC}
    get_file
    unpack

    CONFIG="./configure --prefix=${INST_DIR}/${SRC_DIR} \
            --pid-path=/var/run/nginx.pid \
            --error-log-path=/var/log/nginx/error.log \
            --http-log-path=/var/log/nginx/access.log \
            --http-client-body-temp-path=/usr/local/nginx/var/tmp/client_body \
            --http-proxy-temp-path=/usr/local/nginx/var/tmp/proxy \
            --http-fastcgi-temp-path=/usr/local/nginx/var/tmp/fastcgi \
            --http-uwsgi-temp-path=/usr/local/nginx/var/tmp/uwsgi \
            --with-threads \
            --with-file-aio \
            --with-http_ssl_module \
            --with-http_v2_module \
            --with-http_flv_module \
            --with-http_mp4_module \
            --with-http_realip_module \
            --with-http_addition_module \
            --with-http_gunzip_module \
            --with-http_gzip_static_module \
            --with-http_auth_request_module \
            --with-http_stub_status_module \
            --with-pcre \
            --with-stream \
            --with-stream_ssl_module \
            --with-stream_realip_module \
            --with-stream_ssl_preread_module \
            --without-http_ssi_module \
            --without-http_geo_module \
            --without-http_scgi_module \
            --without-mail_pop3_module \
            --without-mail_imap_module \
            --without-mail_smtp_module"

## for compile
    MAKE='make'
    INSTALL='make install'
    SYMLINK='/usr/local/nginx'
    compile
    
    [ ! -d "${INST_DIR}/${SRC_DIR}/conf/vhosts" ] && mkdir -m 0755 -p ${INST_DIR}/${SRC_DIR}/conf/vhosts
    [ ! -d "${INST_DIR}/${SRC_DIR}/conf/stream" ] && mkdir -m 0755 -p ${INST_DIR}/${SRC_DIR}/conf/stream

## for install config files
    succ_msg "Begin to install ${SRC_DIR} config files"
    ## document root
    [ ! -d "${NGX_DOCROOT}" ] && mkdir -m 0755 -p ${NGX_DOCROOT}
    chown -R www-data:www-data ${NGX_DOCROOT}
    ## log directory
    [ ! -d "${NGX_LOGDIR}" ] && mkdir -m 0755 -p ${NGX_LOGDIR}
    chown -R www-data:www-data ${NGX_LOGDIR}
    ## tmp directory
    [ ! -d "/usr/local/nginx/var/tmp/client_body" ] && mkdir -m 0777 -p /usr/local/nginx/var/tmp/client_body
    [ ! -d "/usr/local/nginx/var/tmp/fastcgi" ] && mkdir -m 0777 -p /usr/local/nginx/var/tmp/fastcgi
    [ ! -d "/usr/local/nginx/var/tmp/uwsgi" ] && mkdir -m 0777 -p /usr/local/nginx/var/tmp/uwsgi
    [ ! -d "/usr/local/nginx/var/tmp/proxy" ] && mkdir -m 0777 -p /usr/local/nginx/var/tmp/proxy
    chown -R www-data:www-data /usr/local/nginx/var
    ## conf
    install -m 0644 ${TOP_DIR}/conf/nginx/nginx.conf ${INST_DIR}/${SRC_DIR}/conf/nginx.conf
    install -m 0644 ${TOP_DIR}/conf/nginx/vhost.conf ${INST_DIR}/${SRC_DIR}/conf/vhosts/${NGX_HOSTNAME}.conf
    install -m 0644 ${TOP_DIR}/conf/nginx/stream_http.conf.sample ${INST_DIR}/${SRC_DIR}/conf/stream/stream_http.conf.sample
    install -m 0644 ${TOP_DIR}/conf/nginx/stream_https.conf.sample ${INST_DIR}/${SRC_DIR}/conf/stream/stream_https.conf.sample
    sed -i "s#.*ng_server_name.*#    server_name  ${NGX_HOSTNAME};#g" ${INST_DIR}/${SRC_DIR}/conf/vhosts/${NGX_HOSTNAME}.conf
    sed -i "s#.*ng_root.*#    root         ${NGX_DOCROOT};#g" ${INST_DIR}/${SRC_DIR}/conf/vhosts/${NGX_HOSTNAME}.conf
    sed -i "s#.*ng_access_log.*#    access_log  ${NGX_LOGDIR}/${NGX_HOSTNAME}_access.log main buffer=4k;#g" ${INST_DIR}/${SRC_DIR}/conf/vhosts/${NGX_HOSTNAME}.conf
    sed -i "s#.*ng_error_log.*#    error_log   ${NGX_LOGDIR}/${NGX_HOSTNAME}_error.log error;#g" ${INST_DIR}/${SRC_DIR}/conf/vhosts/${NGX_HOSTNAME}.conf
    ## log
    [ ! -d "/usr/local/etc/logrotate" ] && mkdir -m 0755 -p /usr/local/etc/logrotate
    install -m 0644 ${TOP_DIR}/conf/nginx/nginx.logrotate /usr/local/etc/logrotate/nginx
    sed -i "s#/var/log/nginx#${NGX_LOGDIR}#g" /usr/local/etc/logrotate/nginx
    [ ! -d "${INST_DIR}/${SRC_DIR}/logs" ] && mkdir -m 0755 -p ${INST_DIR}/${SRC_DIR}/logs
    [ ! -d "/var/log/nginx" ] && mkdir -m 0755 -p /var/log/nginx
    chown -R www-data:www-data ${INST_DIR}/${SRC_DIR}/logs
    chown -R www-data:www-data /var/log/nginx
    ## cron job
    echo '' >> /var/spool/cron/crontabs/root
    echo '# Logrotate - Nginx' >> /var/spool/cron/crontabs/root
    echo '0 0 * * * /usr/sbin/logrotate -f /usr/local/etc/logrotate/nginx > /dev/null 2>&1' >> /var/spool/cron/crontabs/root
    ## install CA
    [ ! -d '/usr/local/bin' ] && mkdir -p /usr/local/bin
    install -m 0755 ${TOP_DIR}/conf/nginx/ca.sh /usr/local/bin/ca.sh
    sed -i "s#.*PRE_VHOST_DN.*#    VHOST_DN=${NGX_HOSTNAME}#" /usr/local/bin/ca.sh
    ## create certs
    /usr/local/bin/ca.sh
    ## init scripts
    install -m 0644 ${TOP_DIR}/conf/nginx/nginx.service /usr/lib/systemd/system/nginx.service
    systemctl daemon-reload
    systemctl enable nginx.service
    ## start
    systemctl start nginx.service
    sleep 3

## check proc
    proc_exist nginx
    if [ ${PROC_FOUND} -eq 0 ];then
        fail_msg "Nginx fail to start!"
    fi

## record installed tag    
    echo 'NGINX' >> ${INST_LOG}
else
    succ_msg "Nginx already installed!"
fi
