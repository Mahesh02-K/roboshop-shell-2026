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
    echo -e "You are running with root access : $G Move forward $N" | tee -a $LOG_FILE
else
    echo -e "$R ERR :: Please run this with root access $N" | tee -a $LOG_FILE
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

dnf module disable nodejs -y &>>$LOG_FILE
VERIFY $? "Disabling Nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VERIFY $? "Enabling nodejs"

dnf install nodejs -y &>>$LOG_FILE
VERIFY $? "Installing nodejs"

mkdir -p /app
VERIFY $? "Creating app directory"

id roboshop
if [ $? -eq 0 ]
then    
    echo -e "Roboshop user is .. $Y Already created $N" | tee -a $LOG_FILE
else 
    useradd --system --home /app --shell /sbin/nologin --comment "Roboshop system user" roboshop
    VERIFY $? "Creating roboshop user"
fi

cd /app
curl -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>>$LOG_FILE
rm -rf /app/*
unzip /tmp/cart.zip
VERIFY $? "Downlaoding and unzipping cart"

npm install &>>$LOG_FILE
VERIFY $? "Installing Dependencies"

cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service
VERIFY $? "Copying cart service"

systemctl daemon-reload &>>$LOG_FILE
systemctl enable cart &>>$LOG_FILE
systemctl start cart &>>$LOG_FILE
VERIFY $? "Starting cart"

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME - $START_TIME))
echo -e "Script execution completed successfully, $Y TIME_TAKEN = $TOTAL_TIME $N secs" | tee -a $LOG_FILE