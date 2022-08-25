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

echoTitle(){
  echo -e "${LIGHTBLUE}$1${NC}"
}

echoInfo(){
  echo -e "${LIGHTPURPLE}$1${NC}"
}

echoSuccess(){
  echo -e "${LIGHTGREEN}$1${NC}"
}

echoError(){
  echo -e "${LIGHTRED}$1${NC}"
}

##
## Install Fail2ban
##
echoTitle "INSTALL FAIL2BAN"

echoInfo "Update apt repo"
sudo apt -y update

eechoInfo "Install Fail2ban"
sudo apt -y install fail2ban

echoInfo "✔ Fail2ban installed"

##
## Add custom filters
##
echoTitle "ADD CUSTOM FILTERS"

echoInfo "✔ Custom filters added"

##
## Setup DB
##
echoTitle "SETUP DATABASE"

if type mysql >/dev/null 2>&1; then
    DB_HOST=127.0.0.1
    DB_PORT=3306
    DATABASE="fail2ban"
    DB_USER="fail2ban"
    DB_PASSWORD=$(randomString)

    cd /tmp
    echoInfo "Download MYSQL database creation script"
    wget https://raw.githubusercontent.com/buleedan/fail2ban-setup/master/database/fail2ban.mysql

    echoInfo "Create ${DATABASE} database and user"
    if [ -f /root/.my.cnf ]; then
        mysql -e "CREATE DATABASE ${DATABASE} DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
        mysql -e "GRANT ALL ON ${DATABASE}.* TO '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';"
        ##mysql -e "USE ${DATABASE};"
        ##mysql -e "SOURCE /tmp/fail2ban.mysql;"
        mysql ${DATABASE} < /tmp/fail2ban.mysql
    else
        read -sp "MySQL root password: " MYSQL_PSWD
        echo -e ""
        mysql -uroot -p${MYSQL_PSWD} -e "CREATE DATABASE ${DATABASE} DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
        mysql -uroot -p${MYSQL_PSWD} -e "GRANT ALL ON ${DATABASE}.* TO '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';"
        ##mysql -uroot -p${MYSQL_PSWD} -e "USE ${DATABASE};"
        ##mysql -uroot -p${MYSQL_PSWD} -e "SOURCE /tmp/fail2ban.mysql;"
        mysql -uroot -p${MYSQL_PSWD} ${DATABASE} < /tmp/fail2ban.mysql
    fi

    echoInfo "✔ Database created and setup"

    ##
    ## Setup GeoIP DB
    ##
    echoTitle "INSTALL GEOIP"
    sudo apt-get -y install geoip-bin geoip-database

    echoInfo "✔ GEOIP installed"

    ##
    ## Setup connection to DB
    ##
    echoTitle "SETUP CONNECTION TO DATABASE"
    echoInfo "Download fail2ban configuration"
    wget https://raw.githubusercontent.com/buleedan/fail2ban-setup/master/database/banned_db.conf

    echoInfo "Move banned_db.conf to the right directory"
    sudo mv banned_db.conf /etc/fail2ban/action.d/

    echoInfo "Download fail2ban DB script"
    wget https://raw.githubusercontent.com/buleedan/fail2ban-setup/master/database/fail2ban_banned_db

    echoInfo"Move fail2ban_banned_db to the right directory"
    sudo mv fail2ban_banned_db /usr/local/bin/

    echoInfo "Set banned_db.conf CHMOD"
    sudo chmod 0550 /usr/local/bin/fail2ban_banned_db

    echoInfo "Generate MYSQL connection configuration file for fail2ban"
    sudo cat >/root/.my.cnf-fail2ban <<EOL
      [client]
      host="${DB_HOST}"
      port="${DB_PORT}"
      user="${DB_USER}"
      password="${DB_PASSWORD}"
EOL

    echoInfo "✔ Connection to Database set"

    ##
    ## Custom local jail
    ##
    echoTitle "SETUP CUSTOM LOCAL JAIL"
    echoInfo "Download custom jail.local"
    wget https://raw.githubusercontent.com/buleedan/fail2ban-setup/master/jail.d/jail.local

    echoInfo "Move jail.local to the right directory"
    sudo mv jail.local /etc/fail2ban

    echoInfo "✔ Custom local jail setup"

    echo -e ""
    echo -e "+"
    echo -e "| Database Setup"
    echo -e "| - Host    : ${DB_HOST}"
    echo -e "| - Port    : ${DB_PORT}"
    echo -e "| - Database: ${DATABASE}"
    echo -e "| - User    : ${DB_USER}"
    echo -e "| - Password: ${DB_PASSWORD}"
    echo -e "+"

else
    echoError "+---------------------------------------------+"
    echoError "| MySQL not installed !!                      |"
    echoError "| Fail2Ban database and configuration skipped |"
    echoError "+---------------------------------------------+"
fi

##
## Custom local jail
##
echoTitle "START FAIL2BAN"
sudo fail2ban-client start

echoInfo "✔ Fail2ban started"

echoSuccess "+-------------------------+"
echoSuccess "| Fail2ban setup finished |"
echoSuccess "+-------------------------+"
