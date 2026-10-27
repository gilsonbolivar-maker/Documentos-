# 📨 Central de Mensagens

**WhatsApp + Messenger + Signal num app só, num servidor seu, lendo sem mostrar "visto".**

```
 WhatsApp ─┐
 Messenger ─┼─► [Pontes mautrix] ─► [Synapse] ─► Element (navegador / iPad / celular)
 Signal ───┘                                        "confirmação de leitura" DESLIGADA
```

## 🔑 Por que você lê sem marcar como lida

| Peça | O que faz |
|---|---|
| **Element** | Já vem com **"Enviar confirmações de leitura" desligado** |
| **Synapse** | Guarda a sua leitura como **privada**, então as pontes não ficam sabendo |
| **Pontes** | Só avisam o WhatsApp, o Messenger e o Signal quando recebem uma leitura **pública** |

➡️ O outro lado continua vendo **✔✔ cinza**.

---

## 🧰 O que você precisa

| Item | Sugestão | Custo |
|---|---|---|
| **Servidor (VPS)** | Hetzner, Contabo, Hostinger: **2 GB de RAM**, Ubuntu | ~R$25–50/mês |
| **Domínio** | `duckdns.org` (grátis), ex.: `gilson.duckdns.org` | Grátis |
| **Docker** | Instalado no VPS | Grátis |

---

## 🚀 Instalação (uma vez)

1. **Aponte o domínio** para o IP do VPS (no DuckDNS: cole o IP e salve)
2. **Entre no VPS** e instale o Docker:
   ```bash
   curl -fsSL https://get.docker.com | sh
   ```
3. **Baixe o projeto:**
   ```bash
   git clone https://github.com/gilsonbolivar-maker/documentos-.git
   cd documentos-/central-mensagens
   ```
4. **Configure:**
   ```bash
   cp .env.example .env
   nano .env        # coloque seu DOMAIN e ADMIN
   ```
5. **Gere tudo e suba:**
   ```bash
   ./setup.sh
   docker compose up -d
   ```
6. **Crie seu usuário** (ele pede uma senha):
   ```bash
   docker compose exec synapse register_new_matrix_user \
     -c /data/homeserver.yaml -u SEU_ADMIN -a http://localhost:8008
   ```
7. **Abra** `https://SEU_DOMINIO` e entre com o usuário e a senha que você criou

---

## 🔌 Conectar cada app

No Element: **iniciar conversa** com o robô da ponte e mandar `login`.

| App | Converse com | Como entra |
|---|---|---|
| **WhatsApp** | `@whatsappbot:SEU_DOMINIO` | `login` → escaneie o **QR** em *WhatsApp → Aparelhos conectados* |
| **Signal** | `@signalbot:SEU_DOMINIO` | `login` → escaneie o **QR** em *Signal → Aparelhos conectados* |
| **Messenger** | `@metabot:SEU_DOMINIO` | `login` → o robô pede os **cookies** do Facebook e explica como pegar |

As conversas vão aparecendo sozinhas. ✅

---

## 📱 Usar no iPad ou no celular

1. Instale o app **Element** (App Store)
2. **Servidor:** `SEU_DOMINIO` → entre
3. ⚠️ **Obrigatório:** *Configurações → Preferências* → **desligue "Enviar confirmações de leitura"** (e "digitando")

> No navegador isso já vem desligado. **No app, você precisa desligar à mão.**

---

## ✅ Teste antes de confiar

1. Peça pra alguém mandar uma mensagem no WhatsApp
2. Leia no Element
3. Confira se, do lado da pessoa, ficou **✔✔ cinza**

## ⚠️ Avisos

- **Responder** a mensagem normalmente faz ela aparecer como lida
- **Abra o WhatsApp no celular** pelo menos a cada 14 dias, senão a conexão cai
- Usar cliente não oficial tem **risco pequeno de bloqueio** pela Meta
- **Backup:** a pasta `data/` guarda tudo. Copie essa pasta de vez em quando.

## 🛠️ Comandos úteis

| Ação | Comando |
|---|---|
| Ver logs | `docker compose logs -f whatsapp` |
| Reiniciar | `docker compose restart` |
| Atualizar | `docker compose pull && docker compose up -d` |
