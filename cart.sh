#! bin/bash


folder=/var/log/cart-logs
mkdir -p $folder
filename=$(echo $0|cut -d "." -f 1)
logfile=$folder/$filename.log
touch $logfile


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

dnf module disable nodejs -y &>> "$logfile"
validate $? "disabling default nodejs version"

dnf module enable nodejs:20 -y &>> "$logfile"
validate $? "enabling nodejs specific version"

dnf install nodejs -y &>> "$logfile"
validate $? "installing nodejs"

id roboshop &>> "$logfile"
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /bin/bash roboshop
    validate $? "system user created"
else
    validate 0 "system user already exists ...."    

mkdir -p /app &>> "$logfile"
validate $? "move to /app directory"

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>> "$logfile"
validate $? "downloading application artifact"

cd /app &>> "$logfile"
validate $? "change to /app directory"

unzip -o /tmp/cart.zip &>> "$logfile"
validate $? "delete old fils in /app and unzip application artifact"

npm install &>> "$logfile"
validate $? "installing dependencies"

cp $Script_dir/cart.service /etc/systemd/system/cart.service &>> "$logfile"
validate $? "coping cart service"

systemctl daemon-reload &>> "$logfile"
validate $? "reload service configurations"

systemctl enable cart &>> "$logfile"
validate $? "enable cart service"

systemctl start cart &>> "$logfile"
validate $? "start cart service"


