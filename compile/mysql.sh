#!/bin/bash
### MySQL 8.0

if ! grep '^MYSQL$' ${INST_LOG} > /dev/null 2>&1 ; then

## check proc
    proc_exist mysqld
    if [ ${PROC_FOUND} -eq 1 ];then
        fail_msg "MySQL is running on this host!"
    fi

## check settings
    [ -z ${MYSQL_DATA_DIR} ] && MYSQL_DATA_DIR='/data/mysql'
    [ -z ${MYSQL_BACKUP_DIR} ] && MYSQL_BACKUP_DIR='/data/backup/mysql'
    [ -z ${MYSQL_LOGDIR} ] && MYSQL_LOGDIR='/var/log/mysql'

## handle source packages
    file_proc ${MYSQL_SRC}
    get_file
    unpack

    apt install -y libaio1 libtinfo6

    ln -s /usr/lib/x86_64-linux-gnu/libtinfo.so.6.2 /usr/lib/x86_64-linux-gnu/libtinfo.so.5

    SYMLINK='/usr/local/mysql'

    mv ${STORE_DIR}/${SRC_DIR} ${INST_DIR}
    ln -sf ${INST_DIR}/${SRC_DIR} $SYMLINK 
    id mysql >/dev/null 2>&1 || useradd mysql -r -M -s /bin/false
    [ ! -d $MYSQL_DATA_DIR ] && mkdir -m 0755 -p $MYSQL_DATA_DIR
    chown -R mysql:mysql $MYSQL_DATA_DIR
    install -m 0644 ${TOP_DIR}/conf/mysql/my.cnf /etc/my.cnf
    sed -i "s#datadir.*#datadir      = ${MYSQL_DATA_DIR}#" /etc/my.cnf
    sed -i "s#innodb_data_home_dir.*#innodb_data_home_dir           = ${MYSQL_DATA_DIR}#" /etc/my.cnf
    sed -i "s#innodb_log_group_home_dir.*#innodb_log_group_home_dir      = ${MYSQL_DATA_DIR}#" /etc/my.cnf
    sed -i "s#/var/log/mysql#${MYSQL_LOGDIR}#g" /etc/my.cnf
    chown -R mysql:mysql ${INST_DIR}/${SRC_DIR}

    ## log
    [ ! -d ${MYSQL_LOGDIR} ] && mkdir -m 0755 -p ${MYSQL_LOGDIR}
    [ ! -d /usr/local/etc/logrotate ] && mkdir -m 0755 -p /usr/local/etc/logrotate
    chown mysql:mysql -R ${MYSQL_LOGDIR}

    ## check sector file
    MYSQL_DATA_TOPDIR="/$(echo ${MYSQL_DATA_DIR} | cut -d '/' -f 2)"
    touch ${MYSQL_DATA_TOPDIR}/check_sector_size
    chown mysql:mysql ${MYSQL_DATA_TOPDIR}/check_sector_size

    ## initial mysql
    cd $SYMLINK
    bin/mysqld --initialize --user=mysql
    ## get tmp root password
    PASSWORD_LINE=$(grep 'A temporary password is generated' ${MYSQL_LOGDIR}/errors.log)
    TMP_PASS=$(echo ${PASSWORD_LINE} | awk -F 'localhost:' '{print $2;}' | xargs)
    bin/mysql_ssl_rsa_setup
    chown mysql:mysql -R $MYSQL_DATA_DIR

## for install config files
    succ_msg "Begin to install ${SRC_DIR} config files"
    ## log rotate
    install -m 0644 ${TOP_DIR}/conf/mysql/mysql.logrotate /usr/local/etc/logrotate/mysql
    sed -i "s#ROOT_PASS=.*#ROOT_PASS="${TMP_PASS}"#" /usr/local/etc/logrotate/mysql
    sed -i "s#/var/log/mysql#${MYSQL_LOGDIR}#g" /usr/local/etc/logrotate/mysql

    ## cron job
    echo '' >> /var/spool/cron/crontabs/root
    echo '# Logrotate - MySQL' >> /var/spool/cron/crontabs/root
    echo '0 0 * * * /usr/sbin/logrotate -f /usr/local/etc/logrotate/mysql > /dev/null 2>&1' >> /var/spool/cron/crontabs/root

    ## init scripts
    install -m 0755 ${SYMLINK}/support-files/mysql.server /etc/init.d/mysqld
    chmod 755 /etc/init.d/mysqld
    systemctl enable mysqld
    systemctl start mysqld
    sleep 3

## check proc
    proc_exist mysqld
    if [ ${PROC_FOUND} -eq 0 ];then
        fail_msg "MySQL failed to start!"
    fi

    ## Set MySQL root password
    #MYSQL_ROOT_PASS0=0
    #while [ $MYSQL_ROOT_PASS0 -eq 0 ]; do
    #    read -p "Please set MySQL root password:" MYSQL_ROOT_PASS1
    #    read -p "Input the root password again :" MYSQL_ROOT_PASS2
    #    if [ $MYSQL_ROOT_PASS1 = $MYSQL_ROOT_PASS2 ]; then
    #        MYSQL_ROOT_PASS0=1
    #    else
    #        warn_msg "The two password you input are not matched!"
    #        MYSQL_ROOT_PASS0=0
    #    fi
    #done

    #MYSQL_ROOT_PASS=$(mkpasswd -s 0 -l 12)
    #/usr/local/mysql/bin/mysqladmin -uroot password "${MYSQL_ROOT_PASS}"
    #/usr/local/mysql/bin/mysqladmin -h127.0.0.1 -uroot password "${MYSQL_ROOT_PASS}" 

    ## /root/.my.cnf
    echo '[client]' > /root/.my.cnf
    echo 'user = root' >> /root/.my.cnf
    echo "password = ${TMP_PASS}" >> /root/.my.cnf
    chmod 600 /root/.my.cnf
    #succ_msg "MySQL root password has been changed!"
    #warn_msg "Please protect the Moss config file CARFULLY!"
    #read -p 'Press any key to continue.'

    ## remove null username & password accounts
    #/usr/local/mysql/bin/mysql -uroot -p${MYSQL_ROOT_PASS} -e 'USE mysql; DELETE FROM user WHERE password=""; FLUSH PRIVILEGES;'

    ## create mysqladmin user account
    #/usr/local/mysql/bin/mysql -uroot -p${MYSQL_ROOT_PASS} -e "GRANT SHUTDOWN ON *.* TO '${MYSQL_MULADMIN_USER}'@'localhost' IDENTIFIED BY '${MYSQL_MULADMIN_PASS}'; FLUSH PRIVILEGES;"
    #/usr/local/mysql/bin/mysql -uroot -p${MYSQL_ROOT_PASS} -e "GRANT SHUTDOWN ON *.* TO '${MYSQL_MULADMIN_USER}'@'127.0.0.1' IDENTIFIED BY '${MYSQL_MULADMIN_PASS}'; FLUSH PRIVILEGES;"
    #/usr/local/mysql/bin/mysql -uroot -p${MYSQL_ROOT_PASS} -e "GRANT RELOAD ON *.* TO '${MYSQL_MULADMIN_USER}'@'localhost' IDENTIFIED BY '${MYSQL_MULADMIN_PASS}'; FLUSH PRIVILEGES;"
    #/usr/local/mysql/bin/mysql -uroot -p${MYSQL_ROOT_PASS} -e "GRANT RELOAD ON *.* TO '${MYSQL_MULADMIN_USER}'@'127.0.0.1' IDENTIFIED BY '${MYSQL_MULADMIN_PASS}'; FLUSH PRIVILEGES;"

    ## remove database 'test'
    #/usr/local/mysql/bin/mysql -uroot -p${MYSQL_ROOT_PASS} -e 'DROP DATABASE test;'

    ## mysql clone backup
    [ ! -d ${MYSQL_BACKUP_DIR} ] && mkdir -p ${MYSQL_BACKUP_DIR}
    chown -R mysql:mysql ${MYSQL_BACKUP_DIR}
    MYSQL_CLONE_PASS=$(pwgen 10 1)
    echo -e "\n## MySQL Clone User" >> /root/.my.cnf
    echo -e "# Username: mysql_clone" >> /root/.my.cnf
    echo -e "# Password: ${MYSQL_CLONE_PASS}" >> /root/.my.cnf
    /usr/local/mysql/bin/mysql -uroot -p${TMP_PASS} -e "CREATE USER mysql_clone@'localhost' IDENTIFIED by '${MYSQL_CLONE_PASS}';"
    /usr/local/mysql/bin/mysql -uroot -p${TMP_PASS} -e "GRANT BACKUP_ADMIN ON *.* TO 'mysql_clone'@'localhost';"
    install -m 0755 ${TOP_DIR}/conf/mysql/mysql_clone.sh /usr/local/bin/mysql_clone.sh
    sed -i "s#CLONE_PASS=.*#CLONE_PASS=${MYSQL_CLONE_PASS}#" /usr/local/bin/mysql_clone.sh
    sed -i "s#BACKUP_DIR=.*#BACKUP_DIR=${MYSQL_BACKUP_DIR}#" /usr/local/bin/mysql_clone.sh
    echo '' >> /var/spool/cron/crontabs/root
    echo '# MySQL Clone Backup' >> /var/spool/cron/crontabs/root
    echo '0 4 * * * /usr/local/bin/mysql_clone.sh > /dev/null 2>&1' >> /var/spool/cron/crontabs/root

    ## record installed tag
    echo 'MYSQL' >> ${INST_LOG}
else
    succ_msg "MySQL already installed!"
fi
