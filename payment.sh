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
    echo -e "You are running with root access .. $Y Move forward $N" | tee -a $LOG_FILE
else
    echo -e "$R ERR :: Please run this with root access $N"| tee -a $LOG_FILE
    exit 1
fi 

VERIFY(){
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi 
}

dnf install python3 gcc python3-devel -y &>>$LOG_FILE
VERIFY $? "Installing python3"

mkdir -p /app &>>$LOG_FILE
VERIFY $? "Creating app directory"

id roboshop &>>$LOG_FILE
if [ $? -eq 0 ]
then
    echo -e "Roboshop user is ... $Y Already created $N" | tee -a $LOG_FILE
else
    useradd --system --home /app --shell /sbin/nologin --comment "Roboshop user" roboshop
    VERIFY $? "Creating Roboshop user"
fi

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip  &>>$LOG_FILE
cd /app 
rm -rf /app/*
unzip /tmp/payment.zip &>>$LOG_FILE
VERIFY $? "Downloading and unzipping payment component"

pip3 install -r requirements.txt &>>$LOG_FILE
VERIFY $? "Installing python dependencies"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service &>>$LOG_FILE
VERIFY $? "Copying payment service file"

systemctl daemon-reload &>>$LOG_FILE
systemctl enable payment &>>$LOG_FILE
systemctl start payment &>>$LOG_FILE
VERIFY $? "Starting payment service"

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME - $START_TIME))
echo -e "Script execution completed successfully, $Y TIME_TAKEN = $TOTAL_TIME $N secs" | tee -a $LOG_FILE

