#!/bin/bash


read -p "Do you want to change the default SSH port? (y/n) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]
then

    read -p "Enter new SSH port number: " new_port

    # Проверяем, что новый номер порта является числом в диапазоне от 1 до 65535
    if [[ $new_port =~ ^[0-9]+$ ]] && [ $new_port -ge 1 ] && [ $new_port -le 65535 ]
    then

         sed -i "s/^#*\s*\(Port [0-9]*\)\s*/Port $new_port/" /etc/ssh/sshd_config


         systemctl restart ssh

        echo "SSH port changed to $new_port"
    else
        echo "Invalid port number"
    fi
fi