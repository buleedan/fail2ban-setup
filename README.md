## Introduction

Fail2ban is a very nice tool, however it's difficult to ban IPs from apps.
To be able to control Banned IPs from apps, we can create a MySQL database that is linked to fail2ban.

This script setup this database and also configure fail2ban filters to setup everything in a matter of few seconds.

## Setup and initialize Fail2ban

To setup and initialize Fail2ban on your Debian/Ubuntu server, run this script:

```
cd /tmp
wget https://raw.githubusercontent.com/buleedan/fail2ban-setup/master/fail2ban-init.sh
sudo chmod +x fail2ban-init.sh
sudo ./fail2ban-init.sh
```
