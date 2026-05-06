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
echo "Script started executing at : $(date)" | tee -a $LOG_FILE

#check user has root previliges
if [ $USERID -eq 0 ]
then 
    echo -e "You are running root access .. $G Move forward $N" | tee -a $LOG_FILE
else
    echo -e "$R ERR :: $N Please run this with root access" | tee -a $LOG_FILE
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

cp mongo.repo /etc/yum.repos.d/mongo.repo
VERIFY $? "Copying mongo repo file"

dnf install mongodb-org -y &>>$LOG_FILE
VERIFY $? "Installing MongoDB"

systemctl enable mongod &>>$LOG_FILE
systemctl start mongod &>>$LOG_FILE
VERIFY $? "Starting MongoDB"

sed -i "s/127.0.0.1/0.0.0.0/g" /etc/mongod.conf
VERIFY $? "Editing Mongod config file to enable remote connections"

systemctl restart mongod &>>$LOG_FILE
VERIFY $? "Restarting Mongodb"

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME - $START_TIME))

echo -e "Script execution completed successfully, $Y Time taken = $TOTAL_TIME $N sec" | tee -a $LOG_FILE

