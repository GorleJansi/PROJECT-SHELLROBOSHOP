#! /bin/bash
folder=/var/log/catalogue-logs
mkdir -p "$folder"
filename=$(basename "$0" .sh)
logfile=$folder/$filename.log
touch "$logfile"
script_dir=$PWD

user=$(id -u)
if [ $user -ne 0 ]; then
    echo "ERROR:Run as root" | tee -a "$logfile"
    exit 1
fi

validate(){
    if [ $1 -ne 0 ]; then
        echo "ERROR:$2" | tee -a "$logfile"
        exit 1
    else 
        echo "SUCCESS:$2" | tee -a "$logfile"
    fi        
}

dnf module disable nodejs -y >> "$logfile" 2>&1
validate $? "disabling nodejs version"
dnf module enable nodejs:20 -y >> "$logfile" 2>&1
validate $? "enabling nodejs version"
dnf install nodejs -y >> "$logfile" 2>&1
validate $? "install specific nodejs version"
id roboshop >> "$logfile" 2>&1
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /bin/bash roboshop >> "$logfile" 2>&1
    validate $? "creating system user"
else
    validate 0 "system user already exists"
fi
cp "$script_dir/catalogue.service" /etc/systemd/system/catalogue.service >> "$logfile" 2>&1
validate $? "custom app so coping service file"
mkdir -p /app >> "$logfile" 2>&1
validate $? "creating application directory"
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip >> "$logfile" 2>&1
validate $? "downloading artifact"
cd /app >> "$logfile" 2>&1
validate $? "change to app directory"
unzip -o /tmp/catalogue.zip >> "$logfile" 2>&1
validate $? "unzip app code from temp directory"
npm install >> "$logfile" 2>&1
validate $? "install dependencies"
systemctl daemon-reload >> "$logfile" 2>&1
validate $? "daemon realod after updating service file"
systemctl start catalogue >> "$logfile" 2>&1
validate $? "start service"
systemctl enable catalogue >> "$logfile" 2>&1
validate $? "enable service at boot"
cp "$script_dir/mongo.repo" /etc/yum.repos.d/mongo.repo >> "$logfile" 2>&1
validate $? "copy mongo repo to download mongoclient"
dnf install mongodb-mongosh -y >> "$logfile" 2>&1
validate $? "download mongo client"
mongosh --host 172.31.40.12 < /app/db/master-data.js >> "$logfile" 2>&1
validate $? "load the mongodb data master data"
systemctl restart catalogue >> "$logfile" 2>&1
validate $? "restarting service"
