#!/bin/bash               

systemctl stop rsyslog.service
apt autoremove --purge -y
apt-get autoclean
apt-get clean
> /var/log/auth.log
> /var/log/dpkg.log
> /var/log/faillog.log
> /var/log/lastlog
> /var/log/syslog
> /var/log/tallylog
> /var/log/wtmp
rm -f /var/log/vmware-*.log
> /root/.bash_history
journalctl --vacuum-time=1s
journalctl --vacuum-size=1M
