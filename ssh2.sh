#!/bin/bash
export LANG=ru_RU.UTF-8

# Функция для получения ввода от пользователя
get_input() {
    read -p "$1 (y/n) " choice
    case "$choice" in
        y|Y) echo "true" ;;
        n|N) echo "false" ;;
        *) echo "Некорректный ввод" ; get_input "$1"
    esac
}

# Функция для добавления пользователей
add_users() {
    users=()
    while true; do
        read -p "Введите имя пользователя (или нажмите Enter для выхода): " user
        if [ -z "$user" ]; then
            break
        else
            users+=("$user")
        fi
    done
    printf '%s\n' "${users[@]}"
}

# Функция для запрета пользователей
deny_users() {
    denied=()
    while true; do
        read -p "Введите имя пользователя для запрета (или нажмите Enter для выхода): " user
        if [ -z "$user" ]; then
            break
        else
            denied+=("$user")
        fi
    done
    printf '%s\n' "${denied[@]}"
}

# Проверка наличия firewalld
if ! command -v firewall-cmd >/dev/null 2>&1; then
    echo "firewalld не установлен. Пропускаем настройку открытия порта."
    firewalld_installed="false"
else
    firewalld_installed="true"
fi

# Проверка наличия конфигурационного файла SSH
ssh_config_path="/etc/ssh/sshd_config"
while [ ! -f "$ssh_config_path" ]; do
    echo "Файл $ssh_config_path не найден."
    read -p "Введите путь к конфигурационному файлу SSH: " ssh_config_path
done

# Получение ввода от пользователя
change_port=$(get_input "Сменить стандартный порт?")
if [ "$change_port" = "true" ]; then
    read -p "Введите новый порт: " new_port
    if [ "$firewalld_installed" = "true" ]; then
        open_port=$(get_input "Открыть новый порт в firewalld?")
    fi
fi
disable_empty_passwords=$(get_input "Выключить пустые пароли?")
set_login_grace_time=$(get_input "Установить время на вход?")
disable_root_login=$(get_input "Выключить доступ из под рута?")
allowed_users=$(add_users "Введите разрешенных пользователей")
denied_users=$(deny_users "Введите запрещенных пользователей")
read -p "Максимальное количество сессий: " max_sessions
read -p "Количество попыток ввода пароля: " max_auth_tries

# Дополнительные настройки
enable_pubkey_auth=$(get_input "Включить авторизацию по ключам?")
enable_password_auth=$(get_input "Включить авторизацию по паролю?")
enable_banner=$(get_input "Создать баннер?")
if [ "$enable_banner" = "true" ]; then
    create_banner_text=$(get_input "Хотите ввести текст для баннера?")
    if [ "$create_banner_text" = "true" ]; then
        read -p "Введите текст баннера: " banner_text
        banner_file=$(mktemp)
        echo "$banner_text" > "$banner_file"
    else
        read -p "Введите путь к файлу баннера: " banner_file
    fi
fi

# Внесение изменений в конфигурационный файл
sed -i "
    /^Port /c\Port ${new_port:-22}
    /^PermitEmptyPasswords/c\PermitEmptyPasswords $disable_empty_passwords
    /^LoginGraceTime/c\LoginGraceTime $([ "$set_login_grace_time" = "true" ] && read -p "Введите время (в секундах): " && echo "$REPLY" || echo "120")
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

# Открытие нового порта в firewalld, если выбрано
if [ "$open_port" = "true" ] && [ "$firewalld_installed" = "true" ]; then
    firewall-cmd --permanent --add-port="${new_port:-22}"/tcp
    firewall-cmd --reload
fi

# Перезапуск службы SSH
systemctl restart sshd

echo "Конфигурация SSH обновлена!"