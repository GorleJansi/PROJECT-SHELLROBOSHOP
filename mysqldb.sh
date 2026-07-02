#! /bin/bash

set -eou pipefail
trap 'echo "ERROR at line :$LINENO and command :$BASH_COMMAND" ' ERR

folder=/var/log/shell-logs
mkdir -p $folder
filename=$(echo $0|cut -d "." -f 1)
logfile=$folder/$filename.log
touch $logfile


user=$(id -u)
if [ $user -ne 0 ]; then
    echo "ERROR:Run as ROOT"
    exit 1
fi

dnf install mysql-server -y &>> "$logfile"
echo"SUCCESS:install mysql server"
systemctl enable mysqld &>> "$logfile"
echo"SUCCESS:enabling mysqld service"
systemctl start mysqld &>> "$logfile"
echo"SUCCESS:starting mysql service"
mysql_secure_installation --set-root-pass RoboShop@1 &>> "$logfile"
echo"SUCCESS:changing the default root password"