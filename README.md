<div align="center">

# 🔐 pfSense OpenVPN Notify

Sistema de notificação de eventos OpenVPN para pfSense via **Telegram** e **e-mail**, com **relatório diário** detalhado por usuário.

[![Shell Script](https://img.shields.io/badge/Shell-sh-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![pfSense](https://img.shields.io/badge/pfSense-2.6+-212121?style=for-the-badge&logo=pfsense&logoColor=white)](https://www.pfsense.org/)
[![Telegram](https://img.shields.io/badge/Telegram-Bot-26A5E4?style=for-the-badge&logo=telegram&logoColor=white)](https://core.telegram.org/bots)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](LICENSE)

</div>

---

## ✨ Funcionalidades

| Funcionalidade | Descrição |
|---|---|
| ✅ Notificação imediata | Telegram + e-mail ao conectar/desconectar |
| ✅ Filtro por usuário | Clientes ruidosos podem ser silenciados |
| ✅ Relatório diário | Enviado às 08h com detalhamento por sessão |
| ✅ Histórico em CSV | Log completo para auditoria |
| ✅ Duração formatada | Ex: `1h25min` ou `8min` |

---

## 📸 Exemplo de notificações

**Conexão estabelecida:**
```
==============================
[+] OpenVPN - Conexao estabelecida
==============================
Usuario  : joao.moraes
IP Pub   : 200.x.x.x
IP VPN   : 10.0.0.x
Horario  : 14:45
==============================
pfsense.suaempresa.com.br
```

**Conexão encerrada:**
```
==============================
[-] OpenVPN - Conexao encerrada
==============================
Usuario  : joao.moraes
IP Pub   : 200.x.x.x
IP VPN   : 10.0.0.x
Periodo  : 14:45 -> 15:30
Duracao  : 45min
==============================
pfsense.suaempresa.com.br
```

**Relatório diário:**
```
Relatorio VPN - 08/06/2026

Conexoes: 3 | Desconexoes: 3

Detalhamento:
• joao.moraes — 2x
  08:32 -> 09:15 (43min) — 200.x.x.x
  14:10 -> 14:55 (45min) — 200.x.x.x

• usuario.vpn — 1x
  10:05 -> 11:30 (1h25min) — 186.x.x.x
```

---

## 📋 Pré-requisitos

- ✅ pfSense com OpenVPN configurado
- ✅ Pacote **Cron** instalado (`System → Package Manager`)
- ✅ SMTP configurado (`System → Advanced → Notifications`)
- ✅ Bot do Telegram criado via [@BotFather](https://t.me/BotFather)
- ✅ Chat ID do grupo ou usuário destinatário

---

## 🤖 Criando o Bot e obtendo o Chat ID

### 1. Criar o bot

1. Abra o Telegram e acesse [@BotFather](https://t.me/BotFather)
2. Digite `/newbot`
3. Escolha um nome e um username para o bot (ex: `MinhaEmpresa Sense` / `@minhaempresa_bot`)
4. O BotFather retornará o **token** — guarde-o, é o `TELEGRAM_TOKEN`

### 2. Obter o Chat ID com @userinfobot

A forma mais simples de obter o Chat ID é usando o bot **[@userinfobot](https://t.me/userinfobot)**:

**Para obter seu Chat ID pessoal:**
1. Acesse [@userinfobot](https://t.me/userinfobot)
2. Clique em **User** no menu inferior
3. O bot retornará seu `Id` — esse é o seu Chat ID pessoal

**Para obter o Chat ID de um grupo:**
1. Acesse [@userinfobot](https://t.me/userinfobot)
2. Compartilhe o grupo desejado com o bot (botão **Group** no menu)
3. O bot retornará o `Id` do grupo — geralmente começa com `-100`

> 💡 O Chat ID de grupos começa com `-` (negativo). Exemplo: `-100xxxxxxxxxx`

---

## 🚀 Instalação

### 1. Copiar os scripts para o pfSense

Via **Diagnostics → Edit File**, carregue cada caminho, cole o conteúdo e salve:

```
/usr/local/sbin/openvpn-notify.sh
/usr/local/sbin/openvpn-daily-report.sh
```

### 2. Configurar token e chat_id

Em ambos os scripts, substitua:

```sh
TELEGRAM_TOKEN="SEU_TOKEN_AQUI"
TELEGRAM_CHAT="SEU_CHAT_ID_AQUI"
```

### 3. Configurar usuários filtrados

No `openvpn-notify.sh`, edite a variável `SKIP_USERS`:

```sh
# Para adicionar mais usuários, separe por espaço:
# SKIP_USERS="usuario1.vpn usuario2.vpn usuario3.vpn"
SKIP_USERS="usuario.filtrado"
```

> ⚠️ Usuários nessa lista não geram notificação imediata e não aparecem no relatório diário.

### 4. Dar permissão de execução

Via **Diagnostics → Command Prompt**:

```bash
chmod +x /usr/local/sbin/openvpn-notify.sh
chmod +x /usr/local/sbin/openvpn-daily-report.sh
```

### 5. Criar o arquivo de log CSV

```bash
touch /var/log/openvpn-events.csv
```

### 6. Configurar o script no OpenVPN

Acesse **VPN → OpenVPN → Servers → Edit** e nos campos:
- **Client Connect Script:** `/usr/local/sbin/openvpn-notify.sh`
- **Client Disconnect Script:** `/usr/local/sbin/openvpn-notify.sh`

### 7. Configurar o relatório diário via Cron

Acesse **Services → Cron → Add** e preencha:

| Campo   | Valor |
|---------|-------|
| Minuto  | `0` |
| Hora    | `8` |
| Dia     | `*` |
| Mês     | `*` |
| DiaSem  | `*` |
| Usuário | `root` |
| Comando | `/usr/local/sbin/openvpn-daily-report.sh` |

---

## 📁 Estrutura do CSV

O arquivo `/var/log/openvpn-events.csv` grava todos os eventos no formato:

```
2026-06-08 14:45:00,joao.moraes,client-connect,200.x.x.x,10.0.0.x,0,14:45,14:45
2026-06-08 15:30:00,joao.moraes,client-disconnect,200.x.x.x,10.0.0.x,2700,14:45,15:30
```

**Campos:** `timestamp, usuario, evento, ip_publico, ip_vpn, duracao_segundos, hora_inicio, hora_fim`

---

## 🧪 Testando

**Testar o relatório diário:**
```bash
sh /usr/local/sbin/openvpn-daily-report.sh
```

**Simular um evento de conexão:**
```bash
script_type="client-connect" \
common_name="joao.moraes" \
ifconfig_pool_remote_ip="10.0.0.x" \
trusted_ip="200.x.x.x" \
time_duration="0" \
time_ascii="2026-06-08 14:00:00" \
sh /usr/local/sbin/openvpn-notify.sh
```

---

## 👤 Autor

**João Moraes** — [@jmoraes18](https://github.com/jmoraes18)

---

## 📄 Licença

Distribuído sob a licença MIT. Veja [LICENSE](LICENSE) para mais detalhes.
