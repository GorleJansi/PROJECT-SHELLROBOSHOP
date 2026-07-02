#! /bin/bash

folder=/var/log/payment-logs
mkdir -p "$folder"
filename=$(basename "$0" .sh)
logfile=$folder/$filename.log
touch "$logfile"
script_dir=$(cd "$(dirname "$0")" && pwd)

user=$(id -u)
if [ $user -ne 0 ]; then
    echo "ERROR:Run as ROOT" | tee -a "$logfile"
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



dnf install python3 gcc python3-devel -y >> "$logfile" 2>&1
validate $? "installing python"

id roboshop >> "$logfile" 2>&1
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /bin/bash roboshop >> "$logfile" 2>&1
    validate $? "system user created"
else
    validate 0 "system user already exists ...."    
fi


mkdir -p /app >> "$logfile" 2>&1
validate $? "move to /app directory"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip >> "$logfile" 2>&1
validate $? "downloading application artifact"

cd /app >> "$logfile" 2>&1
validate $? "change to /app directory"

unzip -o /tmp/payment.zip >> "$logfile" 2>&1
validate $? "delete old files in /app and unzip application artifact"

pip3 install -r requirements.txt >> "$logfile" 2>&1
validate $? "installing python dependencies"

cp "$script_dir/payment.service" /etc/systemd/system/payment.service >> "$logfile" 2>&1
validate $? "copying payment service"

systemctl daemon-reload >> "$logfile" 2>&1
validate $? "reload service configurations"

systemctl enable payment >> "$logfile" 2>&1
validate $? "enable payment service"

systemctl start payment >> "$logfile" 2>&1
validate $? "start payment service"
