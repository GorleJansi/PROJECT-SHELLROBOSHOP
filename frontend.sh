#! /bin/bash


folder=/var/log/frontend-log
mkdir -p $folder
filename=$(echo $0|cut -d "." -f 1)
logfile=$folder/$filename.log
touch $logfile
script_dir=$PWD

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



dnf module disable nginx -y &>> "$logfile"
validate $? "disabling nginx"

dnf module enable nginx:1.24 -y &>> "$logfile"
validate $? "enabling nginx"

dnf install nginx -y &>> "$logfile"
validate $? "install nginx"

systemctl enable nginx  &>> "$logfile"
validate $? "enabling nginx service"

systemctl start nginx  &>> "$logfile"
validate $? "starting nginx service"

rm -rf /usr/share/nginx/html/* &>> "$logfile"
validate $? "removing default  nginx html pages"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>> "$logfile"
validate $? "downloading app code"

cd /usr/share/nginx/html &>> "$logfile"

unzip -o unzip /tmp/frontend.zip &>> "$logfile"
validate $? "unzip app code in nginx default page "

cp $script_dir/frontend.conf /etc/nginx/nginx.conf &>> "$logfile"
validate $? "adding reverse proxy in nginx conf "

systemctl restart nginx  &>> "$logfile"
validate $? "restarting nginx service"