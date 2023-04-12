#!/bin/bash

# Variables
SITE_DIR="/var/www/mydomain.com"
BACKUP_DIR="/var/backup"
DATE=$(date +%Y-%m-%d-%H%M%S)
DB_USER="root"
DB_PASS="your_mysql_password_here"
DB_NAME="mydatabase"
log_file="/var/log/backup-drupal.log"

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

# Create backup directory if it doesn't exist
if [ ! -d "$BACKUP_DIR" ]; then
  mkdir "$BACKUP_DIR"
  check_output $? "Creating backup directory."
fi

# Backup database
mysqldump -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$BACKUP_DIR/$DATE-db.sql"
check_output $? "Backing up sql data base"

# Backup website files
cd "$SITE_DIR" && zip -r "$BACKUP_DIR/$DATE-site.zip" .
check_output $? "Backing up website files"

# Zip the backup files
cd "$BACKUP_DIR" && zip -r "$DATE-backup.zip" .
check_output $? "zipping the backup files"

# Remove temporary files
rm "$BACKUP_DIR/$DATE-db.sql" "$BACKUP_DIR/$DATE-site.zip"
check_output $? "Removing temporary files"

# Print message to console
echo "Backup completed and stored in $BACKUP_DIR/$DATE-backup.zip"

