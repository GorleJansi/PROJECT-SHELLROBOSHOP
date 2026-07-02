#! bin/bash

folder=/var/log/payment-logs
mkdir -p $folder
filename=$(echo $0|cut -d "." -f 1)
logfile=$folder/$filename.log
touch $logfile
$Script_dir=$PWD

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



dnf install python3 gcc python3-devel -y &>> "$logfile"
validate $? "installing python"

id roboshop &>> "$logfile"
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /bin/bash roboshop
    validate $? "system user created"
else
    validate 0 "system user already exists ...."    
fi


mkdir -p /app &>> "$logfile"
validate $? "move to /app directory"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>> "$logfile"
validate $? "downloading application artifact"

cd /app &>> "$logfile"
validate $? "change to /app directory"

unzip -o /tmp/payment.zip &>> "$logfile"
validate $? "delete old fils in /app and unzip application artifact"

pip3 install -r requirements.txt &>> "$logfile"


cp $Script_dir/payment.service /etc/systemd/system/payment.service &>> "$logfile"
validate $? "coping payment service"

systemctl daemon-reload &>> "$logfile"
validate $? "reload service configurations"

systemctl enable payment &>> "$logfile"
validate $? "enable payment service"

systemctl start payment &>> "$logfile"
validate $? "start payment service"
