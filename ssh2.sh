#!/bin/bash
export LANG=ru_RU.UTF-8

# ������� ��� ��������� ����� �� ������������
get_input() {
    read -p "$1 (y/n) " choice
    case "$choice" in
        y|Y) echo "true" ;;
        n|N) echo "false" ;;
        *) echo "������������ ����" ; get_input "$1"
    esac
}

# ������� ��� ���������� �������������
add_users() {
    users=()
    while true; do
        read -p "������� ��� ������������ (��� ������� Enter ��� ������): " user
        if [ -z "$user" ]; then
            break
        else
            users+=("$user")
        fi
    done
    printf '%s\n' "${users[@]}"
}

# ������� ��� ������� �������������
deny_users() {
    denied=()
    while true; do
        read -p "������� ��� ������������ ��� ������� (��� ������� Enter ��� ������): " user
        if [ -z "$user" ]; then
            break
        else
            denied+=("$user")
        fi
    done
    printf '%s\n' "${denied[@]}"
}

# �������� ������� firewalld
if ! command -v firewall-cmd >/dev/null 2>&1; then
    echo "firewalld �� ����������. ���������� ��������� �������� �����."
    firewalld_installed="false"
else
    firewalld_installed="true"
fi

# �������� ������� ����������������� ����� SSH
ssh_config_path="/etc/ssh/sshd_config"
while [ ! -f "$ssh_config_path" ]; do
    echo "���� $ssh_config_path �� ������."
    read -p "������� ���� � ����������������� ����� SSH: " ssh_config_path
done

# ��������� ����� �� ������������
change_port=$(get_input "������� ����������� ����?")
if [ "$change_port" = "true" ]; then
    read -p "������� ����� ����: " new_port
    if [ "$firewalld_installed" = "true" ]; then
        open_port=$(get_input "������� ����� ���� � firewalld?")
    fi
fi
disable_empty_passwords=$(get_input "��������� ������ ������?")
set_login_grace_time=$(get_input "���������� ����� �� ����?")
disable_root_login=$(get_input "��������� ������ �� ��� ����?")
allowed_users=$(add_users "������� ����������� �������������")
denied_users=$(deny_users "������� ����������� �������������")
read -p "������������ ���������� ������: " max_sessions
read -p "���������� ������� ����� ������: " max_auth_tries

# �������������� ���������
enable_pubkey_auth=$(get_input "�������� ����������� �� ������?")
enable_password_auth=$(get_input "�������� ����������� �� ������?")
enable_banner=$(get_input "������� ������?")
if [ "$enable_banner" = "true" ]; then
    create_banner_text=$(get_input "������ ������ ����� ��� �������?")
    if [ "$create_banner_text" = "true" ]; then
        read -p "������� ����� �������: " banner_text
        banner_file=$(mktemp)
        echo "$banner_text" > "$banner_file"
    else
        read -p "������� ���� � ����� �������: " banner_file
    fi
fi

# �������� ��������� � ���������������� ����
sed -i "
    /^Port /c\Port ${new_port:-22}
    /^PermitEmptyPasswords/c\PermitEmptyPasswords $disable_empty_passwords
    /^LoginGraceTime/c\LoginGraceTime $([ "$set_login_grace_time" = "true" ] && read -p "������� ����� (� ��������): " && echo "$REPLY" || echo "120")
    /^PermitRootLogin/c\PermitRootLogin $disable_root_login
    /^AllowUsers/d
    /^DenyUsers/d
    $ a\AllowUsers $([ -n "$allowed_users" ] && echo "$allowed_users" || echo "ALL")
    $ a\DenyUsers $([ -n "$denied_users" ] && echo "$denied_users")
    /^MaxSessions/c\MaxSessions $max_sessions
    /^MaxAuthTries/c\MaxAuthTries $max_auth_tries
    /^PubkeyAuthentication/c\PubkeyAuthentication $enable_pubkey_auth
    /^PasswordAuthentication/c\PasswordAuthentication $enable_password_auth
    /^Banner/d
    $([ -n "$banner_file" ] && echo "/^#Banner/a\Banner $banner_file")
" "$ssh_config_path"

# �������� ������ ����� � firewalld, ���� �������
if [ "$open_port" = "true" ] && [ "$firewalld_installed" = "true" ]; then
    firewall-cmd --permanent --add-port="${new_port:-22}"/tcp
    firewall-cmd --reload
fi

# ���������� ������ SSH
systemctl restart sshd

echo "������������ SSH ���������!"