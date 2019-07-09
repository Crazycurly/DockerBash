#!/bin/bash
read -p "Create UserName  : " USER_NAME

read -p "Setting Password  [ default : password ] : " USER_PWD
if [ ${#USER_PWD} == 0 ] ; then
    USER_PWD="password"
fi

read -p "Setting SSH's Port  : " USER_PORT
read -p "Setting notebook's Port  : " NOTEBOOK_PORT
read -p "Setting tensorboard's Port  : " TENSORBOARD_PORT

if [ ${#USER_NAME} == 0 -o ${#USER_PORT} == 0 -o ${#TENSORBOARD_PORT} == 0 ] ; then
    echo "Please at least enter the user name and the port number"
    exit 0
fi

echo -e "\nYou Setting:"
echo "User: ${USER_NAME}"
echo "Password: ${USER_PWD}"
echo "Port: ${USER_PORT}"
echo "tensorboard Port: ${TENSORBOARD_PORT}"

sudo nvidia-docker run -itd \
                -p $USER_PORT:22 \
                -p $TENSORBOARD_PORT:6006 \
                --name $USER_NAME \
                --hostname $USER_NAME \
                pytorch/pytorch:latest &> /dev/null

# sudo docker exec -ti $USER_NAME sudo sh -c "sudo apt-get update && sudo apt-get upgrade && sudo apt-get install -y openssh-server"

sudo docker exec -ti $USER_NAME sudo sh -c "sudo useradd -m $USER_NAME -s /bin/bash;
                                         echo \"${USER_NAME}:${USER_PWD}\" | chpasswd;
                                         sudo adduser $USER_NAME sudo;
                                         echo \"export LANG=C.UTF-8\" | tee -a /home/$USER_NAME/.bashrc;
                                         sudo wget -P /etc/fail2ban/ https://raw.githubusercontent.com/voidful/DockerBash/master/jail.local;
                                         sudo rm /var/run/fail2ban/fail2ban.sock"

sudo docker restart $USER_NAME

sudo docker exec -ti $USER_NAME sudo sh -c "sudo /etc/init.d/ssh start"

echo "Container create finish"