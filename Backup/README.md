# Backup Drupal

This is a shell script that can be used to backup a Drupal website's files and database.
Prerequisites

## Requirements

To run this script, you must have the following:

- A Linux or Unix-like operating system with Bash installed
- Root privileges to run the script
- A Drupal website with a MySQL database
- Access to the website's server via SSH

## Instructions

1. Download the script and place it on the server where your Drupal website is hosted.
2. Open the script in a text editor.
3. Modify the following variables according to your website's configuration:
    - **domain**: The domain name of your website
    - **site_dir**: The directory where your website's files are stored
    - **backup_dir**: The directory where you want to store the backup files
    - **db_user**: The username of the MySQL user with access to your website's database
    - **db_name**: The name of your website's database
    - **log_file**: The path to the log file where the script will record its output
4. Save the script and exit the text editor.
5. Open a terminal or SSH session and navigate to the directory where the script is located.
6. Run the script with root privileges by entering the following commands:
    ```
    chmod +x backup-drupal.sh
    sudo ./backup-drupal.sh
    ```
7. When prompted, enter the password for the MySQL user specified in the db_user variable.
8. The script will run and create a backup of your website's files and database.
9. Once the backup is complete, the script will print a message to the console indicating where the backup files are stored.

## Modifying the Script

If you need to modify the script, you can do so by opening it in a text editor and making the necessary changes to the variables or commands.

Note that modifying the script incorrectly could cause it to fail or produce unexpected results. It is recommended to make a backup of the original script before making any modifications.

# License

This script is released under the MIT License.