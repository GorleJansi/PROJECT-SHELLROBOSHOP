#! /bin/bash
user=$(id -u)
if [ $user -ne 0 ]; then
    echo "ERROR:Run as root"
    exit 1
fi

folder=/var/log/catalogue-logs
mkdir -p $folder
filename=$(echo $0|cut -d "." -f 1)
logfile=$folder/$filename.log
touch $logfile

validate(){
    if [ $1 -ne 0 ]; then
        echo "ERROR:$2"|tee -a "$logfile"
    else 
        echo "SUCESS:$2"|tee -a "$logfile"
    fi        
}

dnf module disable nodejs -y &>> "$logfile"
validate $? "disabling nodejs version"
dnf module enable nodejs:20 -y &>> "$logfile"
validate $? "enabling nodejs version"
dnf install nodejs -y &>> "$logfile"
validate $? "install specific nodejs version"
useradd --system --home /app --shell /bin/bash roboshop &>> "$logfile"
validate $? "creating system user"
cp catalogue.service /etc/systemd/system/catalogue.service &>> "$logfile"
validate $? "custom app so coping service file"
mkdir -p /app &>> "$logfile"
validate $? "creating application directory"
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>> "$logfile"
validate $? "downloading artifact"
cd /app &>> "$logfile"
validate $? "change to app directory"
unzip /tmp/catalogue.zip &>> "$logfile"
validate $? "unzip app code from temp directory"
npm install &>> "$logfile"
validate $? "install dependencies"
systemctl daemon-reload &>> "$logfile"
validate $? "daemon realod after updating service file"
systemctl start catalogue &>> "$logfile"
validate $? "start service"
systemctl enable catalogue &>> "$logfile"
validate $? "enable service at boot"
cp mongo.repo /etc/yum.repos.d &>> "$logfile"
validate $? "copy mongo repo to download mongoclient"
dnf install mongodb-mongosh -y &>> "$logfile"
validate $? "download mongo client"
mongosh --host 172.31.40.12 </app/db/master-data.js &>> "$logfile"
validate $? "load the mongodb data master data"
systemctl restart catalogue &>> "$logfile"
validate $? "restarting service"
