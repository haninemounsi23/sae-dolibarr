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
