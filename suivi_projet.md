# Suivi du projet SAE Dolibarr

## 24 septembre 2026
- Installation de Docker et Docker Compose sur Ubuntu.
- Déploiement de Dolibarr et MariaDB dans deux conteneurs.
- Installation manuelle de Dolibarr depuis le navigateur.
- Création des comptes administrateur et utilisateur standard.
- Activation du module Tiers et création du client de test.
- Vérification des droits du compte utilisateur.
- Premier essai d'import CSV : erreur sur le champ fk_stcomm.

## 29 septembre 2026
- Correction du fichier CSV et validation de la simulation.
- Import de trois clients et deux fournisseurs.
- Activation du module Fournisseurs et vérification des six tiers.
- Initialisation du dépôt Git sur la branche main.
- Déplacement des mots de passe dans un fichier .env ignoré par Git.
- Correction et validation du fichier compose.yaml.

## Travail restant
- Rédiger le fichier readme.md.
- Automatiser l'installation avec install.sh.
- Automatiser l'import avec import_csv.sh.
- Sauvegarder les données et tester une restauration complète.
- Documenter les tests et publier le dépôt Git.
