# Install Drupal 9 on Ubuntu 20.04 LTS 

This Bash script automates the installation of a LAMP stack, configuration of firewall, secure MySQL setup, and the installation of Drupal 9 on Ubuntu 20.04 LTS.

## Prerequisites

- Ubuntu 20.04 LTS
- Administrative privileges on the Ubuntu system
- Internet connection

## Usage

1. Open a terminal window on your Ubuntu system.

2. Download the script using curl:

```
curl https://raw.githubusercontent.com/username/repository/main/install-drupal.sh --output install-drupal.sh
```

3. Make the script executable:

```
chmod +x install-drupal.sh
```

4. Change the domain variable to the domain of the Drupal website:

```
domain=your.domain.com
```

5. Follow the on-screen instructions to complete the installation.

Run the script:

```
sudo ./install-drupal.sh
```

If any errors are encountered, make sure to view the logfile for more in-depth information. This script will store everything in `/var/log/install-drupal.log`.

## What does the script do?

The script performs the following steps:

- Installs Apache2, MySQL Server, PHP and other dependencies using APT.
- Configures the firewall to allow HTTP, HTTPS, and OpenSSH traffic.
- Creates a virtual host configuration file for the Apache web server.
- Finalizes changes to Apache web server by enabling modules and reloading the server.
- Secures MySQL installation, deletes default users and databases, and creates a new database for Drupal.
- Downloads and installs the latest version of Drupal 9.
- Outputs the MySQL password and Drupal MySQL password for future reference.


## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License

This project is licensed under the MIT License.


This is a simple automated BASH script to install Drupal 9 on Ubuntu 20.04.  This could work on other Ubuntu/Debian versions, but it has not been tested.

Before running this script, some changes to variables will be needed at the top:
```
domain=your.domain.com
```

Make sure that the domain name of the Drupal Site is filled out correctly in `domain`.  The full url isn't needed and neither is `www` part.  That part is assumed and will be filled in later on different configuration files.

After the script has been modified, make the script executable by running `chmod +x install-drupal.sh` and run it as below:
```
sudo ./install-drupal.sh
```

When the script completed its run, there will be out put for each step of the process that looks like:
```
Installing LAMP Server

Installing software requirements via APT...

Configuring firewall..

Creating configuration files for Apache Webserver...

Finalizing changes to Apache Webserver...

Going through MySQL secure setup...

Installing Drupal 9...
YOUR MYSQL PASSWORD IS: <SOME RANDOM LETTERS AND NUMBERS>
YOUR DRUPAL MYSQL PASSWORD IS: <SOME RANDOM LETTERS AND NUMBERS>
```
Make sure to record these passwords at the end of the script and **DO NOT LOSE THEM**.  They are needed for root access to MySQL and Drupal's access the MySQL.  The Drupal MySQL Password is need in the next steps for installation.

Now that the initial setup has completed, if someone were to navigate to the IP address of the server in their browser - they'll be immediate redirected to the domain name specified in the first steps of this document.  This is because a default `index.html` file has been created as a redirect while the final stages of the Drupal install takes place. 

Navigate to `http://<SERVER ADDRESS HERE>/index.php` and follow the Drupal installation steps in a browser. When this is completed succesfully, remove the `index.html` file from the website's directory in Apache on your server:
```
sudo rm -rvf /var/www/<DOMAIN NAME HERE>/index.html
```
**CONGRATS! DRUPAL 9 IS NOW SUCCESSFULLY INSTALLED!**

If any errors are encountered, make sure to view the logfile for more in-depth information. This script will store everything in `/var/log/install-drupal.log`.

PLEASE NOTE: No passwords will be stored in the logfile, so be sure to store your passwords in a secure place.

