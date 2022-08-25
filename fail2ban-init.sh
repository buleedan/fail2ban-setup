#!/usr/bin/env bash

## Global variables and function

LIGHTRED='\033[0;31m'
LIGHTGREEN='\033[0;32m'
LIGHTBLUE='\033[0;34m'
LIGHTCYAN='\033[0;36m'
LIGHTPURPLE='\033[0;35m'
NC='\033[0m' # No Color

randomString() {
  LC_ALL=C tr -dc 'A-Za-z0-9!#$%&()*+,-./:;<=>?@[\]^_{|}~' </dev/urandom | head -c 32 ; echo
}

##
## Install Fail2ban
##
echo -e "${LIGHTBLUE}INSTALL FAIL2BAN${NC}"
sudo apt -y update
sudo apt -y install fail2ban

echo -e "${LIGHTPURPLE}✔ Fail2ban installed${NC}"

##
## Add custom filters
##
echo -e "${LIGHTBLUE}ADD CUSTOM FILTERS${NC}"

echo -e "${LIGHTPURPLE}✔ Custom filters added${NC}"

##
## Setup DB
##
echo -e "${LIGHTBLUE}SETUP DATABASE${NC}"

DB_TEMPLATE=/tmp/fail2ban.mysql;
DB_HOST=127.0.0.1
DB_PORT=3306
DATABASE="fail2ban"
DB_USER="fail2ban"
DB_PASSWORD=$(randomString)

cd /tmp
wget https://raw.githubusercontent.com/buleedan/fail2ban-setup/master/database/fail2ban.mysql

if [ -f /root/.my.cnf ]; then
  mysql -e "CREATE DATABASE ${DATABASE} DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
  mysql -e "GRANT ALL ON ${DATABASE}.* TO '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';"
  mysql -e "USE ${DATABASE};"
  mysql -e "SOURCE ${DB_TEMPLATE}"
else
  read -sp "MySQL root password: " MYSQL_PSWD
  echo -e ""
  mysql -uroot -p${MYSQL_PSWD} -e "CREATE DATABASE ${DATABASE} DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
  mysql -uroot -p${MYSQL_PSWD} -e "GRANT ALL ON ${DATABASE}.* TO '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';"
  mysql -uroot -p${MYSQL_PSWD} -e "USE ${DATABASE};"
  mysql -uroot -p${MYSQL_PSWD} -e "SOURCE ${DB_TEMPLATE}"
fi

echo -e "+"
echo -e "| Database Setup"
echo -e "| - Host    : ${DB_HOST}"
echo -e "| - Port    : ${DB_PORT}"
echo -e "| - Database: ${DATABASE}"
echo -e "| - User    : ${DB_USER}"
echo -e "| - Password: ${DB_PASSWORD}"
echo -e "+"

echo -e "${LIGHTPURPLE}✔ Database created and setup${NC}"

##
## Setup GeoIP DB
##
echo -e "${LIGHTBLUE}INSTALL GEOIP${NC}"
sudo apt-get -y install geoip-bin geoip-database

echo -e "${LIGHTPURPLE}✔ GEOIP installed${NC}"

##
## Setup connection to DB
##
echo -e "${LIGHTBLUE}SETUP CONNECTION TO DATABASE${NC}"
wget https://raw.githubusercontent.com/buleedan/fail2ban-setup/master/database/banned_db.conf
sudo mv banned_db.conf /etc/fail2ban/action.d/

wget https://raw.githubusercontent.com/buleedan/fail2ban-setup/master/database/fail2ban_banned_db
sudo mv fail2ban_banned_db /usr/local/bin/
sudo chmod 0550 /usr/local/bin/fail2ban_banned_db

sudo cat >/root/.my.cnf-fail2ban << EOL
[client]
host="${DB_HOST}"
port="${DB_PORT}"
user="${DB_USER}"
password="${DB_PASSWORD}"
EOL

echo -e "${LIGHTPURPLE}✔ Connection to Database set${NC}"

##
## Custom local jail
##
echo -e "${LIGHTBLUE}SETUP CUSTOM LOCAL JAIL${NC}"
wget https://raw.githubusercontent.com/buleedan/fail2ban-setup/master/jail.d/jail.local
sudo mv jail.local /etc/fail2ban

echo -e "${LIGHTPURPLE}✔ Custom local jail setup${NC}"

##
## Custom local jail
##
echo -e "${LIGHTBLUE}START FAIL2BAN${NC}"
sudo fail2ban-client start

echo -e "${LIGHTPURPLE}✔ Fail2ban started${NC}"

echo -e "${LIGHTGREEN}== Fail2ban setup finished ==${NC}"
