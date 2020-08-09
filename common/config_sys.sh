#!/bin/bash


## set hostname
if ! grep '^SET_HOSTNAME' ${INST_LOG} > /dev/null 2>&1 ;then
    if [ ! -z "${OS_HOSTNAME}" ];then
        OLD_HOSTNAME=$(hostname)
        hostnamectl set-hostname "${OS_HOSTNAME}" || fail_msg 'Set Hostname Error!'
        if [ -n "$(grep "$OLD_HOSTNAME" /etc/hosts)" ]; then
            sed -i "s/${OLD_HOSTNAME}//g" /etc/hosts
        fi
        sed -i "s/127\.0\.0\.1.*/127.0.0.1    ${OS_HOSTNAME} localhost/" /etc/hosts
        sed -i "s/127\.0\.1\.1.*/127.0.1.1    ${OS_HOSTNAME}.domain localhost.domain/" /etc/hosts
        ## log installed tag
        echo 'SET_HOSTNAME' >> ${INST_LOG}
    fi
fi


## set timezone
if ! grep '^SET_TIMEZONE' ${INST_LOG} > /dev/null 2>&1 ;then
    if [ ! -z "${TIMEZONE}" ];then
        timedatectl list-timezones | grep ${TIMEZONE}
        if [ $? -eq 1 ];then
            fail_msg 'Timezone name error! Check with <timedatectl list-timezones>'
        fi
        timedatectl set-timezone ${TIMEZONE} || fail_msg 'Set Timezone Error!'
        ## log installed tag                                                    
        echo 'SET_TIMEZONE' >> ${INST_LOG}
    fi
fi


## remove snapd
if ! grep '^RM_SNAP' ${INST_LOG} > /dev/null 2>&1 ;then
    snap remove --purge lxd
    snap remove --purge core18
    snap remove --purge snapd
    apt autoremove --purge -y snapd
    [ -d ~/snap ] && rm -rf ~/snap
    [ -d /root/snap ] && rm -rf /root/snap
    [ -d /snap ] && rm -rf /snap
    [ -d /var/snap ] && rm -rf /var/snap
    [ -d /var/lib/snapd ] && rm -rf /var/lib/snapd
    NEED_REBOOT=1
    ## log installed tag
    echo 'RM_SNAP' >> ${INST_LOG}
fi


## remove cloud-init
if ! grep '^RM_CLOUD-INIT' ${INST_LOG} > /dev/null 2>&1 ;then
    systemctl stop cloud-init
    systemctl disable cloud-init
    apt autoremove --purge -y cloud-init
    [ -d /etc/cloud ] && rm -rf /etc/cloud
    [ -d /var/lib/cloud ] && rm -rf /var/lib/cloud
    rm -rf /var/log/cloud-init*
    ## log installed tag
    echo 'RM_CLOUD-INIT' >> ${INST_LOG}
fi


## do not bell on tab-completion
if ! grep '^NO_BELL' ${INST_LOG} > /dev/null 2>&1 ;then
    if ! grep '# set bell-style none' /etc/inputrc > /dev/null 2>&1 ;then
        sed -i '1i\set bell-style none' /etc/inputrc
    else
        sed -i 's/^# set bell-style none/set bell-style none/g' /etc/inputrc
    fi
    NEED_REBOOT=1
    ## log installed tag
    echo 'NO_BELL' >> ${INST_LOG}
fi


## bashrc settings
if ! grep '^SET_BASHRC' ${INST_LOG} > /dev/null 2>&1 ;then
    if ! grep 'Moss bashrc' /etc/bash.bashrc > /dev/null 2>&1 ;then
        cat ${TOP_DIR}/conf/bash/bashrc >> /etc/bash.bashrc
    fi
    NEED_REBOOT=1
    ## log installed tag
    echo 'SET_BASHRC' >> ${INST_LOG}
fi


## vimrc settings
if ! grep '^SET_VIMRC' ${INST_LOG} > /dev/null 2>&1 ;then
    if ! grep 'Moss vimrc' /etc/vim/vimrc > /dev/null 2>&1 ;then
        cat ${TOP_DIR}/conf/vi/vimrc >> /etc/vim/vimrc
    fi
    ## log installed tag
    echo 'SET_VIMRC' >> ${INST_LOG}
fi


## disable cron mail
if ! grep '^CRON_MAIL' ${INST_LOG} > /dev/null 2>&1 ;then
    if ! grep 'MAILTO' /var/spool/cron/crontabs/root > /dev/null 2>&1 ;then
        echo 'MAILTO=""' >> /var/spool/cron/crontabs/root
    fi
    ## log installed tag
    echo 'CRON_MAIL' >> ${INST_LOG}
fi
    

## set root password
if ! grep '^SET_ROOT_PASSWORD' ${INST_LOG} > /dev/null 2>&1 ;then
    if [ ! -z "${OS_ROOT_PASSWD}" ];then
        echo "root:${OS_ROOT_PASSWD}" | chpasswd
        ## log installed tag
        echo 'SET_ROOT_PASSWORD' >> ${INST_LOG}
    fi
fi


## openssh
if ! grep '^OPENSSH' ${INST_LOG} > /dev/null 2>&1 ;then
    if [ ${SSH_PASS_AUTH} -eq 1 2>/dev/null ]; then
        sed -r -i 's/^#?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
    elif [ ${SSH_PASS_AUTH} -eq 0 2>/dev/null ]; then
        if [ ! -f ${TOP_DIR}/etc/rsa_public_keys/root.pub ]; then
            fail_msg "You must put root public key file(root.pub) into ${TOP_DIR}/etc/rsa_public_keys/root.pub"
        fi
        sed -r -i 's/^#?PasswordAuthentication.*/PasswordAuthentication no/g' /etc/ssh/sshd_config
    fi

    if [ ${SSH_ROOT_LOGIN} -eq 1 2>/dev/null ]; then
        sed -r -i 's/^#?PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
    elif [ ${SSH_ROOT_LOGIN} -eq 0 2>/dev/null ]; then
        sed -r -i 's/^#?PermitRootLogin.*/PermitRootLogin no/g' /etc/ssh/sshd_confi
    fi
    systemctl restart sshd.service
    ## log installed tag
    echo 'OPENSSH' >> ${INST_LOG}
fi


## profiles
if ! grep '^PROFILE' ${INST_LOG} > /dev/null 2>&1 ;then
    install -m 0644 ${TOP_DIR}/conf/profile/history.sh /etc/profile.d/history.sh
    install -m 0644 ${TOP_DIR}/conf/profile/path.sh /etc/profile.d/path.sh
    install -m 0644 ${TOP_DIR}/conf/profile/locale.sh /etc/profile.d/locale.sh
    NEED_REBOOT=1
    ## log installed tag
    echo 'PROFILE' >> ${INST_LOG}
fi


## sysctl
if ! grep '^SYSCTL' ${INST_LOG} > /dev/null 2>&1 ;then
    if ! grep 'Moss sysctl' /etc/sysctl.conf > /dev/null 2>&1 ;then
        cat ${TOP_DIR}/conf/sysctl/sysctl.conf >> /etc/sysctl.conf
        sysctl -p
        sysctl --system
    fi
    ## log installed tag
    echo 'SYSCTL' >> ${INST_LOG}
    NEED_REBOOT=1
fi


## disable ipv6
if ! grep 'IPv6_OFF' ${INST_LOG} > /dev/null 2>&1 ;then
    if [ ${DISABLE_IPV6} -eq 1 2>/dev/null ];then
        if ! grep 'Moss Disable IPv6' /etc/sysctl.conf > /dev/null 2>&1 ;then
            cat ${TOP_DIR}/conf/sysctl/no_ipv6.conf >> /etc/sysctl.conf
            sysctl -p
            sysctl --system

            if ! grep 'ipv6.disable=1' /etc/default/grub > /dev/null 2>&1 ;then
                if grep 'GRUB_CMDLINE_LINUX_DEFAULT=""' /etc/default/grub > /dev/null 2>&1 ;then
                    sed -r -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="ipv6.disable=1"/g' /etc/default/grub
                else
                    sed -r -i 's/(^GRUB_CMDLINE_LINUX_DEFAULT=.*)("$)/\1 ipv6.disable=1"/g' /etc/default/grub
                fi
            fi
            update-grub
            ## log installed tag
            echo 'IPv6_OFF' >> ${INST_LOG}
            NEED_REBOOT=1
        fi
    fi
fi


## enable bbr
if ! grep 'BBR_ON' ${INST_LOG} > /dev/null 2>&1 ;then
    if [ ${ENABLE_BBR} -eq 1 2>/dev/null ];then
        if ! grep 'Moss Enable BBR' /etc/sysctl.conf > /dev/null 2>&1 ;then
            cat ${TOP_DIR}/conf/sysctl/bbr.conf >> /etc/sysctl.conf
            sysctl -p
            sysctl --system
            ## log installed tag
            echo 'BBR_ON' >> ${INST_LOG}
            NEED_REBOOT=1
        fi
    fi
fi


## System Handler
if ! grep '^SYS_HANDLER' ${INST_LOG} > /dev/null 2>&1 ;then
    if ! grep 'Moss' /etc/security/limits.conf > /dev/null 2>&1 ;then
        cat ${TOP_DIR}/conf/os/limits.conf >> /etc/security/limits.conf
    fi
    sed -r -i 's/^#?DefaultLimitCORE.*/DefaultLimitCORE=100000/g' /etc/systemd/system.conf
    sed -r -i 's/^#?DefaultLimitNOFILE.*/DefaultLimitNOFILE=100000/g' /etc/systemd/system.conf
    ## log installed tag
    echo 'SYS_HANDLER' >> ${INST_LOG}
    NEED_REBOOT=1
fi


## systemd-timesyncd
if ! grep '^TIMESYNCD' ${INST_LOG} > /dev/null 2>&1 ;then
    mv -f /etc/systemd/timesyncd.conf /etc/systemd/timesyncd.conf.ori
    install -m 0644 ${TOP_DIR}/conf/timesyncd/timesyncd.conf /etc/systemd/timesyncd.conf
    systemctl restart systemd-timesyncd.service
    ## log installed tag
    echo 'TIMESYNCD' >> ${INST_LOG}
fi


## systemd-resolved
if ! grep '^RESOLVED' ${INST_LOG} > /dev/null 2>&1 ;then
    sed -r -i 's/^#?Cache=.*/Cache=no-negative/g' /etc/systemd/resolved.conf
    systemctl restart systemd-resolved.service
    ## log installed tag
    echo 'RESOLVED' >> ${INST_LOG}
fi


## system services
if ! grep '^SYS_SERVICE' ${INST_LOG} > /dev/null 2>&1 ;then
    for SVC_ON in atd.service cron.service dbus.service irqbalance.service networking.service networkd-dispatcher.service ssh.service sshd.service rsyslog.service systemd-resolved.service systemd-timesyncd.service;do
        systemctl enable ${SVC_ON} 2>/dev/null
        systemctl start ${SVC_ON} 2>/dev/null
    done
    ## log installed tag
    echo 'SYS_SERVICE' >> ${INST_LOG}
fi
