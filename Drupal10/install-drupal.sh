#!/bin/bash

# Variables
domain="mydomain.com"
web_dir="/var/www/$domain"
sites_dir="/etc/apache2/sites-available"
sites_conf="$domain.conf"
apache_logs="/var/log/apache2"
root_mysql_pass="$(openssl rand -base64 12)"
drupal_sql_pass="$(openssl rand -base64 12)"
drupal_zip="/path/to/drupal-10.0.0.zip"

# Check if running as root
if [[ $(id -u) -ne 0 ]]; then
  echo "This script must be run as root."
  exit 1
fi

# Check if running on Ubuntu 22.04
if [[ $(lsb_release -rs) != "22.04" ]]; then
  echo "This script is designed to run on Ubuntu 22.04 only."
  exit 1
fi

# Install required packages
apt update
apt install -y apache2 php-{cli,fpm,json,common,mysql,zip,gd,intl,mbstring,curl,xml,pear,tidy,soap,bcmath,xmlrpc} openssl ufw unzip

# Configure firewall
ufw allow 80
ufw allow 443
ufw enable

# Secure MySQL installation
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$root_mysql_pass';
          DELETE FROM mysql.user WHERE User='';
          DROP USER IF EXISTS ''@'$(hostname)';
          DROP DATABASE IF EXISTS test;
          CREATE DATABASE drupal;
          CREATE USER 'drupal'@'localhost' IDENTIFIED BY '$drupal_sql_pass';
          GRANT ALL ON drupal.* TO 'drupal'@'localhost';
          FLUSH PRIVILEGES;"

# Create virtual host file
cat <<EOF > "$sites_dir/$sites_conf"
<VirtualHost *:80 *:443>
     ServerName $domain
     ServerAlias www.$domain 
     ServerAdmin help@$domain
     DocumentRoot $web_dir
     ErrorLog $apache_logs/error.log
     CustomLog $apache_logs/access.log combined
     <Directory $web_dir>
         Options Indexes FollowSymLinks
         AllowOverride All
         Require all granted
         RewriteEngine on
         RewriteBase /
         RewriteCond %{REQUEST_FILENAME} !-f
         RewriteCond %{REQUEST_FILENAME} !-d
         RewriteRule ^(.*)$ index.php?q=\$1 [L,QSA]
    </Directory>
 </VirtualHost>
EOF

# Enable virtual host and modules, disable default site and event module
a2ensite $domain
a2dissite 000-default
a2dismod mpm_event
a2enmod mpm_prefork
a2enmod php$(php -v | grep -oP "PHP \K[0-9]+\.[0-9]+")
a2enmod rewrite
apache2ctl configtest
systemctl reload apache2

# Create web directory and install Drupal
mkdir -p "$web_dir"
chown -R www-data:www-data "$web_dir"
chmod -R 755 "$web_dir"
unzip -q "$drupal_zip" -d "$web_dir"
touch "$web_dir/sites/default/settings.php"
chmod 666 "$web_dir/sites/default/settings.php"
mkdir -p "$web_dir/sites/default/files"
chmod 777 "$web_dir/sites/default/files"

# Install Composer and Drush
apt install -y composer
composer global require drush/drush
echo "Passwords:"
echo "Root MySQL password: $root_mysql_pass"
echo "Drupal SQL password: $drupal_sql_pass"

