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

# Function to add users
add_users() {
    users=()
    while true; do
        read -p "Enter username (or press Enter to exit): " user
        if [ -z "$user" ]; then
            break
        else
            users+=("$user")
        fi
    done
    printf '%s\n' "${users[@]}"
}

# Function to deny users
deny_users() {
    denied=()
    while true; do
        read -p "Enter username to deny (or press Enter to exit): " user
        if [ -z "$user" ]; then
            break
        else
            denied+=("$user")
        fi
    done
    printf '%s\n' "${denied[@]}"
}

# Check if firewalld is installed
if ! command -v firewall-cmd >/dev/null 2>&1; then
    echo "firewalld is not installed. Skipping port opening."
    firewalld_installed="false"
else
    firewalld_installed="true"
fi

# Check if SSH configuration file exists
ssh_config_path="/etc/ssh/sshd_config"
while [ ! -f "$ssh_config_path" ]; do
    echo "File $ssh_config_path not found."
    read -p "Enter the path to the SSH configuration file: " ssh_config_path
done

# Get user input
change_port=$(get_input "Change default port?")
if [ "$change_port" = "true" ]; then
    read -p "Enter new port: " new_port
    if [ "$firewalld_installed" = "true" ]; then
        open_port=$(get_input "Open new port in firewalld?")
    fi
fi
disable_empty_passwords=$(get_input "Disable empty passwords?")
set_login_grace_time=$(get_input "Set login grace time?")
disable_root_login=$(get_input "Disable root login?")
allowed_users=$(add_users "Enter allowed users")
denied_users=$(deny_users "Enter denied users")
read -p "Maximum number of sessions: " max_sessions
read -p "Maximum number of password attempts: " max_auth_tries

# Additional settings
enable_pubkey_auth=$(get_input "Enable public key authentication?")
enable_password_auth=$(get_input "Enable password authentication?")
enable_banner=$(get_input "Create a banner?")
if [ "$enable_banner" = "true" ]; then
    create_banner_text=$(get_input "Do you want to enter the banner text?")
    if [ "$create_banner_text" = "true" ]; then
        read -p "Enter banner text: " banner_text
        banner_file=$(mktemp)
        echo "$banner_text" > "$banner_file"
    else
        read -p "Enter the path to the banner file: " banner_file
    fi
fi

# Apply changes to the configuration file
sed -i '
    /^Port /c\Port '"${new_port:-22}"'
    /^PermitEmptyPasswords/c\PermitEmptyPasswords '"$disable_empty_passwords"'
    /^LoginGraceTime/c\LoginGraceTime '"$([ "$set_login_grace_time" = "true" ] && read -p "Enter time (in seconds): " && echo "$REPLY" || echo "120")"'
    /^PermitRootLogin/c\PermitRootLogin '"$disable_root_login"'
    /^AllowUsers/d
    /^DenyUsers/d
    $ a\AllowUsers '"$([ -n "$allowed_users" ] && echo "$allowed_users" || echo "ALL")"'
    $ a\DenyUsers '"$([ -n "$denied_users" ] && echo "$denied_users")"'
    /^MaxSessions/c\MaxSessions '"$max_sessions"'
    /^MaxAuthTries/c\MaxAuthTries '"$max_auth_tries"'
    /^PubkeyAuthentication/c\PubkeyAuthentication '"$enable_pubkey_auth"'
    /^PasswordAuthentication/c\PasswordAuthentication '"$enable_password_auth"'
    /^Banner/d
    '"$([ -n "$banner_file" ] && echo "/^#Banner/a\\Banner $banner_file")"'
' "$ssh_config_path"

# Open new port in firewalld if selected
if [ "$open_port" = "true" ] && [ "$firewalld_installed" = "true" ]; then
    firewall-cmd --permanent --add-port="${new_port:-22}"/tcp
    firewall-cmd --reload
fi

# Restart SSH service
systemctl restart sshd

echo "SSH configuration updated!"