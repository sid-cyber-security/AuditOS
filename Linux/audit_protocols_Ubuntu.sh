#!/bin/bash

# Проверка наличия сервисов
services=(
    "telnet:telnetd:23:Telnet не зашифрованный протокол передачи данных. Рекомендуется использовать SSH."
    "ftp:vsftpd:21:FTP - протокол передачи файлов без шифрования. Рекомендуется использовать SFTP/FTPS или SCP."
    "rsh:rsh-server:514:RSH - старый протокол удаленного выполнения команд. Рекомендуется использовать SSH."
    "http:apache2:80:HTTP - не безопасный протокол передачи данных для веб-серверов. Рекомендуется использовать HTTPS с SSL/TLS-шифрованием."
    "tftp:tftp-hpa:69:TFTP - протокол передачи файлов без аутентификации. Рассмотрите возможность перехода на более безопасные альтернативы."
)

# Проверяем установленные сервисы
for service_str in "${services[@]}"; do
    IFS=":" read -ra service <<< "$service_str"
    if dpkg -l | grep -q "${service[1]}"; then
        if netstat -pnltu | grep -qw ":${service[2]}"; then
            echo "${service[0]} (порт ${service[2]}) найден: ${service[3]}"
        fi
    fi
done

# Проверяем наличие не безопасных протоколов
if [ -f "/etc/securetty" ] && grep -q -E "rlogin|rsh|rexec" /etc/securetty; then
    echo "Rlogin, Rexec и Rsh (порты 512-514) найдены: старые протоколы с низким уровнем безопасности. Рекомендуется использовать SSH."
fi

# Проверяем наличие не безопасных сервисов NIS и NIS+
nis_services=("ypserv" "ypbind" "rpc.yppasswdd" "rpc.ypupdated" "rpc.ypxfrd")
for nis_service in "${nis_services[@]}"; do
    if dpkg -l | grep -q "$nis_service"; then
        echo "Сервис $nis_service(NIS или NIS+) найден: старые и небезопасные системы. Рекомендуется перейти на более современные системы."
    fi
done

# Проверяем наличие и версию SMB
if dpkg -l | grep -q "samba"; then
    if testparm -s 2>/dev/null | grep -q "^\s*server min protocol\s*=\s*SMB2" || testparm -s 2>/dev/null | grep -q "^\s*client min protocol\s*=\s*SMB2"; then
        echo "SMBv1 отключен: при работе с Samba рекомендуется использовать SMBv2 или выше."
    else
        echo "SMBv1 включен: устаревшая и небезопасная версия протокола SMB. Рекомендуется перейти на SMBv2 или выше."
    fi
fi

# Проверяет версии SSL
ssl_versions=("SSLv2" "SSLv3")
for version in "${ssl_versions[@]}"; do
    if [ -d "/etc/apache2" ] && find /etc/apache2 -type f | xargs grep -qw "$version"; then
        echo "${version} найден: устаревшая версия TLS. Рекомендуется отключить и использовать TLS 1.2 или выше."
    elif [ -d "/etc/nginx" ] && find /etc/nginx -type f | xargs grep -qw "$version"; then
        echo "${version} найден: устаревшая версия TLS. Рекомендуется отключить и использовать TLS 1.2 или выше."
    fi
done

# Проверяем версии SNMP
if dpkg -l | grep -q "snmp"; then
    if ! grep -qw "v3" /etc/snmp/snmpd.conf; then
        echo "SNMPv1 и SNMPv2 найдены: первые версии протокола SNMP. Рекомендуется использовать SNMPv3 для аутентификации и шифрования данных."
    fi
fi
