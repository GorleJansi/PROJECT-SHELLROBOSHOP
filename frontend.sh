#!/bin/bash


folder=/var/log/frontend-log
mkdir -p "$folder"
filename=$(basename "$0" .sh)
logfile=$folder/$filename.log
touch "$logfile"
script_dir=$(cd "$(dirname "$0")" && pwd)

user=$(id -u)
if [ $user -ne 0 ]; then
    echo "ERROR:get ROOT access"|tee -a "$logfile"
    exit 1
fi

validate(){
    if [ $1 -ne 0 ]; then
        echo "ERROR:$2"|tee -a "$logfile"
        exit 1
    else    
        echo "SUCCESS:$2"|tee -a "$logfile"
    fi
}



dnf module disable nginx -y >> "$logfile" 2>&1
validate $? "disabling nginx"

dnf module enable nginx:1.24 -y >> "$logfile" 2>&1
validate $? "enabling nginx"

dnf install nginx unzip -y >> "$logfile" 2>&1
validate $? "install nginx and unzip"

systemctl enable nginx >> "$logfile" 2>&1
validate $? "enabling nginx service"

systemctl start nginx >> "$logfile" 2>&1
validate $? "starting nginx service"

rm -rf /usr/share/nginx/html/* >> "$logfile" 2>&1
validate $? "removing default  nginx html pages"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip >> "$logfile" 2>&1
validate $? "downloading app code"

cd /usr/share/nginx/html >> "$logfile" 2>&1
validate $? "change to nginx html directory"

unzip -o /tmp/frontend.zip >> "$logfile" 2>&1
validate $? "unzip app code in nginx default page "

cp "$script_dir/frontend.conf" /etc/nginx/nginx.conf >> "$logfile" 2>&1
validate $? "adding reverse proxy in nginx conf "

systemctl restart nginx >> "$logfile" 2>&1
validate $? "restarting nginx service"
