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
echo -e "Script started executing at : $(date)" | tee -a $LOG_FILE

if [ $USERID -eq 0 ]
then 
    echo -e "You are running with root :: $G Move forward $N" | tee -a $LOG_FILE
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

dnf module disable redis -y &>>$LOG_FILE
VERIFY $? "Disabling default redis"

dnf module enable redis:7 -y &>>$LOG_FILE
VERIFY $? "Enabling redis:7"

dnf install redis -y &>>$LOG_FILE
VERIFY $? "Installing redis"

sed -i -e "s/127.0.0.1/0.0.0.0/g" -e "/protected-mode/ c protected-mode no" /etc/redis/redis.conf 
VERIFY $? "Enabling remote connections"

systemctl enable redis &>>$LOG_FILE
VERIFY $? "Enabling redis"

systemctl start redis &>>$LOG_FILE
VERIFY $? "Starting redis"

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME - $START_TIME))

echo -e "Script execution completed successfully, $Y Time_taken = $TOTAL_TIME secs $N" | tee -a $LOG_FILE