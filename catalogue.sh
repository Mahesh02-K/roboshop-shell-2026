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

mkdir -p $LOGS_FOLDER
echo "Script started executing at : $(date)"

#check user has root previleges
if [ $USERID -eq 0 ]
then
    echo -e "You are running with root access ... $G Move forward $N" | tee -a $LOG_FILE
else 
    echo -e "$R ERR ::: Please run this with root user $N" | tee -a $LOG_FILE
    exit 1 #give other than 0 upto 127 
fi 

VERIFY(){
    if [ $1 -eq 0 ]
    then 
        echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1 #give other than 0 upto 127
    fi
}

dnf module disable nodejs -y &>>$LOG_FILE
VERIFY $? "Disabling Nodejs default version"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VERIFY $? "Enabling nodejs 20"

dnf install nodejs -y &>>$LOG_FILE
VERIFY $? "Installing nodejs"

mkdir -p /app
VERIFY $? "Creating app directory"

useradd --system --home /app --shell /sbin/nologin --comment "Roboshop system user" roboshop &>>$LOG_FILE
VERIFY $? "Creating roboshop user"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VERIFY $? "Downloading Catalogue"

cd /app
unzip /tmp/catalogue.zip &>>$LOG_FILE
VERIFY $? "Unzipping Catalogue"

npm install &>>$LOG_FILE
VERIFY $? "Installing Dependencies"

cp catalogue.service /etc/systemd/system/catalogue.service
VERIFY $? "Creating service file"

systemctl daemon-reload &>>$LOG_FILE
VERIFY $? "Daemon reload"

systemctl enable catalogue &>>$LOG_FILE
systemctl start catalogue &>>$LOG_FILE
VERIFY $? "Starting Catalogue"

cp $PWD/mongo.repo /etc/yum.repos.d/mongo.repo
dnf install mongodb-mongosh - &>>$LOG_FILE
VERIFY $? "Installing Mongodb client"

mongosh --host mongodb.kakuturu.online </app/db/master-data.js &>>$LOG_FILE
VERIFY $? "Loading data into MongoDB"

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME - $START_TIME))

echo -e "Script execution completed successfully, $Y Time taken = $TOTAL_TIME $Y sec" | tee -a $LOG_FILE