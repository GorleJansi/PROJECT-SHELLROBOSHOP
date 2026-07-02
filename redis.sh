#! /bin/bash

red="\e[31m"
green="\e[32m"
normal="\e[0m"

folder=/var/log/redis-logs
mkdir -p $folder
filename=$(echo $0 |cut -d "." -f 1)
logfile=$folder/$filename.log
touch $logfile

user=$(id -u)
if [ $user -ne 0 ]; then
    echo -e "$red ERROR $normal:Run as ROOT"|tee -a "$logfile"
    exit 1
fi

validate(){
    if [ $1 -ne 0 ]; then
        echo -e "$red ERROR $normal:$2 "|tee -a "$logfile"
    else
        echo -e "$green SUCCESS $normal:$2 "|tee -a "$logfile"
    fi       
}

dnf module disable redis -y >> "$logfile" 2>&1
validate $? "disabling redis version"

dnf module enable redis:7 -y >> "$logfile" 2>&1
validate $? "enabling redis version"

dnf install redis -y >> "$logfile" 2>&1
validate $? "installing enabled redis version"

sed -i -e "s/127.0.0.1/0.0.0.0/g"  -e  "/protected-mode/ c protected-mode no" /etc/redis/redis.conf >> "$logfile" 2>&1
validate $? "Allowing Remote connections to Redis"

systemctl enable redis >> "$logfile" 2>&1
validate $? "enabled redis service"

systemctl start redis >> "$logfile" 2>&1
validate $? "started redis service"
