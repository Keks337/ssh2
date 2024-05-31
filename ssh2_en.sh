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

# Set login grace time?
set_login_grace_time=$(get_input "Set login grace time?")
if [ "$set_login_grace_time" = "true" ]; then
    read -p "Enter login grace time (seconds): " login_grace_time
fi

# Disable root login?
disable_root_login=$(get_input "Disable root login?")

# Allow users?
allow_users=$(get_input "Allow specific users?")
if [ "$allow_users" = "true" ]; then
    read -p "Enter allowed users (comma-separated): " allowed_users
    allowed_users=$(sed 's/,/ /g' <<< "$allowed_users")
fi

# Deny users?
deny_users=$(get_input "Deny specific users?")
if [ "$deny_users" = "true" ]; then
    read -p "Enter denied users (comma-separated): " denied_users
    denied_users=$(sed 's/,/ /g' <<< "$denied_users")
fi

# Set maximum sessions?
set_max_sessions=$(get_input "Set maximum sessions?")
if [ "$set_max_sessions" = "true" ]; then
    read -p "Enter maximum sessions: " max_sessions
fi

# Set maximum password attempts?
set_max_auth_tries=$(get_input "Set maximum password attempts?")
if [ "$set_max_auth_tries" = "true" ]; then
    read -p "Enter maximum password attempts: " max_auth_tries
fi

# Apply changes to the configuration file
sed -i "
/^Port .*/c\Port $new_port
/^PermitEmptyPasswords .*/c\PermitEmptyPasswords $disable_empty_passwords
/^LoginGraceTime .*/c\LoginGraceTime $login_grace_time
/^PermitRootLogin .*/c\PermitRootLogin $disable_root_login
/^AllowUsers .*/c\AllowUsers $allowed_users
/^DenyUsers .*/c\DenyUsers $denied_users
/^MaxSessions .*/c\MaxSessions $max_sessions
/^MaxAuthTries .*/c\MaxAuthTries $max_auth_tries
" "$ssh_config_path"

# Restart SSH service
systemctl restart sshd

echo "SSH configuration updated successfully."