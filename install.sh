#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

if [ ! -f .env ]; then
  echo "Erreur : crée le fichier .env avant de lancer l'installation."
  exit 1
fi

docker compose version >/dev/null
docker info >/dev/null

echo "Vérification de la configuration..."
docker compose -p sae-dolibarr-auto -f compose.auto.yaml config --quiet

echo "Démarrage de MariaDB et installation de Dolibarr..."
docker compose -p sae-dolibarr-auto -f compose.auto.yaml up -d

echo "Conteneurs démarrés. L'installation peut encore prendre quelques minutes."
echo "Adresse : http://localhost:8082"
echo "Identifiant : admin"
