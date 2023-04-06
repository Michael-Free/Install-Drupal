#!/bin/bash

domain=your.domain.com

date=$(date)
log_file=/var/log/install-drupal.log
web_dir=/var/www/$domain
sites_dir=/etc/apache2/sites-available
sites_file=$domain.conf
apache_logs=/var/log/apache2
mysql_pass=$(date +%s | sha256sum | base64 | head -c 32 ;)
drupal_download=https://www.drupal.org/download-latest/tar.gz
drupal_tar=/tmp/drupal.tar.gz

check_output () {
    if [ $1 -eq 0 ]; then
        echo "SUCCESS: $1 - $2 " >> $log_file
        return 0
    else
        echo "ERROR: $1 PLEASE CHECK LOGFILE - $2"
        echo "ERROR: $1 - $2" >> $log_file
        sed -i "s/$mysql_pass/PasswordNotStoredInLogfile/g" $log_file
        sed -i "s/$drupal_sql_pass/PasswordNotStoredInLogfile/g" $log_file
        exit
    fi
}

install_reqs () {
    apt install wget apache2 mysql-server php libapache2-mod-php php-{cli,fpm,json,common,mysql,zip,gd,intl,mbstring,curl,xml,pear,tidy,soap,bcmath,xmlrpc} ufw -y
}

create_configs() {
    mkdir -v $web_dir &&
    touch $web_dir/index.html &&
    cat <<EOF > $web_dir/index.html
<meta http-equiv="refresh" content="1; URL=https://www.$domain/" />
EOF
    cat $web_dir/index.html
    touch $sites_dir/$sites_file &&
    cat <<EOF > $sites_dir/$sites_file
<VirtualHost *:80 *:443>
    ServerName $domain
    ServerAlias www.$domain 
    ServerAdmin help@$domain
    DocumentRoot $web_dir
    ErrorLog $apache_logs/error.log
    CustomLog $apache_logs/access.log combined
    <Directory $sites_dir>
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
    cat $sites_dir/$sites_file
}

finalize_apache() {
    a2ensite $domain &&
    a2dissite 000-default &&
    a2dismod mpm_event &&
    a2enmod mpm_prefork &&
    a2enmod php7.4 &&
    a2enmod rewrite &&
    apache2ctl configtest &&  
    systemctl reload apache2
}

config_firewall() {
    ufw allow http &&
    ufw allow https &&
    ufw allow OpenSSH &&
    ufw enable
}

config_mysql() {
    drupal_sql_pass=$(date +%s | sha256sum | base64 | head -c 32 ;)
    mysql -v << EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '$mysql_pass';
DELETE FROM mysql.user WHERE User='';
DROP USER IF EXISTS ''@'$(hostname)';
DROP DATABASE IF EXISTS test;
CREATE DATABASE drupal;
CREATE USER 'drupal'@'localhost' IDENTIFIED BY '$drupal_sql_pass';
GRANT ALL ON drupal.* TO 'drupal'@'localhost';
FLUSH PRIVILEGES;
EOF
}

install_drupal() {
    chown -R www-data:www-data $web_dir &&
    chown -R 755 $web_dir &&
    wget $drupal_download -O $drupal_tar &&
    tar -xf $drupal_tar &&
    mv -v $(tar -tf $drupal_tar | grep -o '^[^/]\+' | sort -u)/* $web_dir &&
    touch $web_dir/sites/default/settings.php &&
    chmod 666 $web_dir/sites/default/settings.php
    mkdir $web_dir/sites/default/files &&
    chmod 777 $web_dir/sites/default/files
}

echo "SUCCESS: RUN $date " >> $log_file

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  echo "ERROR: ADMIN PRIVILEGES" >> $log_file
  exit
fi

echo "Installing LAMP Server"
echo
echo "Installing software requirements via APT..."
install_reqs >> $log_file 2>&1
check_output $? "INSTALLING APT REQUIREMENTS"
echo
echo "Configuring firewall.."
config_firewall >> $log_file 2>&1
echo
echo "Creating configuration files for Apache Webserver..."
create_configs >> $log_file
check_output $? "CREATING CONFIGURATION FILES FOR APACHE"
echo
echo "Finalizing changes to Apache Webserver..."
finalize_apache >> $log_file 2>&1
check_output $? "FINALIZING CHANGES TO APACHE"
echo
echo "Going through MySQL secure setup..."
config_mysql >> $log_file 2>&1
check_output $? "CONFIGURING SECURE MYSQL SETUP"
sed -i "s/$mysql_pass/PasswordNotStoredInLogfile/g" $log_file
sed -i "s/$drupal_sql_pass/PasswordNotStoredInLogfile/g" $log_file
echo
echo "Installing Drupal 9..."
install_drupal >> $log_file 2>&1
check_output $? "INSTALLING DRUPAL 9"
echo "YOUR MYSQL PASSWORD IS: $mysql_pass"
echo "YOUR DRUPAL MYSQL PASSWORD IS: $drupal_sql_pass"
