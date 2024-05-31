#!/bin/bash

# ѕровер€ем, установлен ли firewalld
if ! dpkg -s firewalld &>/dev/null; then
    read -p "Firewalld is not installed. Do you want to install it? (y/n) " INSTALL_FIREWALLD
    if [ "$INSTALL_FIREWALLD" = "y" ]; then
         apt install firewalld -y
    else
        echo "Cannot set up port forwarding without firewalld."
        exit 1
    fi
fi

# «апрашиваем у пользовател€ изменить ли порт по умолчанию
read -p "Do you want to change the default port? (y/n) " CHANGE_PORT
if [ "$CHANGE_PORT" = "y" ]; then
    read -p "Enter new default port: " NEW_PORT
     sed -i "s/^#*\s*Port\s.*$/Port $NEW_PORT/" /etc/ssh/sshd_config

    # «апрашиваем у пользовател€ согласи€ на проброс портов
    read -p "Do you want to set up port forwarding? (y/n) " SETUP_FORWARDING
    if [ "$SETUP_FORWARDING" = "y" ]; then
        read -p "Enter IP address: " IP_ADDR
         firewall-cmd --zone=external --add-forward-port=port=22:proto=tcp:toport=$NEW_PORT:toaddr="$IP_ADDR" --permanent
         firewall-cmd --zone=external --add-port=$NEW_PORT/tcp --permanent
        read -p "Enter interface name: " INTERFACE_NAME
         firewall-cmd --zone=external --add-interface="$INTERFACE_NAME" --permanent
         firewall-cmd --reload
    fi
fi

# «адаем вопросы пользователю и обновл€ем файл sshd_config в соответствии с ответами
read -p "Disable empty passwords? (y/n) " DISABLE_EMPTY_PASSWDS
if [ "$DISABLE_EMPTY_PASSWDS" = "y" ]; then
     sed -i "s/^#*\s*PermitEmptyPasswords\s.*$/PermitEmptyPasswords no/" /etc/ssh/sshd_config
fi

read -p "Set login grace time (minutes): " GRACE_TIME
if [ -n "$GRACE_TIME" ]; then
    GRACE_TIME=$((GRACE_TIME * 60))
     sed -i "s/^#*\s*LoginGraceTime\s.*$/LoginGraceTime $GRACE_TIME/" /etc/ssh/sshd_config
fi

read -p "Disable root login? (y/n) " DISABLE_ROOT_LOGIN
if [ "$DISABLE_ROOT_LOGIN" = "y" ]; then
     sed -i "s/^#*\s*PermitRootLogin\s.*$/PermitRootLogin no/" /etc/ssh/sshd_config
fi

read -p "Enable key authentication? (y/n) " ENABLE_KEY_AUTH
if [ "$ENABLE_KEY_AUTH" = "y" ]; then
     sed -i "s/^#*\s*PubkeyAuthentication\s.*$/PubkeyAuthentication yes/" /etc/ssh/sshd_config
fi

read -p "Enable password authentication? (y/n) " ENABLE_PASSWORD_AUTH
if [ "$ENABLE_PASSWORD_AUTH" = "y" ]; then
     sed -i "s/^#*\s*PasswordAuthentication\s.*$/PasswordAuthentication yes/" /etc/ssh/sshd_config
fi

read -p "Enter users to allow (->,): " ALLOW_USERS
if [ -n "$ALLOW_USERS" ]; then
    sed -i "/^AllowUsers/ d" /etc/ssh/sshd_config
    echo "AllowUsers $ALLOW_USERS" |  tee -a /etc/ssh/sshd_config
fi

read -p "Enter users to deny (->,): " DENY_USERS
if [ -n "$DENY_USERS" ]; then
    sed -i "/^DenyUsers/ d" /etc/ssh/sshd_config
    echo "DenyUsers $DENY_USERS" |  tee -a /etc/ssh/sshd_config
fi

read -p "Set maximum sessions? (y/n) " MAX_SESSIONS
if [ "$MAX_SESSIONS" = "y" ]; then
    read -p "Enter maximum sessions: " MAX_SESSIONS_NUM
     sed -i "s/^#*\s*MaxSessions\s.*$/MaxSessions $MAX_SESSIONS_NUM/" /etc/ssh/sshd_config
fi

read -p "Set maximum password attempts? (y/n) " MAX_AUTH_TRIES
if [ "$MAX_AUTH_TRIES" = "y" ]; then
    read -p "Enter maximum password attempts: " MAX_AUTH_TRIES_NUM
     sed -i "s/^#*\s*MaxAuthTries\s.*$/MaxAuthTries $MAX_AUTH_TRIES_NUM/" /etc/ssh/sshd_config
fi

# «апрашиваем у пользовател€ согласи€ на создание баннера
read -p "Do you want to create a banner? (y/n) " CREATE_BANNER
if [ "$CREATE_BANNER" = "y" ]; then
    read -p "Enter banner text: " BANNER_TEXT
    echo "$BANNER_TEXT" |  tee /etc/ssh/banner > /dev/null
    echo "Banner /etc/ssh/banner" |  tee -a /etc/ssh/sshd_config
fi

# ѕерезапускаем службу SSH
systemctl restart sshd