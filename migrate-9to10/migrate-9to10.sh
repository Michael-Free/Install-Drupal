#!/bin/bash

# Variables
DRUPAL9_BACKUP=drupal9_backup.zip
DRUPAL10_ROOT=/var/www/mydomain.com
DRUPAL10_SQL_PASS=random_password
log_file=/var/log/migrate-drupal.log

check_output () {
    if [ "$1" -eq 0 ]; then
        echo "SUCCESS: $1 - $2 " >> $log_file
        return 0
    else
        echo "ERROR: $1 PLEASE CHECK LOGFILE - $2"
        echo "ERROR: $1 - $2" >> $log_file
        sed -i "s/$DB_PASS/PasswordNotStoredInLogfile/g" $log_file
        exit 1
    fi
}

# unset password
# prompt="Enter Password:"
# while IFS= read -p "$prompt" -r -s -n 1 char
# do
#     if [[ $char == $'\0' ]]
#     then
#         break
#     fi
#     prompt='*'
#     password+="$char"
# done
# echo
# echo "Done. Password=$password"

copy_files () {
    echo "placeholder"
}

import_database () {
    echo "placeholdeR"
}

update_settings () {
    echo "placeholder"
}

check_settings () {
    echo "placeholdeR"
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
if [ ! -f $DRUPAL9_BACKUP ]; then
    echo "ERROR: backup file $DRUPAL9_BACKUP not found."
    echo "ERROR: backup file $DRUPAL9_BACKUP not found." >> $log_file
    exit 1
fi

# Unzip the backup file
unzip -q $DRUPAL9_BACKUP -d drupal9_backup
## checkoutput


# Check if the unzip was successful
#if [ $? -ne 0 ]; then
#    echo "Error: failed to unzip the backup file."
#    exit 1
#fi

# Copy the Drupal 9 files to the Drupal 10 root directory
rsync -avz --exclude 'sites/default/settings.php' drupal9_backup/files/ $DRUPAL10_ROOT/sites/default/files/
rsync -avz --exclude '.htaccess' --exclude 'sites/default/files' drupal9_backup/ $DRUPAL10_ROOT/
#check_output

# Check if the files copy was successful
if [ $? -ne 0 ]; then
    echo "Error: failed to copy the Drupal 9 files to the Drupal 10 root directory."
    exit 1
fi

# Create a new Drupal 10 database and user
mysql -u root -p <<EOF
CREATE DATABASE drupal10;
CREATE USER 'drupal10'@'localhost' IDENTIFIED BY '$DRUPAL10_SQL_PASS';
GRANT ALL PRIVILEGES ON drupal10.* TO 'drupal10'@'localhost';
FLUSH PRIVILEGES;
EOF
#check_output

# Check if the database creation was successful
#if [ $? -ne 0 ]; then
#    echo "Error: failed to create the Drupal 10 database and user."
#    exit 1
#fi

# Import the Drupal 9 database into the Drupal 10 database
mysql -u root -p drupal10 < drupal9_backup/drupal9.sql
#check_output
# Check if the database import was successful
#if [ $? -ne 0 ]; then
#    echo "Error: failed to import the Drupal 9 database into the Drupal 10 database."
#    exit 1
#fi

# Update the Drupal 10 settings.php file with the new database credentials
sed -i "s/'database' => 'drupal9'/'database' => 'drupal10'/g" $DRUPAL10_ROOT/sites/default/settings.php
sed -i "s/'username' => 'drupal9'/'username' => 'drupal10'/g" $DRUPAL10_ROOT/sites/default/settings.php
sed -i "s/'password' => 'drupal9'/'password' => '$DRUPAL10_SQL_PASS'/g" $DRUPAL10_ROOT/sites/default/settings.php

# Check if the settings.php update was successful
if [ $? -ne 0 ]; then
    echo "Error: failed to update the Drupal 10 settings.php file with the new database credentials."
    exit 1
fi

echo "Drupal 9 migration to Drupal 10 completed successfully."

