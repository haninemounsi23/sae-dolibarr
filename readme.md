# SAE — Déploiement de Dolibarr

## Objectif
Déployer Dolibarr avec une base MariaDB séparée, gérer des clients
et fournisseurs, puis automatiser l'installation, l'import CSV
et la sauvegarde/restauration.

## Environnement
- Ubuntu 24.04
- Docker et Docker Compose v2
- Dolibarr et MariaDB dans deux conteneurs
- Accès local : http://localhost:8080

## Configuration
Le fichier compose.yaml décrit les services et les volumes.
Les mots de passe sont placés dans .env, exclu du dépôt Git.
Le fichier .env.example fournit les variables à renseigner.

## État du projet
- Installation manuelle réalisée.
- Comptes administrateur et utilisateur standard créés.
- Accès aux tiers testé avec le compte standard.
- Trois clients et deux fournisseurs importés par CSV.
- Six tiers présents, avec le client créé manuellement.

## Stockage
- db_data : base MariaDB.
- documents : documents Dolibarr.
- custom : extensions personnalisées.

La sauvegarde complète et la restauration restent à mettre en place
et à tester.

## Travail restant
- Script install.sh.
- Script import_csv.sh.
- Sauvegarde et test de restauration complète.
- Documentation des procédures et des tests.

## Journal
Voir suivi_projet.md pour les étapes réalisées.



## Test de restauration — PRA

Le PRA (plan de reprise d’activité) permet de remettre
Dolibarr en service à partir d’une sauvegarde.

Éléments sauvegardés :
- base MariaDB dans dolibarr.sql ;
- documents ;
- modules personnalisés ;
- configuration conf.php, compose.auto.yaml et .env.

La restauration a été réalisée dans un environnement Docker
séparé, nommé sae-dolibarr-auto-pra, accessible sur
http://localhost:8083.

La base a été importée, les fichiers restaurés et les
permissions adaptées au serveur web.

Vérification du 3 octobre 2026 :
- connexion avec le compte administrateur réussie ;
- trois clients et deux fournisseurs présents.

![Dolibarr après restauration](docs/restauration-pra.png)

Les sauvegardes et le fichier .env sont exclus du dépôt Git
car ils peuvent contenir des informations confidentielles.
