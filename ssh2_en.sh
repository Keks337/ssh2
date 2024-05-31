#!/bin/bash

# Function to get user input
get_input() {
    read -p "$1 (y/n) " choice
    case "$choice" in
        y|Y) echo "true" ;;
        n|N) echo "false" ;;
        *) echo "Invalid input" ; get_input "$1"
    esac
}

# Check if SSH configuration file exists
ssh_config_path="/etc/ssh/sshd_config"
if [ ! -f "$ssh_config_path" ]; then
    echo "SSH configuration file not found at $ssh_config_path. Exiting."
    exit 1
fi

# Get user input to change default port
change_port=$(get_input "Change default SSH port?")
if [ "$change_port" = "true" ]; then
    read -p "Enter new port: " new_port
    # Check if port number is valid
    if [[ ! $new_port =~ ^[0-9]+$ ]] || [ $new_port -lt 1 ] || [ $new_port -gt 65535 ]; then
        echo "Invalid port number. Using default port 22."
        new_port=22
    fi
fi

# Disable empty passwords?
disable_empty_passwords=$(get_input "Disable empty passwords?")
if [ "$disable_empty_passwords" = "true" ]; then
    sed -i "s/^PermitEmptyPasswords.*/PermitEmptyPasswords no/" $ssh_config_path
fi

# Set login grace time?
set_login_grace_time=$(get_input "Set login grace time?")
if [ "$set_login_grace_time" = "true" ]; then
    read -p "Enter login grace time (seconds): " login_grace_time
    sed -i "s/^LoginGraceTime.*/LoginGraceTime $login_grace_time/" $ssh_config_path
fi

# Disable root login?
disable_root_login=$(get_input "Disable root login?")
if [ "$disable_root_login" = "true" ]; then
    sed -i "s/^PermitRootLogin.*/PermitRootLogin no/" $ssh_config_path
fi

# Allow users?
allow_users=$(get_input "Allow specific users?")
if [ "$allow_users" = "true" ]; then
    read -p "Enter allowed users (comma-separated): " allowed_users_list
    allowed_users=( $allowed_users_list )
    echo "AllowUsers ${allowed_users[@]}" >> $ssh_config_path
fi

# Deny users?
deny_users=$(get_input "Deny specific users?")
if [ "$deny_users" = "true" ]; then
    read -p "Enter denied users (comma-separated): " denied_users_list
    denied_users=( $denied_users_list )
    echo "DenyUsers ${denied_users[@]}" >> $ssh_config_path
fi

# Set maximum sessions?
set_max_sessions=$(get_input "Set maximum sessions?")
if [ "$set_max_sessions" = "true" ]; then
    read -p "Enter maximum sessions: " max_sessions
    sed -i "s/^MaxSessions.*/MaxSessions $max_sessions/" $ssh_config_path
fi

# Set maximum password attempts?
set_max_auth_tries=$(get_input "Set maximum password attempts?")
if [ "$set_max_auth_tries" = "true" ]; then
    read -p "Enter maximum password attempts: " max_auth_tries
    sed -i "s/^MaxAuthTries.*/MaxAuthTries $max_auth_tries/" $ssh_config_path
fi

# Change default port
if [ "$change_port" = "true" ]; then
    sed -i "s/^Port.*/Port $new_port/" $ssh_config_path
fi

# Restart SSH service
systemctl restart sshd

echo "SSH configuration updated successfully."