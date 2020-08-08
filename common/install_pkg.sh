#!/bin/bash


## clean
apt-get clean
apt-get autoclean

## change atp source
if ! grep '^CH_APT' ${INST_LOG} > /dev/null 2>&1 ;then
    if [ ${CHANGE_APT} -eq 1 2>/dev/null ]; then
        mv /etc/apt/sources.list /etc/apt/sources.list.ori
        install -m 0644 ${TOP_DIR}/conf/apt/sources.list.moss /etc/apt/sources.list
        apt autoclean
        ## log installed tag
        echo 'CH_APT' >> ${INST_LOG}
    fi
fi

## update system
if ! grep '^APT_UPDATE' ${INST_LOG} > /dev/null 2>&1 ;then
    apt update -y || fail_msg "APT Update Failed!"
    apt upgrade -y || fail_msg "APT Upgrade Failed!"
    apt autoremove --purge -y
    ## log installed tag
    echo 'APT_UPDATE' >> ${INST_LOG}
    NEED_REBOOT=1
fi

## install PKGs
if ! grep '^PKG_INSTALL' ${INST_LOG} > /dev/null 2>&1 ;then
    PKGS=$(cat ${TOP_DIR}/conf/apt/pkgs.list)
    apt install -y ${PKGS} || fail_msg "Install Package(s) Failed!"
    ## log installed tag
    echo 'PKG_INSTALL' >> ${INST_LOG}
fi
