#!/bin/bash

START_TIME=$(date)
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
echo -e "Script started executing at : $Y $(date) $N"

if [ $USERID -eq 0 ]
then 
    echo -e "You are running with root access ... $G Move Forward $N"
else
    echo -e "$R ERR :: Please run this with root access $N"
    exit 1
fi

VERIFY(){
    if [ $1 -eq 0 ]
    then 
        echo -e "$2 is ... $G SUCCESS $N"
    else
        echo -e "$2 is ... $R FAILURE $N"
        exit 1
    fi
}
