#!/bin/bash

domain="mydomain.com"

date=$(date)
log_file=/var/log/install-drupal10.log
web_dir="/var/www/$domain"
sites_dir="/etc/apache2/sites-available"
sites_file="$domain.conf"
apache_logs="/var/log/apache2"
root_mysql_pass="$(openssl rand -base64 12)"
drupal_sql_pass="$(openssl rand -base64 12)"
drupal_download="https://ftp.drupal.org/files/projects/drupal-10.0.0.zip"
drupal_zip="/tmp/drupal-10.0.0.zip"

check_output() {
    if [ "$1" -eq 0 ]; then
        echo "SUCCESS: $1 - $2 "
        echo "SUCCESS: $1 - $2 " >> $log_file
        return 0
    else
        echo "ERROR: $1 PLEASE CHECK LOGFILE - $2"
        echo "ERROR: $1 - $2" >> $log_file
        sed -i "s/$root_mysql_pass/PasswordNotStoredInLogfile/g" $log_file
        sed -i "s/$drupal_sql_pass/PasswordNotStoredInLogfile/g" $log_file
        exit
    fi
}

install_reqs() {
  # Install required packages
  apt update && 
  apt upgrade -y &&
  apt install -y wget apache2 php-{cli,fpm,json,common,mysql,zip,gd,intl,mbstring,curl,xml,pear,tidy,soap,bcmath,xmlrpc} openssl ufw unzip composer &&
  composer global require drush/drush
}

create_configs() {
    mkdir -v $web_dir &&
    touch $web_dir/index.html &&
    cat <<EOF > $web_dir/index.html
<meta http-equiv="refresh" content="1; URL=https://www.$domain/" />
EOF
# Create virtual host file
  cat <<EOF > "$sites_dir/$sites_file"
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
}

finalize_apache() {
  # Enable virtual host and modules, disable default site and event module
  a2ensite $domain &&
  a2dissite 000-default &&
  a2dismod mpm_event &&
  a2enmod mpm_prefork &&
  a2enmod php$(php -v | grep -oP "PHP \K[0-9]+\.[0-9]+") &&
  a2enmod rewrite &&
  apache2ctl configtest &&
  systemctl reload apache2
}

config_firewall() {
  # Configure firewall
  ufw allow 80 &&
  ufw allow 443 &&
  #ufw allow 22 &&
  ufw enable
}

config_mysql() {
  mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$root_mysql_pass';
            DELETE FROM mysql.user WHERE User='';
            DROP USER IF EXISTS ''@'$(hostname)';
            DROP DATABASE IF EXISTS test;
            CREATE DATABASE drupal;
            CREATE USER 'drupal'@'localhost' IDENTIFIED BY '$drupal_sql_pass';
            GRANT ALL ON drupal.* TO 'drupal'@'localhost';
            FLUSH PRIVILEGES;"
}

install_drupal() {
  mkdir -p "$web_dir" &&
  chown -R www-data:www-data "$web_dir" &&
  chmod -R 755 "$web_dir" &&
  wget $drupal_download -O $drupal_zip &&
  unzip -q "$drupal_zip" -d "$web_dir" &&
  touch "$web_dir/sites/default/settings.php" &&
  chmod 666 "$web_dir/sites/default/settings.php" &&
  mkdir -p "$web_dir/sites/default/files" &&
  chmod 777 "$web_dir/sites/default/files"
}

echo "SUCCESS: RUN $date " >> $log_file

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  echo "ERROR: ADMIN PRIVILEGES" >> $log_file
  exit 1
fi

if [[ $(lsb_release -rs) != "22.04" ]];
  then echo "This script is designed to run on Ubuntu 22.04 only."
  echo "ERROR: WRONG OS/VERSION" >> $log_file
  exit 1
fi

echo "Installing LAMP Server..."

install_reqs >> $log_file 2>&1
check_output $? "INSTALLING APT REQUIREMENTS"

config_firewall >> $log_file 2>&1
check_output $? "CONFIGURING FIREWALL"

create_configs >> $log_file 2>&1
check_output $? "CREATING CONFIGURATION FILES FOR APACHE"

finalize_apache >> $log_file 2>&1
check_output $? "FINALIZING CHANGES TO APACHE"

config_mysql >> $log_file 2>&1
check_output $? "CONFIGURING SECURE MYSQL SETUP"

sed -i "s/$mysql_pass/PasswordNotStoredInLogfile/g" $log_file
check_output $? "REMOVING MYSQL PASSWORD FROM LOG FILE"

sed -i "s/$drupal_sql_pass/PasswordNotStoredInLogfile/g" $log_file
check_output $? "REMOVING DRUPAL PASSWORD FROM LOG FILE"

install_drupal >> $log_file 2>&1
check_output $? "INSTALLING DRUPAL 10"

echo "YOUR MYSQL PASSWORD IS: $mysql_pass"
echo "YOUR DRUPAL MYSQL PASSWORD IS: $drupal_sql_pass"
