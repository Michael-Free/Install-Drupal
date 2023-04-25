#!/bin/bash

# Variables
domain="mydomain.com"

drupal_temp=/tmp/drupal_tmp/
drupal_backup=/path/to/drupal_backup.zip
drupal_root=/var/www/$domain

db_name="drupal"
db_pass=""

log_file=/var/log/migrate-drupal.log

check_output() {
    if [ "$1" -eq 0 ]; then
        echo "SUCCESS: $1 - $2 " >> $log_file
        return 0
    else
        echo "ERROR: $1 PLEASE CHECK LOGFILE - $2"
        echo "ERROR: $1 - $2" >> $log_file
        sed -i "s/$db_pass/PasswordNotStoredInLogfile/g" $log_file
        exit 1
    fi
}

# Check if running as root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  echo "ERROR: ADMIN PRIVILEGES" >> $log_file
  exit 1
fi

# Check if rsync, zip, and unzip are installed
if ! command -v rsync &> /dev/null || ! command -v zip &> /dev/null || ! command -v unzip &> /dev/null; then
    echo "ERROR: rsync, zip, and/or unzip are not installed. Please install them and try again." 
    echo "ERROR: rsync, zip, and/or unzip are not installed. Please install them and try again." >> $log_file
    exit 1
fi

# Check if the backup file exists
if [ ! -f $drupal_backup ]; then
    echo "ERROR: backup file $drupal_backup not found."
    echo "ERROR: backup file $drupal_backup not found." >> $log_file
    exit 1
fi

# Unzip the backup file
unzip -q $drupal_backup -d $drupal_temp
check_output $? "Unzipping Drupal backup." >> $log_file

# Copy the Drupal 9 files to the Drupal 10 root directory
rsync -avz --exclude 'sites/default/settings.php' $drupal_temp/files/ $drupal_root/sites/default/files/
check_output $? "Rsyncing apache sites directory..." >> $log_file

# Copy the Drupal 9 files to the Drupal 10 root directory
rsync -avz --exclude '.htaccess' --exclude 'sites/default/files' $drupal_temp/ $drupal_root/
check_output $? "Rsyncing drupal root directory..." >> $log_file

# Check if the files copy was successful
if [ $? -ne 0 ]; then
    echo "Error: failed to copy the Drupal 9 files to the Drupal 10 root directory."
    exit 1
fi

## Create a new Drupal 10 database and user
#mysql -u root -p <<EOF
#CREATE DATABASE drupal10;
#CREATE USER 'drupal10'@'localhost' IDENTIFIED BY '$db_pass';
#GRANT ALL PRIVILEGES ON drupal10.* TO 'drupal10'@'localhost';
#FLUSH PRIVILEGES;
#EOF
##check_output

# Check if the database creation was successful
#if [ $? -ne 0 ]; then
#    echo "Error: failed to create the Drupal 10 database and user."
#    exit 1
#fi

# Import the Drupal 9 database into the Drupal 10 database
mysql -u root -p $db_name < $drupal_temp/drupal9.sql
check_output $? "Importing Drupal SQL DB"

## Update the Drupal 10 settings.php file with the new database credentials
#sed -i "s/'database' => 'drupal9'/'database' => 'drupal10'/g" $drupal_root/sites/default/settings.php
#sed -i "s/'username' => 'drupal9'/'username' => 'drupal10'/g" $drupal_root/sites/default/settings.php
#sed -i "s/'password' => 'drupal9'/'password' => '$db_pass'/g" $drupal_root/sites/default/settings.php

## Check if the settings.php update was successful
#if [ $? -ne 0 ]; then
#    echo "Error: failed to update the Drupal 10 settings.php file with the new database credentials."
#    exit 1
#fi

echo "Drupal 9 migration to Drupal 10 completed successfully."

