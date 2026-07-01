#! /bin/bash

user=$(id -u)
if [ $user -ne 0 ]; then
    echo "ERROR:login with root." | tee -a "$logfile"
    exit 1
fi

folder=/var/log/monodb-log
mkdir -p $folder
filename=$(echo $0|cut -d "." -f 1)
logfile=$folder/$filname.log
touch $logfile


validate()
{
    if [ $1 -ne 0 ]; then
        echo " ERROR:$2 " | tee -a "$logfile"
        exit 1
    else
        echo " SUCCESS:$2 " |tee -a "$logfile"
    fi         
}


cp mongo.repo /etc/yum.repos.d &>> "$logfile"
validate $? "copy mongodb repository"
dnf install mongodb-org -y &>> "$logfile"
validate $? "install mongodb"
systemctl enable --now  mongod &>> "$logfile"
validate $? "enable at boot,start now"
systemctl status mongod &>> "$logfile"
validate $? "status of mongod"
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf &>> "$logfile"
validate $? "mongodb port access from local to everyone"
systemctl restart mongod &>> "$logfile"
validate $? "restart monogb"