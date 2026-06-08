#!/bin/sh
# Desenvolvido e implantado por: João Moraes
# github.com/jmoraes18/pfsense-openvpn-notify

# ============================================================
# CONFIGURAÇÕES
# ============================================================
TELEGRAM_TOKEN="SEU_TOKEN_AQUI"
TELEGRAM_CHAT="SEU_CHAT_ID_AQUI"
CSV_LOG="/var/log/openvpn-events.csv"
TMP_MSG="/tmp/openvpn_tg_msg.txt"

# ============================================================
# FILTROS - Usuários que NÃO geram notificação imediata
# e NÃO aparecem no relatório diário.
# Para adicionar mais usuários, separe por espaço:
# SKIP_USERS="usuario1.vpn usuario2.vpn usuario3.vpn"
# ============================================================
SKIP_USERS="usuario.filtrado"

# ============================================================
HOSTNAME=$(hostname)
EVENT=$script_type
CLIENT=$common_name
IP=$ifconfig_pool_remote_ip
REAL_IP=$trusted_ip
TIME=$(date '+%d/%m/%Y %H:%M:%S')
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
TIME_SHORT=$(date '+%H:%M')
DURATION=$time_duration

CONNECT_TIME=$(date -j -f "%Y-%m-%d %H:%M:%S" "$time_ascii" '+%d/%m/%Y %H:%M:%S' 2>/dev/null || echo "$time_ascii")
CONNECT_TIME_SHORT=$(date -j -f "%Y-%m-%d %H:%M:%S" "$time_ascii" '+%H:%M' 2>/dev/null || echo "?")

if [ -n "$DURATION" ] && [ "$DURATION" -gt 0 ]; then
    MINUTOS=$((DURATION / 60))
    SEGUNDOS=$((DURATION % 60))
    [ "$SEGUNDOS" -gt 0 ] && MINUTOS=$((MINUTOS + 1))
    if [ "$MINUTOS" -ge 60 ]; then
        HORAS=$((MINUTOS / 60))
        MINS=$((MINUTOS % 60))
        DURACAO_FORMATADA="${HORAS}h${MINS}min"
    else
        DURACAO_FORMATADA="${MINUTOS}min"
    fi
else
    DURACAO_FORMATADA="N/A"
    DURATION=0
fi

# Verificar se usuário está na lista de filtrados
FILTRADO=0
for SKIP in $SKIP_USERS; do
    if [ "$CLIENT" = "$SKIP" ]; then
        FILTRADO=1
        break
    fi
done

# Gravar no CSV apenas se não for usuário filtrado
if [ "$FILTRADO" = "0" ]; then
    echo "${TIMESTAMP},${CLIENT},${EVENT},${REAL_IP},${IP},${DURATION},${CONNECT_TIME_SHORT},${TIME_SHORT}" >> "$CSV_LOG"
fi

[ "$FILTRADO" = "1" ] && exit 0

case "$EVENT" in
  client-connect)
    SUBJECT="[$HOSTNAME] [+] $CLIENT conectou na VPN"
    BODY="=====================================
 [+] USUARIO CONECTOU NA VPN
=====================================
 Usuario  : $CLIENT
 IP Real  : $REAL_IP
 IP VPN   : $IP
 Horario  : $TIME
=====================================
 $HOSTNAME"
    printf "==============================\n[+] OpenVPN - Conexao estabelecida\n==============================\nUsuario  : %s\nIP Pub   : %s\nIP VPN   : %s\nHorario  : %s\n==============================\n%s\n" \
      "$CLIENT" "$REAL_IP" "$IP" "$TIME_SHORT" "$HOSTNAME" > "$TMP_MSG"
    ;;
  client-disconnect)
    SUBJECT="[$HOSTNAME] [-] $CLIENT desconectou da VPN"
    BODY="=====================================
 [-] USUARIO DESCONECTOU DA VPN
=====================================
 Usuario      : $CLIENT
 IP Real      : $REAL_IP
 IP VPN       : $IP
 Conectou em  : $CONNECT_TIME
 Desconectou  : $TIME
 Duracao      : $DURACAO_FORMATADA
=====================================
 $HOSTNAME"
    printf "==============================\n[-] OpenVPN - Conexao encerrada\n==============================\nUsuario  : %s\nIP Pub   : %s\nIP VPN   : %s\nPeriodo  : %s -> %s\nDuracao  : %s\n==============================\n%s\n" \
      "$CLIENT" "$REAL_IP" "$IP" "$CONNECT_TIME_SHORT" "$TIME_SHORT" "$DURACAO_FORMATADA" "$HOSTNAME" > "$TMP_MSG"
    ;;
  *)
    exit 0
    ;;
esac

echo "$BODY" | /usr/local/bin/php /usr/local/bin/mail.php -s"$SUBJECT"

curl -s "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
  -d "chat_id=${TELEGRAM_CHAT}" \
  --data-urlencode "text@${TMP_MSG}" \
  > /dev/null 2>&1

rm -f "$TMP_MSG"
