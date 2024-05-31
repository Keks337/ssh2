#!/bin/bash

# Запрашиваем у пользователя новый порт по умолчанию
NEW_PORT=""
while [ -z "$NEW_PORT" ]; do
    read -p "Enter new default port: " NEW_PORT
done

# Обновляем файл sshd_config с новым портом
sudo sed -i "s/^#*\s*Port\s.*$/Port $NEW_PORT/" /etc/ssh/sshd_config

# Задаем вопросы пользователю и обновляем файл sshd_config в соответствии с ответами
read -p "Disable empty passwords? (y/n) " DISABLE_EMPTY_PASSWDS
if [ "$DISABLE_EMPTY_PASSWDS" = "y" ]; then
    sudo sed -i "s/^#*\s*PermitEmptyPasswords\s.*$/PermitEmptyPasswords no/" /etc/ssh/sshd_config
fi

read -p "Set login grace time? (y/n) " LOGIN_GRACE_TIME
if [ "$LOGIN_GRACE_TIME" = "y" ]; then
    read -p "Enter login grace time (seconds): " GRACE_TIME
    sudo sed -i "s/^#*\s*LoginGraceTime\s.*$/LoginGraceTime $GRACE_TIME/" /etc/ssh/sshd_config
fi

read -p "Disable root login? (y/n) " DISABLE_ROOT_LOGIN
if [ "$DISABLE_ROOT_LOGIN" = "y" ]; then
    sudo sed -i "s/^#*\s*PermitRootLogin\s.*$/PermitRootLogin no/" /etc/ssh/sshd_config
fi

read -p "Enter users to allow (comma-separated): " ALLOW_USERS
sudo sed -i "s/^#*\s*AllowUsers\s.*$/AllowUsers $ALLOW_USERS/" /etc/ssh/sshd_config

read -p "Enter users to deny (comma-separated): " DENY_USERS
sudo sed -i "s/^#*\s*DenyUsers\s.*$/DenyUsers $DENY_USERS/" /etc/ssh/sshd_config

read -p "Set maximum sessions? (y/n) " MAX_SESSIONS
if [ "$MAX_SESSIONS" = "y" ]; then
    read -p "Enter maximum sessions: " MAX_SESSIONS_NUM
    sudo sed -i "s/^#*\s*MaxSessions\s.*$/MaxSessions $MAX_SESSIONS_NUM/" /etc/ssh/sshd_config
fi

read -p "Set maximum password attempts? (y/n) " MAX_AUTH_TRIES
if [ "$MAX_AUTH_TRIES" = "y" ]; then
    read -p "Enter maximum password attempts: " MAX_AUTH_TRIES_NUM
    sudo sed -i "s/^#*\s*MaxAuthTries\s.*$/MaxAuthTries $MAX_AUTH_TRIES_NUM/" /etc/ssh/sshd_config
fi