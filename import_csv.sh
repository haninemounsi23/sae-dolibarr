#!/usr/bin/env bash
# SAE51 : import SQL des tiers, pour compose.auto.yaml / Dolibarr 24.
# Usage : sudo ./import_csv.sh [--simulate] data/tiers_sae.csv
# Necessite les conteneurs deja installes. PHP est execute dans Dolibarr.
# Les codes existants sont ignores si leur nom correspond ; aucun tiers
# existant n'est modifie. Les champs non pris en charge non vides sont refuses.
#
# EN RESUME : le script lit un fichier CSV de "tiers" (clients / fournisseurs)
# et les insere dans la base de donnees de Dolibarr. Il ne modifie jamais un
# tiers existant. Avec --simulate, il fait tout le travail puis annule
# (rollback) : on voit le resultat sans rien enregistrer.

# -e : stoppe à la première commande en erreur
# -u : erreur si on utilise une variable non définie
# -o pipefail : une erreur dans un pipe fait échouer tout le pipe
set -euo pipefail

# ---------------------------------------------------------------------------
# PARTIE 1 : SHELL (gestion des arguments, préparation de docker compose)
# ---------------------------------------------------------------------------

# Mode simulation désactivé par défaut (0 = import réel, 1 = simulation)
simulation=0
# Si le 1er argument est --simulate, on active le mode et on le retire
# de la liste des arguments (shift) pour que $1 devienne le chemin du CSV.
if [[ ${1:-} == --simulate ]]; then simulation=1; shift; fi

# Il doit rester exactement 1 argument (le CSV) et ce fichier doit être lisible.
# Sinon : message d'usage sur la sortie d'erreur (>&2) et code retour 1.
if [[ $# -ne 1 || ! -r $1 ]]; then
    echo "Usage : sudo $0 [--simulate] chemin/tiers_sae.csv" >&2
    exit 1
fi

# Chemin absolu du CSV (calculé AVANT le cd ci-dessous, sinon un chemin
# relatif ne pointerait plus au bon endroit).
csv=$(realpath -- "$1")

# On se place dans le dossier du script : c'est là que se trouve
# compose.auto.yaml.
cd -- "$(dirname -- "$0")"

# Commande docker compose stockée dans un tableau (bonne pratique pour
# éviter les problèmes d'espaces/quotes). -p = nom du projet, -f = fichier.
compose=(docker compose -p sae-dolibarr-auto -f compose.auto.yaml)

# Vérifie que le fichier compose est valide (--quiet = n'affiche rien
# sauf en cas d'erreur).
"${compose[@]}" config --quiet

# ---------------------------------------------------------------------------
# PARTIE 2 : le code PHP, stocké dans une variable shell
# ---------------------------------------------------------------------------
# Le <<'PHP' (avec quotes) empêche le shell d'interpréter quoi que ce soit
# dans le bloc : le PHP est transmis tel quel.

# Le code PHP utilise des requetes preparees : les donnees ne sont jamais
# interpretees comme du SQL. Une transaction annule tout en cas d'erreur.
php_code=$(cat <<'PHP'
// Fait lever une exception à toute erreur MySQL (au lieu d'un simple warning)
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

$db = null;            // connexion à la base (pas encore ouverte)
$transaction = false;  // indique si une transaction est en cours (pour le rollback)
$line = 1;             // n° de ligne CSV courante, pour les messages d'erreur

try {
    // $argv[1] = argument passé par le script shell ("1" = simulation)
    $simulate = ($argv[1] ?? '0') === '1';

    // Le CSV arrive sur l'entrée standard (grâce au "< $csv" en bas du script)
    $stream = fopen('php://stdin', 'r');

    // ---- 1) LECTURE ET VALIDATION DE L'EN-TETE --------------------------
    // Première ligne = noms des colonnes. Séparateur ',' / guillemet '"'.
    $headers = fgetcsv($stream, 0, ',', '"', '');
    if (!$headers) throw new RuntimeException('CSV vide.');

    $fields = []; // noms des colonnes de la table SQL, dans l'ordre du CSV
    foreach ($headers as $header) {
        // Chaque en-tête doit finir par "(s.nom_du_champ)", par exemple
        // "Nom (s.nom)". On extrait le nom du champ SQL entre parenthèses.
        if (!preg_match('/\(s\.([a-z0-9_]+)\)\s*$/', $header, $match)) {
            throw new RuntimeException('En-tete non reconnu : '.$header);
        }
        // Interdit d'avoir deux fois la même colonne
        if (in_array($match[1], $fields, true)) throw new RuntimeException('Colonne repetee.');
        $fields[] = $match[1];
    }

    // Colonnes obligatoires : le CSV doit toutes les contenir
    $required = ['nom', 'status', 'code_client', 'code_fournisseur', 'client', 'fournisseur'];
    foreach ($required as $field) {
        if (!in_array($field, $fields, true)) throw new RuntimeException('Colonne absente : '.$field);
    }

    // ---- 2) DEFINITION DES CHAMPS AUTORISES ------------------------------
    // Champs texte : insérés tels quels (vide => NULL en base)
    $textFields = ['nom','name_alias','code_client','code_fournisseur','address','zip','town',
        'phone','phone_mobile','fax','url','email','note_private','note_public','default_lang'];
    // Champs entiers, avec la liste des valeurs permises pour chacun
    // (ex : client = 0 non, 1 client, 2 prospect, 3 client+prospect)
    $integers = ['status'=>[0,1], 'client'=>[0,1,2,3], 'fournisseur'=>[0,1],
        'fk_stcomm'=>[-1,0,1,2,3], 'tva_assuj'=>[0,1], 'fk_multicurrency'=>[0]];
    // Liste blanche : tout champ rempli hors de cette liste sera refusé.
    // fk_pays est à part : le CSV donne un code pays (ex "FR") qu'on convertit
    // plus bas en identifiant numérique.
    $allowed = array_merge($textFields, array_keys($integers), ['fk_pays']);

    $rows = [];  // lignes validées, prêtes à être insérées
    $seen = [];  // codes déjà vus dans le CSV (détection de doublons)

    // ---- 3) LECTURE ET VALIDATION DE CHAQUE LIGNE (rien n'est écrit en base ici)
    while (($values = fgetcsv($stream, 0, ',', '"', '')) !== false) {
        $line++;
        if ($values === [null]) continue; // ligne vide : ignorée
        // Même nombre de cellules que de colonnes dans l'en-tête
        if (count($values) !== count($fields)) throw new RuntimeException('Nombre de colonnes incorrect.');

        // Associe nom de colonne => valeur, en supprimant les espaces autour
        $row = array_combine($fields, array_map('trim', $values));

        foreach ($row as $field => $value) {
            // Refuse tout texte qui n'est pas de l'UTF-8 valide
            if (!mb_check_encoding($value, 'UTF-8')) throw new RuntimeException('Encodage UTF-8 requis.');
            // Refuse une colonne inconnue SI elle contient une valeur
            // (une colonne inconnue mais vide est tolérée)
            if ($value !== '' && !in_array($field, $allowed, true)) {
                throw new RuntimeException('Champ rempli non pris en charge : '.$field);
            }
        }

        if ($row['nom'] === '') throw new RuntimeException('Nom vide.');

        // Validation des champs entiers
        foreach ($integers as $field => $choices) {
            $value = $row[$field] ?? '';
            // Valeur par défaut si vide : status = 1 (actif), les autres = 0
            if ($value === '') $value = ($field === 'status') ? '1' : '0';
            // Doit être un entier (éventuellement négatif) ET faire partie
            // des valeurs permises pour ce champ
            if (!preg_match('/^-?\d+$/', $value) || !in_array((int)$value, $choices, true)) {
                throw new RuntimeException('Valeur incorrecte pour '.$field);
            }
            $row[$field] = (int)$value;
        }

        // Un tiers doit être au moins client OU fournisseur
        if (!$row['client'] && !$row['fournisseur']) throw new RuntimeException('Ni client ni fournisseur.');

        // Pour chaque rôle (client / fournisseur) :
        foreach (['client'=>'code_client', 'fournisseur'=>'code_fournisseur'] as $flag=>$code) {
            // si le tiers a ce rôle, le code correspondant est obligatoire
            if ($row[$flag] && $row[$code] === '') throw new RuntimeException('Code manquant : '.$code);
            // si un code est présent, il doit être unique dans le CSV
            // (comparaison insensible à la casse)
            if ($row[$code] !== '') {
                $key = $code.':'.mb_strtolower($row[$code], 'UTF-8');
                if (isset($seen[$key])) throw new RuntimeException('Code repete dans le CSV : '.$row[$code]);
                $seen[$key] = true;
            }
        }
        // Ligne valide : on la garde avec son numéro de ligne
        $rows[] = [$line, $row];
    }
    if (!$rows) throw new RuntimeException('Aucune ligne de donnees.');

    // ---- 4) CONNEXION A LA BASE -----------------------------------------
    // Identifiants lus dans les variables d'environnement du conteneur
    // Dolibarr, avec des valeurs par défaut (mariadb / dolibarr).
    $db = new mysqli(getenv('DOLI_DB_HOST') ?: 'mariadb', getenv('DOLI_DB_USER') ?: 'dolibarr',
        getenv('DOLI_DB_PASSWORD'), getenv('DOLI_DB_NAME') ?: 'dolibarr');
    $db->set_charset('utf8mb4');
    // Mode SQL strict : une donnée trop longue/invalide = erreur, pas de
    // troncature silencieuse
    $db->query("SET SESSION sql_mode = 'STRICT_ALL_TABLES,NO_ENGINE_SUBSTITUTION'");

    // Vérifie que la table des tiers existe et est InnoDB (les transactions
    // et rollback ne fonctionnent qu'avec InnoDB)
    $engine = $db->query("SELECT ENGINE FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='llx_societe'")->fetch_row();
    if (strtoupper($engine[0] ?? '') !== 'INNODB') throw new RuntimeException('Table llx_societe absente ou non transactionnelle.');

    // Verrou applicatif nommé : empêche deux imports simultanés
    // (attend 10 secondes max, sinon erreur)
    if ((int)$db->query("SELECT GET_LOCK('sae_import_tiers', 10)")->fetch_row()[0] !== 1) {
        throw new RuntimeException('Un autre import est en cours.');
    }

    // ---- 5) REQUETES PREPAREES -------------------------------------------
    // Les "?" sont des paramètres : les valeurs sont envoyées séparément de
    // la requête, donc impossible de faire une injection SQL via le CSV.

    // Retrouver l'id d'un pays à partir de son code (ex "FR")
    $country = $db->prepare('SELECT rowid FROM llx_c_country WHERE code = ?');
    // Chercher un tiers existant ayant le même code client ou fournisseur
    $existing = $db->prepare('SELECT rowid, nom, code_client, code_fournisseur FROM llx_societe WHERE entity=1 AND (code_client=? OR code_fournisseur=?)');

    // Construction dynamique de l'INSERT : liste des colonnes + autant de "?"
    // que de colonnes, plus datec (date de création) = NOW()
    $columns = array_merge(['entity'], $textFields, array_keys($integers), ['fk_pays']);
    $sql = 'INSERT INTO llx_societe (`'.implode('`,`', $columns).'`,datec) VALUES ('.implode(',', array_fill(0, count($columns), '?')).',NOW())';
    $insert = $db->prepare($sql);

    // ---- 6) INSERTION DANS UNE TRANSACTION ---------------------------------
    // Tout ce qui suit est annulable d'un bloc
    $db->begin_transaction();
    $transaction = true;
    $added = 0;    // compteur de tiers ajoutés
    $skipped = 0;  // compteur de tiers déjà présents (ignorés)

    foreach ($rows as [$line, $row]) {
        // Prépare les données dans le même ordre que $columns
        $data = ['entity'=>1];
        // Texte vide => NULL
        foreach ($textFields as $field) $data[$field] = ($row[$field] ?? '') === '' ? null : $row[$field];
        foreach ($integers as $field=>$choices) $data[$field] = $row[$field];

        // Conversion du code pays (ex "FR") en identifiant numérique
        $data['fk_pays'] = null;
        if (($row['fk_pays'] ?? '') !== '') {
            $country->execute([strtoupper($row['fk_pays'])]);
            $found = $country->get_result()->fetch_all(MYSQLI_ASSOC);
            // Le code doit correspondre à exactement un pays
            if (count($found) !== 1) throw new RuntimeException('Code pays inconnu : '.$row['fk_pays']);
            $data['fk_pays'] = (int)$found[0]['rowid'];
        }

        // Ce code existe-t-il déjà en base ?
        $existing->execute([$data['code_client'], $data['code_fournisseur']]);
        $matches = $existing->get_result()->fetch_all(MYSQLI_ASSOC);
        if ($matches) {
            $old = $matches[0];
            // Cas toléré : UN SEUL tiers existant, avec le MEME nom et les
            // MEMES codes => c'est le même tiers, on l'ignore.
            // Tout autre cas (plusieurs correspondances, nom différent, code
            // différent) => le code appartient à un autre tiers : erreur.
            if (count($matches) !== 1 || $old['nom'] !== $row['nom']
                || ($data['code_client'] !== null && $old['code_client'] !== $data['code_client'])
                || ($data['code_fournisseur'] !== null && $old['code_fournisseur'] !== $data['code_fournisseur'])) {
                throw new RuntimeException('Code deja attribue a un autre tiers : '.$row['nom']);
            }
            $skipped++;
            continue; // on passe à la ligne suivante, sans insérer
        }

        // Nouveau tiers : insertion
        $insert->execute(array_values($data));
        $added++;
    }

    // ---- 7) FIN : VALIDER OU ANNULER ----------------------------------------
    // Simulation => rollback (rien n'est conservé) ; sinon commit (définitif)
    if ($simulate) $db->rollback(); else $db->commit();
    $transaction = false;

    // Message de résultat
    echo $simulate ? "SIMULATION OK : $added tiers a ajouter, $skipped deja presents. Aucun tiers conserve par cette simulation.\n"
                   : "IMPORT OK : $added tiers ajoutes, $skipped deja presents (non modifies).\n";
    $db->close();

} catch (Throwable $error) {
    // En cas d'erreur n'importe où : annule la transaction si elle est ouverte,
    // affiche l'erreur avec le n° de ligne CSV et sort avec le code 1.
    // (Tout ou rien : un seul tiers invalide => aucun n'est importé.)
    if ($db && $transaction) $db->rollback();
    fwrite(STDERR, "ECHEC (ligne CSV $line) : ".$error->getMessage()."\nImport non valide.\n");
    exit(1);
}
PHP
)

# ---------------------------------------------------------------------------
# PARTIE 3 : EXECUTION
# ---------------------------------------------------------------------------
# - "exec -T dolibarr" : lance une commande dans le conteneur "dolibarr"
#   (-T = pas de terminal, nécessaire car on lui envoie le CSV en entrée)
# - "php -r "$php_code"" : exécute le code PHP ci-dessus
# - "-- "$simulation"" : transmet 0 ou 1 au PHP (récupéré dans $argv[1])
# - "< "$csv"" : envoie le contenu du CSV sur l'entrée standard du conteneur
#   (c'est ce que lit php://stdin)
"${compose[@]}" exec -T dolibarr php -r "$php_code" -- "$simulation" < "$csv"
