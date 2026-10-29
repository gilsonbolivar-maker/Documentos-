#!/usr/bin/env bash
# Instalação completa da Central de Mensagens num Ubuntu da Oracle Cloud.
# Uso (no servidor):
#   curl -fsSL https://raw.githubusercontent.com/gilsonbolivar-maker/Documentos-/central-mensagens/central-mensagens/instala.sh -o instala.sh
#   sudo bash instala.sh gilsoncentral.duckdns.org gilson
set -euo pipefail

DOMAIN=${1:?informe o domínio, ex.: gilsoncentral.duckdns.org}
ADMIN=${2:-gilson}
DIR=/opt/central

[ "$(id -u)" = 0 ] || { echo "Rode com sudo"; exit 1; }

echo ">> 1/6 Liberando portas 80 e 443 no firewall interno..."
for port in 443 80; do
	iptables -C INPUT -p tcp --dport "$port" -j ACCEPT 2>/dev/null ||
		iptables -I INPUT 6 -p tcp -m state --state NEW --dport "$port" -j ACCEPT
done
command -v netfilter-persistent >/dev/null && netfilter-persistent save

echo ">> 2/6 Instalando Docker..."
command -v docker >/dev/null || curl -fsSL https://get.docker.com | sh

echo ">> 3/6 Baixando o projeto..."
if [ -d "$DIR/.git" ]; then
	git -C "$DIR" pull -q
else
	git clone -q -b central-mensagens https://github.com/gilsonbolivar-maker/Documentos-.git "$DIR"
fi
cd "$DIR/central-mensagens"

echo ">> 4/6 Configurando..."
printf 'DOMAIN=%s\nADMIN=%s\n' "$DOMAIN" "$ADMIN" > .env
./setup.sh

echo ">> 5/6 Subindo a central..."
docker compose up -d

echo ">> 6/6 Criando seu usuário..."
SENHA_FILE=data/senha-inicial.txt
if [ ! -f "$SENHA_FILE" ]; then
	SENHA=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 16)
	for i in $(seq 1 30); do
		if docker compose exec -T synapse register_new_matrix_user \
			-c /data/homeserver.yaml -u "$ADMIN" -p "$SENHA" -a http://localhost:8008 >/dev/null 2>&1; then
			echo "$SENHA" > "$SENHA_FILE"
			chmod 600 "$SENHA_FILE"
			break
		fi
		sleep 5
	done
fi

echo
if [ -f "$SENHA_FILE" ]; then
	echo "✅ PRONTO!"
	echo "   Endereço: https://$DOMAIN"
	echo "   Usuário:  $ADMIN"
	echo "   Senha:    $(cat "$SENHA_FILE")   (anote e troque depois no Element)"
else
	echo "⚠️ A central subiu, mas o usuário não foi criado. Veja: docker compose logs synapse"
fi
