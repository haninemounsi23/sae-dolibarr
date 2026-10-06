# Journal de bord

* TITRE PROJET : SAE Dolibarr
* NOM CHEF DE PROJET : Hanine Mounsi
* NOMS AUTRE MEMBRES EQUIPE : Adam Benadouche
* DATE DEBUT : 24 septembre 2026


## Séance n° 1

* date - heure : 24 septembre 2026
* Travail effectué :
  - Installation de Docker et Docker Compose sur Ubuntu.
  - Déploiement de Dolibarr et MariaDB dans deux conteneurs.
  - Installation manuelle de Dolibarr depuis le navigateur.
  - Création des comptes administrateur et utilisateur standard.
  - Activation du module Tiers et création du client de test.
  - Vérification des droits du compte utilisateur.
  - Premier essai d'import CSV.

* A faire à la prochaine séance :
  - Corriger le fichier CSV.
  - Valider la simulation de l'import.
  - Importer les clients et fournisseurs dans Dolibarr.
  - Continuer la configuration du projet.

* Difficultés rencontrées :
  - Erreur lors du premier import CSV sur le champ `fk_stcomm`.

* Remarques sur la séances (membre absent, pbe technique, ...) :
  - L'installation manuelle de Dolibarr fonctionne.
  - Les comptes administrateur et utilisateur standard ont été créés et testés.


## Séance n° 2

* date - heure : 29 septembre 2026
* Travail effectué :
  - Correction du fichier CSV et validation de la simulation.
  - Import de trois clients et deux fournisseurs.
  - Activation du module Fournisseurs.
  - Vérification des six tiers présents dans l'installation manuelle.
  - Initialisation du dépôt Git sur la branche `main`.
  - Déplacement des mots de passe dans un fichier `.env` ignoré par Git.
  - Correction et validation du fichier `compose.yaml`.

* A faire à la prochaine séance :
  - Rédiger le fichier `readme.md`.
  - Automatiser l'installation avec `install.sh`.
  - Automatiser l'import avec `import_csv.sh`.
  - Sauvegarder les données et tester une restauration complète.
  - Documenter les tests et publier le dépôt Git.

* Difficultés rencontrées :
  - Correction du fichier CSV nécessaire pour obtenir un import valide.
  - Vérification de la configuration Docker Compose et du fichier `.env`.

* Remarques sur la séances (membre absent, pbe technique, ...) :
  - L'import manuel fonctionne.
  - L'installation manuelle contient six tiers : un client créé manuellement et cinq tiers importés.


## Séance n° 3

* date - heure : 30 septembre 2026
* Travail effectué :
  - Installation automatique de Dolibarr sur le port `8082` avec `install.sh`.
  - Création du script `import_csv.sh`.
  - Simulation réussie avec le fichier `tiers_sae.csv`.
  - Import de trois clients et deux fournisseurs.
  - Deuxième exécution du script d'import.
  - Vérification qu'aucun doublon n'a été créé.
  - Vérification des cinq tiers dans l'interface Dolibarr.

* A faire à la prochaine séance :
  - Effectuer une sauvegarde complète de l'installation automatique.
  - Tester une restauration complète.
  - Finaliser la documentation.
  - Mettre à jour le dépôt Git.

* Difficultés rencontrées :
  - Mise au point du script d'installation automatique.
  - Vérification du fonctionnement du script d'import sans création de doublons.

* Remarques sur la séances (membre absent, pbe technique, ...) :
  - L'installation automatique fonctionne sur le port `8082`.
  - Le script d'import permet d'ajouter les cinq tiers sans générer de doublons lors d'une deuxième exécution.


## Séance n° 4

* date - heure : 1er octobre 2026 - après-midi
* Travail effectué :
  - Synchronisation du projet avec GitHub par SSH.
  - Suppression du README vide présent en doublon.
  - Sauvegarde de la base de données.
  - Sauvegarde des documents.
  - Sauvegarde des modules personnalisés.
  - Sauvegarde de la configuration.
  - Mise en place d'un environnement Docker séparé pour tester la restauration.
  - Restauration des données sur une nouvelle instance accessible sur le port `8083`.
  - Vérification de la connexion avec le compte administrateur.
  - Vérification de la présence des cinq tiers après restauration.

* A faire à la prochaine séance :
  - Conserver une capture du résultat de la restauration.
  - Compléter la documentation.
  - Publier cette avancée sur GitHub.

* Difficultés rencontrées :
  - MariaDB était arrêté au début de la sauvegarde.
  - Une option incorrecte dans une commande Docker a dû être corrigée.
  - Adaptation du port de l'environnement de restauration.
  - Correction des permissions de certains fichiers restaurés.

* Remarques sur la séances (membre absent, pbe technique, ...) :
  - L'environnement de restauration utilise ses propres conteneurs et volumes.
  - L'environnement de restauration est accessible sur le port `8083`.
  - Les cinq tiers sont bien présents après la restauration.


## Séance n° 5

* date - heure : 3 octobre 2026 - à partir de 16 h 21
* Travail effectué :
  - Reprise du projet.
  - Redémarrage de l'environnement de restauration.
  - Vérification de la connexion administrateur.
  - Vérification de la présence des trois clients et des deux fournisseurs sur le port `8083`.
  - Capture du résultat de la restauration.
  - Mise à jour de la documentation.
  - Création d'un `Dockerfile` basé sur Dolibarr `24.0.0`.
  - Adaptation de Docker Compose pour utiliser le `Dockerfile`.
  - Adaptation du script `install.sh` pour construire l'image Docker.
  - Construction et démarrage de la nouvelle image testés.
  - Vérification de la connexion à Dolibarr.
  - Vérification de la présence des cinq tiers après la modification.

* A faire à la prochaine séance :
  - Vérifier l'ensemble des livrables par rapport au sujet.
  - Compléter les éléments manquants.
  - Finaliser le fichier `readme.md`.
  - Vérifier les fichiers présents dans le dépôt GitHub.

* Difficultés rencontrées :
  - Aucune difficulté technique importante lors de la reprise.
  - Adaptation nécessaire de Docker Compose et de `install.sh` pour intégrer le nouveau `Dockerfile`.

* Remarques sur la séances (membre absent, pbe technique, ...) :
  - Les données restaurées sont toujours présentes après le redémarrage.
  - La construction de l'image Docker fonctionne.
  - Les cinq tiers restent présents après le démarrage de l'environnement basé sur le nouveau `Dockerfile`.
