#!/bin/bash

#!/bin/bash

START_TIME=$(date +%s)
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[37m"

LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo -e "Script started executing at : $Y $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]
then
    echo -e "$R ERROR ::: $N PLEASE RUN WITH ROOT ACCESS" | tee -a $LOG_FILE
    exit 1 #give other than 0 upto 127
else
    echo -e "$G SUCCESS ::: $N YOU ARE RUNNING WITH ROOT ACCESS" | tee -a $LOG_FILE
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
VERIFY $? "Disabling Default Nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VERIFY $? "Enabling Nodejs:20"

dnf install nodejs -y &>>$LOG_FILE
VERIFY $? "Installing Nodejs"

mkdir -p /app &>>$LOG_FILE
VERIFY $? "Creating App Directory"

id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VERIFY $? "Creating roboshop user"
else
    echo -e "Roboshop user is ... $Y Already Created $N" | tee -a $LOG_FILE
fi

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip
VERIFY $? "Downloading cart"

rm -rf /app/* &>>$LOG_FILE
cd /app &>>$LOG_FILE
unzip /tmp/cart.zip &>>$LOG_FILE
VERIFY $? "Unzipping Cart"

npm install &>>$LOG_FILE
VERIFY $? "Installing Dependancies"

cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service &>>$LOG_FILE
VERIFY $? "Copying service file"

systemctl daemon-reload &>>$LOG_FILE
systemctl enable cart &>>$LOG_FILE
systemctl start cart &>>$LOG_FILE
VERIFY $? "Starting Cart service"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script execution completed successfully, $Y Time taken : $TOTAL_TIME secs $N" | tee -a $LOG_FILE

# START_TIME=$(date +%s)
# USERID=$(id -u)
# R="\e[31m"
# G="\e[32m"
# Y="\e[33m"
# N="\e[0m"

# LOGS_FOLDER="/var/log/roboshop-logs"
# SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
# LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
# SCRIPT_DIR=$PWD

# mkdir -p $LOGS_FOLDER
# echo -e "Script started executing at : $Y $(date) $N" | tee -a $LOG_FILE

# if [ $USERID -eq 0 ]
# then 
#     echo -e "You are running with root access : $G Move forward $N" | tee -a $LOG_FILE
# else
#     echo -e "$R ERR :: Please run this with root access $N" | tee -a $LOG_FILE
#     exit 1
# fi 

# VERIFY(){
#     if [ $1 -eq 0 ]
#     then    
#         echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
#     else 
#         echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
#         exit 1
#     fi
# }

# dnf module disable nodejs -y &>>$LOG_FILE
# VERIFY $? "Disabling Nodejs"

# dnf module enable nodejs:20 -y &>>$LOG_FILE
# VERIFY $? "Enabling nodejs"

# dnf install nodejs -y &>>$LOG_FILE
# VERIFY $? "Installing nodejs"

# mkdir -p /app
# VERIFY $? "Creating app directory"

# id roboshop
# if [ $? -eq 0 ]
# then    
#     echo -e "Roboshop user is .. $Y Already created $N" | tee -a $LOG_FILE
# else 
#     useradd --system --home /app --shell /sbin/nologin --comment "Roboshop system user" roboshop
#     VERIFY $? "Creating roboshop user"
# fi

# cd /app
# curl -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>>$LOG_FILE
# rm -rf /app/*
# unzip /tmp/cart.zip
# VERIFY $? "Downlaoding and unzipping cart"

# npm install &>>$LOG_FILE
# VERIFY $? "Installing Dependencies"

# cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service
# VERIFY $? "Copying cart service"

# systemctl daemon-reload &>>$LOG_FILE
# systemctl enable cart &>>$LOG_FILE
# systemctl start cart &>>$LOG_FILE
# VERIFY $? "Starting cart"

# END_TIME=$(date +%s)
# TOTAL_TIME=$(($END_TIME - $START_TIME))
# echo -e "Script execution completed successfully, $Y TIME_TAKEN = $TOTAL_TIME $N secs" | tee -a $LOG_FILE