#!/bin/sh
# Desenvolvido e implantado por: João Moraes
# github.com/jmoraes18/pfsense-openvpn-notify

# ============================================================
# CONFIGURAÇÕES
# ============================================================
TELEGRAM_TOKEN="SEU_TOKEN_AQUI"
TELEGRAM_CHAT="SEU_CHAT_ID_AQUI"
CSV_LOG="/var/log/openvpn-events.csv"
HOSTNAME=$(hostname)

ONTEM=$(date -v-1d '+%Y-%m-%d')
ONTEM_BR=$(date -v-1d '+%d/%m/%Y')

# Filtrar linhas do dia anterior (apenas disconnects, que têm duração)
EVENTOS=$(grep "^${ONTEM}" "$CSV_LOG" 2>/dev/null | grep ",client-disconnect,")

TOTAL_CONNECT=$(grep "^${ONTEM}" "$CSV_LOG" 2>/dev/null | grep ",client-connect," | wc -l | tr -d ' ')
TOTAL_DISCONNECT=$(echo "$EVENTOS" | grep -c ",client-disconnect," | tr -d ' ')

# Montar detalhamento por usuário
DETALHAMENTO=""
USUARIOS=$(echo "$EVENTOS" | cut -d',' -f2 | sort -u)

for USER in $USUARIOS; do
    LINHAS=$(echo "$EVENTOS" | grep ",${USER},")
    TOTAL=$(echo "$LINHAS" | wc -l | tr -d ' ')
    DETALHAMENTO="${DETALHAMENTO}
• ${USER} — ${TOTAL}x"

    echo "$LINHAS" | while IFS=',' read TS UNAME EVENT REAL_IP VPN_IP DURATION HORA_INI HORA_FIM; do
        MINUTOS=$((DURATION / 60))
        if [ "$MINUTOS" -ge 60 ]; then
            HORAS=$((MINUTOS / 60))
            MINS=$((MINUTOS % 60))
            DUR_FMT="${HORAS}h${MINS}min"
        else
            DUR_FMT="${MINUTOS}min"
        fi
        DETALHAMENTO="${DETALHAMENTO}
  ${HORA_INI} -> ${HORA_FIM} (${DUR_FMT}) — ${REAL_IP}"
    done
done

# Montar mensagem
TG_MSG="Relatorio VPN - ${ONTEM_BR}

Conexoes: ${TOTAL_CONNECT} | Desconexoes: ${TOTAL_DISCONNECT}

Detalhamento:${DETALHAMENTO}

${HOSTNAME}"

BODY="=====================================
 RELATORIO DIARIO VPN - $ONTEM_BR
=====================================
 Conexoes    : $TOTAL_CONNECT
 Desconexoes : $TOTAL_DISCONNECT
=====================================
$DETALHAMENTO
=====================================
 $HOSTNAME"

# Enviar e-mail sempre
echo "$BODY" | /usr/local/bin/php /usr/local/bin/mail.php -s"[$HOSTNAME] Relatório VPN - $ONTEM_BR"

# Enviar Telegram sempre
curl -s "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
  -d "chat_id=${TELEGRAM_CHAT}" \
  -d "text=${TG_MSG}" \
  > /dev/null 2>&1
