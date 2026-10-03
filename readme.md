# SAE — Déploiement de Dolibarr

Équipe : Hanine Mounsi et Adam Benadouche.

## Objectif

Déployer Dolibarr avec une base MariaDB séparée, automatiser
l’installation et l’import de clients et fournisseurs depuis
un fichier CSV, puis tester la sauvegarde et la restauration.

## Environnement

- Ubuntu 24.04.
- Docker et Docker Compose V2.
- Dolibarr 24.0.0.
- MariaDB 11.4.
- Deux conteneurs : application et base de données.

| Installation | Adresse | Configuration |
|---|---|---|
| Manuelle, première découverte | http://localhost:8080 | compose.yaml |
| Automatique | http://localhost:8082 | compose.auto.yaml |
| Test de restauration | http://localhost:8083 | compose.pra.yaml |

Chaque projet Docker utilise ses propres volumes.

## Travail réalisé

- Installation manuelle de Dolibarr.
- Création de comptes administrateur et utilisateur standard.
- Test des droits d’accès aux tiers.
- Import manuel de données CSV.
- Installation automatique avec install.sh.
- Import automatisé avec import_csv.sh.
- Test d’un second import sans création de doublons.
- Sauvegarde de la base, des fichiers et de la configuration.
- Restauration dans un environnement Docker séparé.
- Documentation et suivi du travail sur GitHub.

L’installation manuelle contient six tiers :
un client créé manuellement et cinq tiers importés.

L’installation automatique et l’environnement restauré
contiennent les cinq tiers du CSV : trois clients et
deux fournisseurs.

## Installation automatique

### Prérequis

Git, Docker et Docker Compose V2 doivent être installés.
Le script install.sh vérifie Docker mais ne l’installe pas.

### Récupérer le projet

Sur une nouvelle machine :

```bash
git clone https://github.com/haninemounsi23/sae-dolibarr.git
cd sae-dolibarr
```

### Configurer les mots de passe

```bash
cp .env.example .env
chmod 600 .env
nano .env
```

Remplacer les valeurs d’exemple par les mots de passe choisis :

```dotenv
MARIADB_ROOT_PASSWORD=mot_de_passe_root_a_remplacer
MARIADB_PASSWORD=mot_de_passe_base_a_remplacer
DOLI_ADMIN_PASSWORD=mot_de_passe_admin_a_remplacer
```

Le fichier .env contient les secrets et est exclu du dépôt Git.
Le fichier .env.example sert de modèle.

### Démarrer

```bash
chmod +x install.sh import_csv.sh
sudo ./install.sh
```

Le script vérifie la configuration, construit l’image locale
et démarre les services. L’installation de Dolibarr peut
continuer quelques minutes après la fin du script.

Ouvrir http://localhost:8082.

- Identifiant : admin.
- Mot de passe : valeur de DOLI_ADMIN_PASSWORD utilisée
  lors de la première installation.

Activer la gestion des tiers et des fournisseurs dans
la configuration des modules si nécessaire.

Modifier DOLI_ADMIN_PASSWORD dans .env ne change pas
le mot de passe d’un compte déjà créé. Pour un compte
existant, utiliser l’interface Dolibarr.

## Import automatique du CSV

Le fichier data/tiers_sae.csv contient cinq tiers fictifs :
trois clients et deux fournisseurs.

### Simuler l’import

```bash
sudo ./import_csv.sh --simulate data/tiers_sae.csv
```

La simulation ne conserve pas les tiers dans la base.

### Effectuer l’import

Si la simulation réussit :

```bash
sudo ./import_csv.sh data/tiers_sae.csv
```

Ouvrir ensuite la rubrique Tiers sur http://localhost:8082.

### Résultats des tests

- Premier import : cinq tiers ajoutés.
- Second import du même fichier : cinq tiers existants ignorés.
- Aucun doublon créé lors de ce second import.

## Construction Docker

Le Dockerfile utilise l’image dolibarr/dolibarr:24.0.0
et ajoute les informations du projet.

Le fichier compose.auto.yaml utilise build: . pour construire
l’image locale sae-dolibarr:24.0.0.

Le script install.sh utilise l’option --build pour construire
l’image avant de démarrer les services.

## Stockage et sauvegarde

Les données sont conservées dans trois volumes :

| Volume | Contenu |
|---|---|
| db_data | Base MariaDB |
| documents | Documents Dolibarr |
| custom | Modules personnalisés |

La sauvegarde comprend :
- un export SQL de la base ;
- les documents ;
- les modules personnalisés ;
- la configuration nécessaire à la remise en service.

Les sauvegardes sont exclues du dépôt Git.

## Test de restauration — PRA

Le PRA, ou plan de reprise d’activité, permet de remettre
Dolibarr en service à partir d’une sauvegarde.

Le 1er octobre 2026, une restauration a été réalisée dans
le projet Docker sae-dolibarr-auto-pra, accessible sur
http://localhost:8083.

La base a été importée, les fichiers recopiés et la configuration
adaptée au port 8083.

Résultats :
- connexion administrateur réussie ;
- trois clients et deux fournisseurs présents.

Le 3 octobre 2026, le redémarrage de cet environnement
et la présence des cinq tiers ont été vérifiés à nouveau.

![Dolibarr après restauration](docs/restauration-pra.png)

## Documentation

- [Procédure de sauvegarde](docs/sauvegarde.md)
- [Procédure de restauration](docs/restauration.md)
- [Journal de bord](suivi_projet.md)
