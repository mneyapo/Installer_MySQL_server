#!/bin/bash
rootpasswd=root
dbname=rpi
username=yapo
userpass=pipi
charset=utf8
MYSQL=root
SECURE_MYSQL(){
	echo "SECURE_MYSQL"
	SECURE_MYSQL=$(expect -c "
	set timeout 1
	spawn mysql_secure_installation
	expect \"Enter current password for root (enter for none):\"
	send \"$MYSQL\r\"
	expect \"Change the root password?\"
	send \"n\r\"
	expect \"Remove anonymous users?\"
	send \"y\r\"
	expect \"Disallow root login remotely?\"
	send \"y\r\"
	expect \"Remove test database and access to it?\"
	send \"y\r\"
	expect \"Reload privilege tables now?\"
	send \"y\r\"
	expect eof
	")
	echo "$SECURE_MYSQL"
	#apt-get purge expect -y 
	}	

Config_MySQL_server(){
	echo -e "\e[31m***** Config MySQL server...\e[0m"
	sudo mysql -uroot -proot mysql -e "SELECT User, Host, plugin FROM mysql.user;"
	echo "Update root User Plugin"
	echo ""
	sudo mysql -uroot -proot mysql -e "update user set plugin='' where User='root';"
	sudo mysql -uroot -proot mysql -e "SELECT User, Host, plugin FROM mysql.user;"
	echo ""
	echo "Update root User Passwd"
	sudo mysql -uroot -proot mysql -e "UPDATE user SET Password=PASSWORD('root') where USER='root';"
	sudo mysql -uroot -proot mysql -e "update mysql.user SET Password=PASSWORD('root') where USER='root';"
	sudo mysql -uroot -proot mysql -e "UPDATE user SET authentication_string='root' WHERE user='root@localhost';"
	echo ""
	echo "Granting ALL privileges To root"
	sudo mysql -uroot -proot mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost';"
	sudo mysql -uroot -proot mysql -e "FLUSH PRIVILEGES;"
	}
Installer_MySQL_server(){
	sudo apt-get install expect -y 
	sudo /etc/init.d/mysql stop
	echo -e "\e[32mInstallation de MySQL-server MySQL-client \e[0m"
	sudo apt-get update && sudo apt-get install -y mysql-server mysql-client mariadb-server 
	echo -e "\e[31mRestart, Start, Stop MySQL : service mysql start \e[0m"
	sudo service mysql start
	/etc/init.d/mysql status
	# If /root/.my.cnf exists then it won't ask for root password
	if [ -f /root/.my.cnf ]; then
		 echo "/root/.my.cnf exists"
	# If /root/.my.cnf doesn't exist then it'll ask for root password	
	else
		echo  -e "\e[31m/root/.my.cnf doesn't exist\e[0m The root user MySQL password! $rootpasswd."
		RESULT=`sudo mysql -uroot -proot --skip-column-names -e "SHOW DATABASES LIKE 'rpi'"`
		if [ "$RESULT" == "rpi" ]; then
			echo "Database exist"
		else
			echo -e "\e[31mDatabase  doesn't exist\e[0m"
			echo ""
			echo "the  database CHARACTER SET! $charset."
			echo -e "\e[33mCreating new  database...$dbname\e[0m"
			sudo mysql -uroot -p${rootpasswd} -e "CREATE DATABASE IF NOT EXISTS ${dbname} /*\!40100 DEFAULT CHARACTER SET ${charset} */;"
			echo "Showing existing databases..."
			sudo sudo mysql -uroot -p${rootpasswd} -e "show databases;"
			echo ""
			echo "The NAME of the new  database user! $username."
			echo ""
			echo "The PASSWORD for the new  database user! $userpass."
			echo ""
			echo -e "\e[33mCreating new user...! $username\e[0m"
			echo ""
			sudo mysql -uroot -p${rootpasswd} -e "CREATE USER IF NOT EXISTS ${username}@localhost IDENTIFIED BY '${userpass}';"
			sudo mysql -uroot -p${rootpasswd} -e "GRANT ALL PRIVILEGES ON ${dbname}.* TO '${username}'@'localhost';"
			sudo mysql -uroot -p${rootpasswd} -e "FLUSH PRIVILEGES;"
			echo "User successfully created!"
			echo ""
		fi
		SECURE_MYSQL
		Config_MySQL_server
		echo -e "\e[33mYou're good now :)\e[0m"
	fi
	}
Installer_MySQL_server
$SHELL
