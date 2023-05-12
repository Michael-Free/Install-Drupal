#!/bin/bash

# Variables
domain="mydomain.com"
site_dir="/var/www/$domain"
backup_dir="/var/backup"
current_date=$(date +%Y-%m-%d-%H%M%S)
log_file="/var/log/backup-drupal.log"
sites_available="/etc/apache2/sites-available/$domain.conf"
# Array of certs to back up ("/path/to/cert1" "/path/to/cert2")
certs_directory=("/etc/ssl/certs/ssl_certificate.crt" "/etc/ssl/private/server.key" "/etc/ssl/certs/IntermediateCA.crt")
db_user="root"
# Array of DB Names ("Database1" "Database2")
db_names=("drupal")

check_output () {
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

# Check Administration Privs
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  echo "ERROR: ADMIN PRIVILEGES" >> $log_file
  exit 1
fi

# Create backup directory if it doesn't exist
if [ ! -d "$backup_dir" ]; then
  mkdir "$backup_dir"
  check_output $? "Creating backup directory."
fi

read -rsp "SQL Password: " db_pass

# Loop through each database name
for db_name in "${db_names[@]}"
do
  # Perform a SQL database dump of each DB
  mysqldump -u "$db_user" -p"$db_pass" "$db_name" > "$backup_dir/$current_date-$db_name-db.sql"
  check_output $? "Backing up SQL database: $db_name"
done

# Backup website files
cd "$site_dir" &&
tar czf "$backup_dir/$current_date-site.tar.gz" .
check_output $? "Backing up website files"

# Change to backup directory
cd "$backup_dir" &&

# Backup Certs
for cert in "${certs_directory[@]}"
do
  # Copy each cert to the backup directory
  cp "${cert}" .
  check_output $? "Copying ${cert}"
done

# Backup sites-available
cp "${sites_available}" .

# Get an array of all files in the directory
backup_files=(*)

# Loop through each file in the array and write it on one line
for file in "${backup_files[@]}"
do
  echo "${file}"
# Pipe out the output to a tar command
done | tar -czvf "$current_date-backup.tar.gz" -T -
check_output $? "Tarring the backup files"

# Remove temporary files
for file in "${backup_files[@]}"
do
  rm -vf "${file}"
  check_output $? "Removing temporary file - ${file}"
done

# Print message to console
echo "Backup completed and stored in $backup_dir/$current_date-backup.tar.gz"
