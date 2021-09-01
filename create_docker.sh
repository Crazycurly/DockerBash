#!/bin/bash
read -p "Create UserName  : " USER_NAME

read -p "Setting Password  [ default : password ] : " USER_PWD
if [ ${#USER_PWD} == 0 ] ; then
    USER_PWD="password"
fi

read -p "Setting SSH's Port  : " SSH_PORT
read -p "Setting published ports (8080:8080 5000:5000...)  : " USER_PORT
read -p "Docker image  : " IMAGE
read -p "Apt package (nano vim...) : " PACKAGE


if [ ${#USER_NAME} == 0 -o ${#SSH_PORT} == 0 -o ${#USER_PORT} == 0 ] ; then
    echo "Please at least enter the user name and the port number"
    exit 0
fi

arrPORT=(${USER_PORT// / })

echo -e "\nYou Setting:"
echo "User: ${USER_NAME}"
echo "Password: ${USER_PWD}"
echo "SSH Port: ${SSH_PORT}"
echo "Published ports: "

len=${#arrPORT[@]}

for (( i=0; i<${len}; i++ ));
do
  echo "${arrPORT[$i]}"
  Port+="-p ${arrPORT[$i]} "
done

read -p "Are you sure ? [Y/n] " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]
then
    exit
fi


sudo docker run -itd \
                -p $SSH_PORT:22 \
                ${Port} \
                --name $USER_NAME \
                --hostname $USER_NAME \
                ${IMAGE}

sudo docker exec -ti $USER_NAME sh -c "apt-get update && apt-get install -y openssh-server ${PACKAGE}"


sudo docker exec -ti $USER_NAME sh -c "echo \"root:${USER_PWD}\" | chpasswd;
                                       sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config;
                                       sed -i 's/#PasswordAuthentication/PasswordAuthentication/' /etc/ssh/sshd_config;
                                       sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd;
                                       export PATH=\"$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\";
                                       wget -P /etc/fail2ban/ https://raw.githubusercontent.com/voidful/DockerBash/master/jail.local;"

sudo docker restart $USER_NAME

sudo docker exec -ti $USER_NAME sh -c "service ssh start"

echo "Container create finish"
echo "Login as root, SSH port ${SSH_PORT}"
