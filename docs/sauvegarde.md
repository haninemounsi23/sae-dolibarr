# Sauvegarde de Dolibarr

Exécuter les commandes depuis le dossier sae-dolibarr.
Utiliser un nouveau dossier pour chaque sauvegarde.

## 1. Préparer le dossier

```bash
sauvegarde="sauvegardes/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$sauvegarde/configuration"
chmod 700 "$sauvegarde" "$sauvegarde/configuration"
```

Conserver le même terminal pour les commandes suivantes.

## 2. Préparer les services

Démarrer MariaDB et arrêter temporairement Dolibarr pour
éviter les modifications pendant la sauvegarde.

```bash
sudo docker compose -p sae-dolibarr-auto -f compose.auto.yaml up -d --wait mariadb
sudo docker compose -p sae-dolibarr-auto -f compose.auto.yaml stop dolibarr
```

## 3. Sauvegarder la base

```bash
(
umask 077
sudo docker compose -p sae-dolibarr-auto -f compose.auto.yaml exec -T mariadb sh -c \
'exec mariadb-dump -u root -p"$MARIADB_ROOT_PASSWORD" --single-transaction --routines --events --triggers dolibarr' \
> "$sauvegarde/dolibarr.sql"
)
```

Si une commande échoue, corriger l’erreur avant de considérer
la sauvegarde comme utilisable.

## 4. Copier les fichiers

```bash
sudo docker compose -p sae-dolibarr-auto -f compose.auto.yaml cp \
dolibarr:/var/www/documents "$sauvegarde/documents"

sudo docker compose -p sae-dolibarr-auto -f compose.auto.yaml cp \
dolibarr:/var/www/html/custom "$sauvegarde/custom"

sudo docker compose -p sae-dolibarr-auto -f compose.auto.yaml cp \
dolibarr:/var/www/html/conf/conf.php "$sauvegarde/configuration/conf.php"

cp .env compose.auto.yaml Dockerfile install.sh "$sauvegarde/configuration/"
sudo chmod 600 "$sauvegarde/configuration/"*
chmod 600 "$sauvegarde/configuration/.env"
```

## 5. Redémarrer Dolibarr

```bash
sudo docker compose -p sae-dolibarr-auto -f compose.auto.yaml start dolibarr
```

## 6. Vérifier la sauvegarde

```bash
test -s "$sauvegarde/dolibarr.sql" && echo "Fichier SQL non vide"
sudo du -sh "$sauvegarde"
```

Ces contrôles vérifient la présence des fichiers.
Un test de restauration permet de vérifier leur utilisation.

Pour appliquer le guide de restauration, remplacer les chemins
sauvegardes/auto par le chemin du dossier daté choisi.

Conserver également une copie sur un autre support.
Les sauvegardes contiennent des données et des mots de passe :
elles ne doivent pas être publiées sur GitHub.
