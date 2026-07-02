#! bin/bash

folder=/var/log/shipping-logs
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



dnf install maven -y &>> "$logfile"
validate $? "installing maven"

id roboshop &>> "$logfile"
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin roboshop
    validate $? "system user created"
else
    validate 0 "system user already exists ...."    
fi



curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip  &>> "$logfile"
validate $? "downloading application artifact"

mkdir -p /app &>> "$logfile"
validate $? "move to /app directory"

cd /app &>> "$logfile"
validate $? "change to /app directory"

unzip -o /tmp/shipping.zip &>> "$logfile"
validate $? "delete old fils in /app and unzip application artifact"

mvn clean package l &>> "$logfile"
validate $? "installing dependencies and build jar "

mv target/shipping-1.0.jar shipping.jar 
validate $? "rename jar file"


cp $Script_dir/shipping.service /etc/systemd/system/shipping.service &>> "$logfile"
validate $? "coping shipping service"

systemctl daemon-reload &>> "$logfile"
validate $? "reload service configurations"

systemctl enable shipping &>> "$logfile"
validate $? "enable shipping service"

systemctl start shipping &>> "$logfile"
validate $? "start shipping service"


dnf install mysql -y  &>>$LOG_FILE

mysql -h 100.58.156.112 -uroot -pRoboShop@1 -e 'use cities' &>>$LOG_FILE
if [ $? -ne 0 ]; then
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOG_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql  &>>$LOG_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOG_FILE
else
    echo -e "Shipping data is already loaded ... $Y SKIPPING $N"
fi

systemctl restart shipping