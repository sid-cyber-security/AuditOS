#Run as root and in user's root directories (or /opt)
#chmod 700 find_root_users.sh
#!/bin/bash

# Ищем UID равный 0 в файле /etc/passwd
root_users=$(awk -F: '$3 == 0 {print $1}' /etc/passwd)

echo "Учетные записи с правами root (UID 0):"
echo "${root_users}"
echo ""

# Ищем пользователей с пользователями в группе wheel
wheel_group_members=$(getent group wheel | cut -d: -f4)

echo "Учетные записи с правами root через группу wheel:"
echo "${wheel_group_members}"
echo ""

# Выводим список пользователей с возможностью использования sudo
sudoers=$(awk -F: '$3 >= 1000 && $3 <= 60000 {print $1}' /etc/passwd)

echo "Учетные записи с возможностью использования sudo:"
for user in ${sudoers}; do
    sudo_status=$(sudo -U "${user}" -l | grep -q "not allowed" && echo "нет" || echo "да")
    echo "${user}: ${sudo_status}"
done
