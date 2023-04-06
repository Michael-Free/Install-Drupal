#!/bin/bash

# Variables
SITE_DIR="/var/www/mydomain.com"
BACKUP_DIR="/var/backup"
DATE=$(date +%Y-%m-%d-%H%M%S)
DB_USER="root"
DB_PASS="your_mysql_password_here"
DB_NAME="mydatabase"

# Create backup directory if it doesn't exist
if [ ! -d "$BACKUP_DIR" ]; then
  mkdir "$BACKUP_DIR"
fi

# Backup database
mysqldump -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$BACKUP_DIR/$DATE-db.sql"

# Backup website files
cd "$SITE_DIR" && zip -r "$BACKUP_DIR/$DATE-site.zip" .

# Zip the backup files
cd "$BACKUP_DIR" && zip -r "$DATE-backup.zip" .

# Remove temporary files
rm "$BACKUP_DIR/$DATE-db.sql" "$BACKUP_DIR/$DATE-site.zip"

# Print message to console
echo "Backup completed and stored in $BACKUP_DIR/$DATE-backup.zip"

