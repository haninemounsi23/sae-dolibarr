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


## Séance du 30 septembre 2026

- Installation automatique de Dolibarr sur le port 8082 avec install.sh.
- Création du script import_csv.sh.
- Simulation réussie avec le fichier tiers_sae.csv.
- Import de 3 clients et 2 fournisseurs.
- Deuxième exécution : aucun doublon créé.
- Vérification des 5 tiers dans l’interface Dolibarr.

À poursuivre : sauvegarde et restauration complète de l’installation
automatique, puis finalisation de la documentation et du dépôt Git.
