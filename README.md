# Moss20.04

Moss20.04 is an automatic services environment deploy system for Ubuntu 20.04.

You could set up a production environment easily by Moss20.04. Inlcude all features below:

* **Optimize** - Automatic optimize Ubuntu 20.04 system. Change to faster apt repository mirror, optimize kernel TCP settings, vi improved, SSH optimize...;
* **Security** - Turn off useless services, disable SSH password authentication;
* **Services** - Automatic install Nginx/PHP FastCGI/PECL modules(Redis)/MySQL/Percona Xtrabackup/Redis/Zabbix Agent...;
* **Performance** - All serives were set to optimized settings, you could use it in production environment directly;
* **Maintenance** - User configure file support. Automatic set up database backup policy, logs rotate policy and all service were added to systemd;
* **Develop** - You could develop Moss20.04  easily. All features in Moss20.04 were designed by modules, you can add or remove modules to fit your need;

## Install
* Configure: Edit configuration file in ```./etc/moss.conf```. Change settings to fit your need.
* Package Repository: Moss20.04 support both download packages from a repository and get from local directory(```./src```). Set in ```./etc/moss.conf```
* Install: Login with root and run ```./install ```

## Uninstall
* Login with root and run ```./install``` select 'u';
* Uninstall services only. All settings done by Moss20.04 will be kept;
