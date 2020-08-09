#!/bin/bash

CLONE_USER='mysql_clone'
CLONE_PASS=''
MY_CNF='/etc/my.cnf'

DATE=$(date +%Y%m%d)

BACKUP_DIR=/data/backup/mysql
CLONE_PREFIX='clone'
CLONE_DIR=${BACKUP_DIR}/${CLONE_PREFIX}-${DATE}

[ ! -d ${BACKUP_DIR} ] && mkdir -p ${BACKUP_DIR}

# Full Clone
MYSQL_PWD=${CLONE_PASS} /usr/local/mysql/bin/mysql -u${CLONE_USER} -e "CLONE LOCAL DATA DIRECTORY = '${CLONE_DIR}'"
unset MYSQL_PWD

[ -f ${MY_CNF} ] && cp -p ${MY_CNF} ${CLONE_DIR}/my.cnf.clone_backup

# Compress
cd ${BACKUP_DIR} && tar czf ${CLONE_PREFIX}-${DATE}.tar.gz ${CLONE_PREFIX}-${DATE} && rm -rf ${CLONE_PREFIX}-${DATE}

# Delete backup over 7 days
find ${BACKUP_DIR} -name "*.gz" -mtime +6 | xargs rm -rf
