#!/usr/bin/env bash
# Gera e ajusta todas as configurações da Central de Mensagens.
# Uso (no servidor, como root):  ./setup.sh
set -euo pipefail
cd "$(dirname "$0")"

[ -f .env ] || { echo "Crie o .env primeiro:  cp .env.example .env  (e edite)"; exit 1; }
set -a; . ./.env; set +a
: "${DOMAIN:?defina DOMAIN no .env}" "${ADMIN:?defina ADMIN no .env}"

yq() {
	docker run --rm -i --user root -e DOMAIN -e ADMIN -e BRIDGE -e PORT \
		-v "$PWD/data:/workdir/data" mikefarah/yq:4 "$@"
}

mkdir -p data/synapse/bridges data/whatsapp data/meta data/signal data/element data/caddy

# 1. Synapse (servidor Matrix)
if [ ! -f data/synapse/homeserver.yaml ]; then
	echo ">> Gerando configuração do Synapse..."
	docker compose run --rm --no-deps \
		-e SYNAPSE_SERVER_NAME="$DOMAIN" -e SYNAPSE_REPORT_STATS=no \
		synapse generate
fi

# 2. Pontes: nome -> porta
declare -A PORTS=([whatsapp]=29318 [meta]=29319 [signal]=29328)

for bridge in whatsapp meta signal; do
	port=${PORTS[$bridge]}
	cfg=data/$bridge/config.yaml

	if [ ! -f "$cfg" ]; then
		echo ">> Gerando configuração da ponte $bridge..."
		docker compose run --rm --no-deps "$bridge" || true
	fi

	if [ ! -f "data/$bridge/registration.yaml" ]; then
		echo ">> Ajustando ponte $bridge..."
		export BRIDGE=$bridge PORT=$port
		yq -i '
			.homeserver.address = "http://synapse:8008" |
			.homeserver.domain = strenv(DOMAIN) |
			.appservice.address = "http://" + strenv(BRIDGE) + ":" + strenv(PORT) |
			.appservice.hostname = "0.0.0.0" |
			.appservice.port = env(PORT) |
			.database.type = "sqlite3-fk-wal" |
			.database.uri = "file:/data/" + strenv(BRIDGE) + ".db?_txlock=immediate" |
			.bridge.permissions = {"*": "relay"} |
			.bridge.permissions[strenv(DOMAIN)] = "user" |
			.bridge.permissions["@" + strenv(ADMIN) + ":" + strenv(DOMAIN)] = "admin"
		' "$cfg"
		if [ "$bridge" = meta ]; then
			yq -i '.network.mode = "messenger"' "$cfg"
		fi

		echo ">> Gerando registro da ponte $bridge..."
		docker compose run --rm --no-deps "$bridge" || true
	fi

	cp "data/$bridge/registration.yaml" "data/synapse/bridges/$bridge.yaml"
	chmod 644 "data/synapse/bridges/$bridge.yaml"
done

# 3. Synapse: liga as pontes, fecha cadastro, sem federação, sem "online"
yq -i '
	.app_service_config_files = [
		"/data/bridges/whatsapp.yaml",
		"/data/bridges/meta.yaml",
		"/data/bridges/signal.yaml"
	] |
	.enable_registration = false |
	.federation_domain_whitelist = [] |
	.presence.enabled = false
' data/synapse/homeserver.yaml
chmod 644 data/synapse/homeserver.yaml

# 4. Element (o app): confirmação de leitura e "digitando" DESLIGADOS por padrão
cat > data/element/config.json <<EOF
{
  "default_server_config": {
    "m.homeserver": { "base_url": "https://$DOMAIN", "server_name": "$DOMAIN" }
  },
  "disable_custom_urls": true,
  "disable_guests": true,
  "brand": "Central",
  "setting_defaults": {
    "sendReadReceipts": false,
    "sendTypingNotifications": false
  }
}
EOF

echo
echo "✅ Pronto! Agora rode:"
echo "   docker compose up -d"
echo "   docker compose exec synapse register_new_matrix_user -c /data/homeserver.yaml -u $ADMIN -a http://localhost:8008"
echo "Depois abra https://$DOMAIN"
