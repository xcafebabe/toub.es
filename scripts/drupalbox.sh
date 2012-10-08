#!/bin/bash

################################################################################
#      Copyright (C) 2012 Luis Toubes(luis@toub.es)
#
#  This Program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2, or (at your option)
#  any later version.
#
#  This Program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this script. If not,  see <http://www.gnu.org/licenses/>.
################################################################################


# This script will install & setup last Drupal Version.
# Ready to go for Ubuntu Distributions.

# STEP 1 - Setup Info
# User who has write access to install Drupal 
USER_LINUX=vagrant

# Group of your Apache Server.
GROUP=www-data

# Root Folder where Drupal should be installed
ROOT_DIR=/home/vagrant/www

# Folder where Drupal should be installed
DRUPAL_DIR=drupal

# User with Admin Privileges to Mysql
USER_ADMIN_MYSQL=root

# New User / Password for Drupal Database 
USER_DRUPAL_MYSQL=drupal4fun 
PASS_DRUPAL_MYSQL=cool@password 

# New Druºpal Database
DB_DRUPAL_MYSQL=drupal_dev

# Admin User for Drupal Website
USER_DRUPAL=guruji
PASS_DRUPAL=2012@06@18

# Admin User Email
MAIL_DRUPAL=love@artofliving.org

# Sitename Drupal
SITENAME_DRUPAL="My Cool Drupal 7 Site"

### END DEFAULT PROPERTIES

### ASKING FOR CUSTOM PROPERTIES
echo "This Script needs some info to behave. Stay calm and enter required info OR hit  ENTER to use default values."
read -p "(1/12) - Enter a Linux User [${USER_LINUX}]: " input
USER_LINUX=${input:-${USER_LINUX}}

read -p "(2/12) - Enter group for apache [${GROUP}]: " input
GROUP=${input:-${GROUP}}

read -p "(3/12) - Enter Mysql user with super powers [${USER_ADMIN_MYSQL}]: " input
USER_ADMIN_MYSQL=${input:-${USER_ADMIN_MYSQL}}

read -p "(4/12) - Enter the name of your new Drupal Database (It will be created) [${DB_DRUPAL_MYSQL}]: " input
DB_DRUPAL_MYSQL=${input:-${DB_DRUPAL_MYSQL}}

read -p "(5/12) - Enter a new mysql user for database '${DB_DRUPAL_MYSQL}' [$USER_DRUPAL_MYSQL]: " input
USER_DRUPAL_MYSQL=${input:-${USER_DRUPAL_MYSQL}}

read -p "(6/12) - Enter a new mysql password for '$USER_DRUPAL_MYSQL'  [$PASS_DRUPAL_MYSQL]: " input
PASS_DRUPAL_MYSQL=${input:-${PASS_DRUPAL_MYSQL}}

read -p "(7/12) - Absolute root path for your Drupal installation [${ROOT_DIR}]: " input
ROOT_DIR=${input:-${ROOT_DIR}}

read -p "(8/12) - Relative folder where Drupal should be installed [${DRUPAL_DIR}]: " input
DRUPAL_DIR=${input:-${DRUPAL_DIR}}

read -p "(9/12) - Enter your Drupal Admin User [${USER_DRUPAL}]: " input
USER_DRUPAL=${input:-${USER_DRUPAL}}

read -p "(10/12) - Enter password for '${USER_DRUPAL}' [${PASS_DRUPAL}]: " input
PASS_DRUPAL=${input:-${PASS_DRUPAL}}

read -p "(11/12) - Enter mail for '${USER_DRUPAL}' [${MAIL_DRUPAL}]: " input
MAIL_DRUPAL=${input:-${MAIL_DRUPAL}}

read -p "(12/12) - Enter you new Drupal SiteName [${SITENAME_DRUPAL}]: " input
SITENAME_DRUPAL=${input:-${SITENAME_DRUPAL}}
echo "GO GO GO!!!"
# LET'S GO
# Updating system
# STEP 2
sudo apt-get update

echo '******DRUSH INSTALLATION******'
sudo sh -c "apt-get -y install php-pear ; pear upgrade ; pear channel-discover pear.drush.org ; pear install drush/drush ; drush version ; rm -rf ~/.drush;"
echo 'OK'

echo '******APACHE INSTALLATION******'
sudo sh -c "apt-get -y install apache2 ; service apache2 stop ; a2enmod vhost-alias ; a2enmod alias ; a2enmod rewrite ; a2dismod cgi ; a2dismod autoindex; service apache2 start"
echo 'OK'

echo '******MYSQL INSTALLATION******'
sudo sh -c "apt-get -y install mysql-server mysql-client phpmyadmin"
sudo sh -c "cp /etc/phpmyadmin/apache.conf /etc/apache2/conf.d/phpmyadmin.conf"
echo 'OK'

echo '******PHP INSTALLATION******'
sudo sh -c "apt-get -y install curl libapache2-mod-php5 php5-cli php5-common php5-curl php5-dev php5-gd php5-mcrypt php5-mysql php5-sqlite php5-xdebug php5-xsl php-apc php-pear"
echo 'OK'

# STEP 3
echo '******DRUPAL DATABASE INSTALLATION ******'
echo "******ENTER PASSWORD FOR MYSQL ADMIN USER '${USER_ADMIN_MYSQL}' ******"
mysql --user=${USER_ADMIN_MYSQL} --password --execute="CREATE DATABASE ${DB_DRUPAL_MYSQL}; GRANT ALL PRIVILEGES ON ${DB_DRUPAL_MYSQL}.* TO ${USER_DRUPAL_MYSQL}@localhost IDENTIFIED BY '${PASS_DRUPAL_MYSQL}'; FLUSH PRIVILEGES;"
echo 'OK'

# STEP 4
echo '******DRUPAL SETUP******'
sudo usermod -a -G ${GROUP}  ${USER}
sudo sh -c "mkdir -p ${ROOT_DIR};  chmod 775 ${ROOT_DIR}; chown ${USER}:${GROUP} ${ROOT_DIR}; chmod g+s ${ROOT_DIR}"
# FIX POSSIBLE PROBLEM WITH PHP WARNING
sudo mv /etc/php5/apache2/conf.d/sqlite.ini /etc/php5/apache2/conf.d/sqlite.ini.disable

# STEP 5
drush --verbose --drupal-project-rename=${DRUPAL_DIR} --destination=${ROOT_DIR} dl drupal
sudo chmod g+s ${ROOT_DIR}/${DRUPAL_DIR}
echo 'OK'

# STEP 6
echo '******APACHE SETUP******'
sudo sh -c "cat >/etc/apache2/sites-available/drupal.site <<EOL
<VirtualHost *:80>
  DocumentRoot ${ROOT_DIR}/${DRUPAL_DIR}
  ServerName localhost
  RewriteEngine On
  RewriteOptions inherit
  CustomLog /var/log/apache2/${DRUPAL_DIR}.log combined
  <Directory ${ROOT_DIR}/${DRUPAL_DIR}>
    Options +FollowSymLinks Indexes
    AllowOverride All
    Order allow,deny
    Allow from all
  </Directory>
</VirtualHost>
EOL"

sudo sh -c "a2ensite drupal.site ; a2dissite default ; service apache2 restart"
echo 'OK'

# STEP 7
echo '******DRUPAL INSTALLATION******'
drush --root=${ROOT_DIR}/${DRUPAL_DIR} --uri=http://localhost site-install standard --db-url=mysql://${USER_DRUPAL_MYSQL}:${PASS_DRUPAL_MYSQL}@localhost/${DB_DRUPAL_MYSQL} --account-name=${USER_DRUPAL} --account-pass=${PASS_DRUPAL} --account-mail=${MAIL_DRUPAL} --site-mail=${MAIL_DRUPAL} --site-name='My Cool Drupal 7 Site'

sudo sh -c "chown -R ${USER}:${GROUP} ${ROOT_DIR}/${DRUPAL_DIR}/sites/default/files ; chmod g+s ${ROOT_DIR}/${DRUPAL_DIR}/sites/default/files"
echo 'OK'
echo 'FINISH. Open browser and go to http://localhost'
