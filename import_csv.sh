#!/usr/bin/env bash
# SAE51 : import SQL des tiers, pour compose.auto.yaml / Dolibarr 24.
# Usage : sudo ./import_csv.sh [--simulate] data/tiers_sae.csv
# Necessite les conteneurs deja installes. PHP est execute dans Dolibarr.
# Les codes existants sont ignores si leur nom correspond ; aucun tiers
# existant n'est modifie. Les champs non pris en charge non vides sont refuses.
set -euo pipefail

simulation=0
if [[ ${1:-} == --simulate ]]; then simulation=1; shift; fi
if [[ $# -ne 1 || ! -r $1 ]]; then
    echo "Usage : sudo $0 [--simulate] chemin/tiers_sae.csv" >&2
    exit 1
fi
csv=$(realpath -- "$1")
cd -- "$(dirname -- "$0")"
compose=(docker compose -p sae-dolibarr-auto -f compose.auto.yaml)
"${compose[@]}" config --quiet

# Le code PHP utilise des requetes preparees : les donnees ne sont jamais
# interpretees comme du SQL. Une transaction annule tout en cas d'erreur.
php_code=$(cat <<'PHP'
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);
$db = null;
$transaction = false;
$line = 1;
try {
    $simulate = ($argv[1] ?? '0') === '1';
    $stream = fopen('php://stdin', 'r');
    $headers = fgetcsv($stream, 0, ',', '"', '');
    if (!$headers) throw new RuntimeException('CSV vide.');
    $fields = [];
    foreach ($headers as $header) {
        if (!preg_match('/\(s\.([a-z0-9_]+)\)\s*$/', $header, $match)) {
            throw new RuntimeException('En-tete non reconnu : '.$header);
        }
        if (in_array($match[1], $fields, true)) throw new RuntimeException('Colonne repetee.');
        $fields[] = $match[1];
    }
    $required = ['nom', 'status', 'code_client', 'code_fournisseur', 'client', 'fournisseur'];
    foreach ($required as $field) {
        if (!in_array($field, $fields, true)) throw new RuntimeException('Colonne absente : '.$field);
    }
    $textFields = ['nom','name_alias','code_client','code_fournisseur','address','zip','town',
        'phone','phone_mobile','fax','url','email','note_private','note_public','default_lang'];
    $integers = ['status'=>[0,1], 'client'=>[0,1,2,3], 'fournisseur'=>[0,1],
        'fk_stcomm'=>[-1,0,1,2,3], 'tva_assuj'=>[0,1], 'fk_multicurrency'=>[0]];
    $allowed = array_merge($textFields, array_keys($integers), ['fk_pays']);
    $rows = [];
    $seen = [];
    while (($values = fgetcsv($stream, 0, ',', '"', '')) !== false) {
        $line++;
        if ($values === [null]) continue;
        if (count($values) !== count($fields)) throw new RuntimeException('Nombre de colonnes incorrect.');
        $row = array_combine($fields, array_map('trim', $values));
        foreach ($row as $field => $value) {
            if (!mb_check_encoding($value, 'UTF-8')) throw new RuntimeException('Encodage UTF-8 requis.');
            if ($value !== '' && !in_array($field, $allowed, true)) {
                throw new RuntimeException('Champ rempli non pris en charge : '.$field);
            }
        }
        if ($row['nom'] === '') throw new RuntimeException('Nom vide.');
        foreach ($integers as $field => $choices) {
            $value = $row[$field] ?? '';
            if ($value === '') $value = ($field === 'status') ? '1' : '0';
            if (!preg_match('/^-?\d+$/', $value) || !in_array((int)$value, $choices, true)) {
                throw new RuntimeException('Valeur incorrecte pour '.$field);
            }
            $row[$field] = (int)$value;
        }
        if (!$row['client'] && !$row['fournisseur']) throw new RuntimeException('Ni client ni fournisseur.');
        foreach (['client'=>'code_client', 'fournisseur'=>'code_fournisseur'] as $flag=>$code) {
            if ($row[$flag] && $row[$code] === '') throw new RuntimeException('Code manquant : '.$code);
            if ($row[$code] !== '') {
                $key = $code.':'.mb_strtolower($row[$code], 'UTF-8');
                if (isset($seen[$key])) throw new RuntimeException('Code repete dans le CSV : '.$row[$code]);
                $seen[$key] = true;
            }
        }
        $rows[] = [$line, $row];
    }
    if (!$rows) throw new RuntimeException('Aucune ligne de donnees.');

    $db = new mysqli(getenv('DOLI_DB_HOST') ?: 'mariadb', getenv('DOLI_DB_USER') ?: 'dolibarr',
        getenv('DOLI_DB_PASSWORD'), getenv('DOLI_DB_NAME') ?: 'dolibarr');
    $db->set_charset('utf8mb4');
    $db->query("SET SESSION sql_mode = 'STRICT_ALL_TABLES,NO_ENGINE_SUBSTITUTION'");
    $engine = $db->query("SELECT ENGINE FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='llx_societe'")->fetch_row();
    if (strtoupper($engine[0] ?? '') !== 'INNODB') throw new RuntimeException('Table llx_societe absente ou non transactionnelle.');
    if ((int)$db->query("SELECT GET_LOCK('sae_import_tiers', 10)")->fetch_row()[0] !== 1) {
        throw new RuntimeException('Un autre import est en cours.');
    }
    $country = $db->prepare('SELECT rowid FROM llx_c_country WHERE code = ?');
    $existing = $db->prepare('SELECT rowid, nom, code_client, code_fournisseur FROM llx_societe WHERE entity=1 AND (code_client=? OR code_fournisseur=?)');
    $columns = array_merge(['entity'], $textFields, array_keys($integers), ['fk_pays']);
    $sql = 'INSERT INTO llx_societe (`'.implode('`,`', $columns).'`,datec) VALUES ('.implode(',', array_fill(0, count($columns), '?')).',NOW())';
    $insert = $db->prepare($sql);
    $db->begin_transaction();
    $transaction = true;
    $added = 0;
    $skipped = 0;
    foreach ($rows as [$line, $row]) {
        $data = ['entity'=>1];
        foreach ($textFields as $field) $data[$field] = ($row[$field] ?? '') === '' ? null : $row[$field];
        foreach ($integers as $field=>$choices) $data[$field] = $row[$field];
        $data['fk_pays'] = null;
        if (($row['fk_pays'] ?? '') !== '') {
            $country->execute([strtoupper($row['fk_pays'])]);
            $found = $country->get_result()->fetch_all(MYSQLI_ASSOC);
            if (count($found) !== 1) throw new RuntimeException('Code pays inconnu : '.$row['fk_pays']);
            $data['fk_pays'] = (int)$found[0]['rowid'];
        }
        $existing->execute([$data['code_client'], $data['code_fournisseur']]);
        $matches = $existing->get_result()->fetch_all(MYSQLI_ASSOC);
        if ($matches) {
            $old = $matches[0];
            if (count($matches) !== 1 || $old['nom'] !== $row['nom']
                || ($data['code_client'] !== null && $old['code_client'] !== $data['code_client'])
                || ($data['code_fournisseur'] !== null && $old['code_fournisseur'] !== $data['code_fournisseur'])) {
                throw new RuntimeException('Code deja attribue a un autre tiers : '.$row['nom']);
            }
            $skipped++;
            continue;
        }
        $insert->execute(array_values($data));
        $added++;
    }
    if ($simulate) $db->rollback(); else $db->commit();
    $transaction = false;
    echo $simulate ? "SIMULATION OK : $added tiers a ajouter, $skipped deja presents. Aucun tiers conserve par cette simulation.\n"
                   : "IMPORT OK : $added tiers ajoutes, $skipped deja presents (non modifies).\n";
    $db->close();
} catch (Throwable $error) {
    if ($db && $transaction) $db->rollback();
    fwrite(STDERR, "ECHEC (ligne CSV $line) : ".$error->getMessage()."\nImport non valide.\n");
    exit(1);
}
PHP
)
"${compose[@]}" exec -T dolibarr php -r "$php_code" -- "$simulation" < "$csv"
