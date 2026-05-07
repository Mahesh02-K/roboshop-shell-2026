#!/bin/bash

START_TIME=$(date +%s)
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo -e "Script started executing at : $Y $(date) $N" | tee -a $LOG_FILE

if [ $USERID -eq 0 ]
then
    echo -e "You are running with root access .. $G Move forward $N" | tee -a $LOG_FILE
else
    echo -e "$R ERR :: Please run this with root access $N" | tee -a $LOG_FILE
    exit 1
fi 

echo -e "$R ENTER ROOT PASSWORD TO SETUP $N" | tee -a $LOG_FILE
read -s MYSQL_ROOT_PASSWORD

VERIFY(){
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}

dnf install maven -y &>>$LOG_FILE
VERIFY $? "Installing Maven and Java"

mkdir -p /app
VERIFY $? "Creating app directory"

id roboshop &>>$LOG_FILE
if [ $? -eq 0 ]
then 
    echo -e "Roboshop user is .. $Y Already created $N" | tee -a $LOG_FILE
else
    useradd --system --home /app --shell /sbin/nologin --comment "Roboshop user" roboshop 
    VERIFY $? "Creating roboshop user"
fi

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
cd /app
rm -rf /app/* 
unzip /tmp/shipping.zip &>>$LOG_FILE
VERIFY $? "Downloading and unzipping shipping content"

mvn clean package &>>$LOG_FILE
VERIFY $? "Packaging in shipping application"

mv target/shipping-1.0.jar shipping.jar &>>$LOG_FILE
VERIFY $? "Moving and renaming jar file in target folder"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service
VERIFY $? "Copying shipping service file"

systemctl daemon-reload &>>$LOG_FILE
systemctl enable shipping &>>$LOG_FILE
systemctl start shipping &>>$LOG_FILE
VERIFY $? "Starting shipping service"

dnf install mysql -y &>>$LOG_FILE
VERIFY $? "Installing mysql client"

mysql -h mysql.kakuturu.online -u root -p$MYSQL_ROOT_PASSWORD -e 'use cities' &>>$LOG_FILE
if [ $? -eq 0 ]
then 
    echo -e "Data is .. $Y Already loaded $N" | tee -a $LOG_FILE
else 
    mysql -h mysql.kakuturu.online -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/schema.sql &>>$LOG_FILE
    mysql -h mysql.kakuturu.online -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/app-user.sql &>>$LOG_FILE
    mysql -h mysql.kakuturu.online -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/master-data.sql &>>$LOG_FILE   
    VERIFY $? "Data loading into mysql"
fi

systemctl restart shipping &>>$LOG_FILE
VERIFY $? "Restarting shipping"

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME - $START_TIME))
echo -e "Script execution completed successfully, $Y TIME_TAKEN = $TOTAL_TIME $N secs" | tee -a $LOG_FILE