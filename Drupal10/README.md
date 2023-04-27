# Description

This bash script installs a LAMP server and Drupal 10 on Ubuntu 22.04. It also configures Apache virtual hosts, the firewall, and the MySQL database.

# How to use

- Download the script to your Ubuntu 22.04 machine.
- Open a terminal and navigate to the directory where the script was downloaded.
- Run the script as root:

```
sudo bash install-drupal10.sh
```

Follow the prompts.

# How to modify for different domain names and directories

To modify the script for different domain names and directories, you need to edit the domain, web_dir, sites_dir, and sites_file variables.

- **domain**: Set this to the domain name you want to use.
- **web_dir**: Set this to the directory where you want to install Drupal.
- **sites_dir**: Set this to the directory where Apache virtual host files are stored.
- **sites_file**: Set this to the name you want to give to the Apache virtual host file.

For example, if you want to use the domain name "example.com" and install Drupal in the directory "/var/www/example.com", you would change the following lines:

```
domain="mydomain.com"
web_dir="/var/www/$domain"
sites_file="$domain.conf"
```

to:

``
domain="example.com"
web_dir="/var/www/$domain"
sites_file="$domain.conf"
``

You would also need to update the DNS records for your domain to point to your server's IP address.

# License

This script is released under the MIT License.