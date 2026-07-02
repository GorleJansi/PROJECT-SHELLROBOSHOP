#! /bin/bash

set -euo pipelinefail
trap 'echo "Scripts failed at line: $LINENUM and command executed is : $BASH_COMMAND" ' ERR
folder=/var/log/rabbitmq-logs
filename=$(echo $0 |cut -d "." -f 1)
logfile=$folder/$filename.log
touch $logfile
Script_dir=$PWD
user=$(id -u)
if [ $user -ne 0 ]; then
    echo " ERROR:run as root "|tee -a "$logfile"
    exit 1
fi

cp $Script_dir/rabbitmq.repo /etc/yum.repos.d >> "$logfile" 2>&1
echo "SUCESS: Coping rabbitmq repo"

dnf install rabbitmq-server -y >> "$logfile" 2>&1
echo "SUCESS: Installing rabbitmq-server"


systemctl enable rabbitmq-server >> "$logfile" 2>&1
echo "SUCESS: enabling rabbitmq-server"

systemctl start rabbitmq-server >> "$logfile" 2>&1
echo "SUCESS: start rabbitmq-server"

rabbitmqctl add_user roboshop roboshop123

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"

systemctl restart rabbitmq-server >> "$logfile" 2>&1
echo "SUCESS: restart rabbitmq-server"