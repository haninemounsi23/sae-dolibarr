# Restauration de Dolibarr

## Objectif

Remettre Dolibarr en service à partir d’une sauvegarde.
Le test utilise le projet Docker sae-dolibarr-auto-pra
et le port 8083.

## Prérequis

- Docker et Docker Compose installés.
- Fichier compose.pra.yaml présent.
- Fichier .env renseigné avec les identifiants compatibles
  avec la configuration sauvegardée.
- Sauvegarde disponible dans sauvegardes/auto :
  dolibarr.sql, documents/, custom/ et configuration/conf.php.

Les commandes suivantes sont à exécuter depuis le dossier
sae-dolibarr, dans un nouvel environnement de restauration.

## 1. Démarrer la base

```bash
sudo docker compose -p sae-dolibarr-auto-pra -f compose.pra.yaml up -d --wait mariadb
```

## 2. Restaurer la base

```bash
sudo docker compose -p sae-dolibarr-auto-pra -f compose.pra.yaml exec -T mariadb sh -c \
'exec mariadb -u root -p"$MARIADB_ROOT_PASSWORD" dolibarr' \
< sauvegardes/auto/dolibarr.sql
```

## 3. Préparer Dolibarr

Dans compose.pra.yaml, vérifier :
- DOLI_INSTALL_AUTO vaut "0" ;
- le port publié est 127.0.0.1:8083:80 ;
- DOLI_URL_ROOT vaut http://localhost:8083.

```bash
sudo docker compose -p sae-dolibarr-auto-pra -f compose.pra.yaml create dolibarr
```

## 4. Restaurer les fichiers

```bash
sudo docker compose -p sae-dolibarr-auto-pra -f compose.pra.yaml cp \
sauvegardes/auto/documents/. dolibarr:/var/www/documents/
```

```bash
sudo docker compose -p sae-dolibarr-auto-pra -f compose.pra.yaml cp \
sauvegardes/auto/custom/. dolibarr:/var/www/html/custom/
```

```bash
sudo docker compose -p sae-dolibarr-auto-pra -f compose.pra.yaml cp \
sauvegardes/auto/configuration/conf.php dolibarr:/var/www/html/conf/conf.php
```

## 5. Démarrer et adapter la configuration

```bash
sudo docker compose -p sae-dolibarr-auto-pra -f compose.pra.yaml start dolibarr
```

```bash
sudo docker compose -p sae-dolibarr-auto-pra -f compose.pra.yaml exec --user root dolibarr \
sed -i 's/localhost:8082/localhost:8083/g' /var/www/html/conf/conf.php
```

```bash
sudo docker compose -p sae-dolibarr-auto-pra -f compose.pra.yaml exec --user root dolibarr \
chown -R www-data:www-data /var/www/documents /var/www/html/custom /var/www/html/conf/conf.php
```

```bash
sudo docker compose -p sae-dolibarr-auto-pra -f compose.pra.yaml exec --user root dolibarr \
chmod 600 /var/www/html/conf/conf.php
```

## 6. Vérifier le résultat

Ouvrir http://localhost:8083 et se connecter avec le compte
administrateur et son mot de passe au moment de la sauvegarde.

Dans Tiers, vérifier la présence des trois clients et
des deux fournisseurs.

Test réalisé le 1er octobre 2026.
Redémarrage et présence des cinq tiers vérifiés à nouveau
le 3 octobre 2026.

![Résultat de la restauration](restauration-pra.png)


