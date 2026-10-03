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


## Séance n°4

- Date : 1er octobre 2026, après-midi.
- Travail effectué : synchronisation du projet avec GitHub par SSH et suppression du README vide en doublon. Sauvegarde de la base de données, des documents, des modules personnalisés et de la configuration. Restauration dans un environnement Docker séparé, accessible sur le port 8083. Connexion administrateur et présence des cinq tiers vérifiées.
- À faire à la prochaine séance : conserver une capture du résultat, compléter la documentation et publier cette avancée sur GitHub.
- Difficultés rencontrées : MariaDB était arrêté au début de la sauvegarde. Une option incorrecte dans une commande Docker a été corrigée. Adaptation du port et des permissions des fichiers restaurés.
- Remarques : l’environnement de restauration utilise ses propres conteneurs et volumes.

## Séance n°5

- Date : 3 octobre 2026, à partir de 16 h 21.
- Travail effectué : reprise du projet et redémarrage de l’environnement de restauration. Vérification de la connexion administrateur et des trois clients et deux fournisseurs sur le port 8083. Capture du résultat et mise à jour de la documentation.
- À faire à la prochaine séance : vérifier les livrables par rapport au sujet et compléter les éléments manquants.
- Difficultés rencontrées : aucune difficulté technique constatée lors de la reprise.
- Remarques : les données restaurées sont toujours présentes après le redémarrage.
- Création d’un Dockerfile basé sur Dolibarr 24.0.0.
- Adaptation de Compose et du script install.sh pour construire l’image.
- Construction et démarrage testés : connexion réussie et cinq tiers toujours présents.
