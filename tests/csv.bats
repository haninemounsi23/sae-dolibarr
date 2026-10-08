#!/usr/bin/env bats
# Tests des regles de verification du CSV (le code PHP de import_csv.sh).
load helper

# ---- CSV refuses ----

@test "CSV vide" {
    CSV="$BATS_TEST_TMPDIR/vide.csv"; : > "$CSV"
    verifier_csv; csv_refuse "CSV vide"
}

@test "en-tete sans '(s.champ)'" {
    creer_csv "Nom,Etat" "A,1"
    verifier_csv; csv_refuse "En-tete non reconnu"
}

@test "colonne obligatoire manquante" {
    creer_csv "Nom (s.nom),Etat (s.status)" "A,1"
    verifier_csv; csv_refuse "Colonne absente"
}

@test "aucune ligne de donnees" {
    creer_csv "$ENTETE"
    verifier_csv; csv_refuse "Aucune ligne"
}

@test "mauvais nombre de colonnes" {
    creer_csv "$ENTETE" "A,1,C1"
    verifier_csv; csv_refuse "Nombre de colonnes"
}

@test "nom vide (et numero de la ligne en erreur)" {
    creer_csv "$ENTETE" "A,1,C1,,1,0" ",1,C2,,1,0"
    verifier_csv; csv_refuse "ligne CSV 3"
}

@test "statut invalide" {
    creer_csv "$ENTETE" "A,5,C1,,1,0"
    verifier_csv; csv_refuse "Valeur incorrecte pour status"
}

@test "ni client ni fournisseur" {
    creer_csv "$ENTETE" "A,1,,,0,0"
    verifier_csv; csv_refuse "Ni client ni fournisseur"
}

@test "client sans code client" {
    creer_csv "$ENTETE" "A,1,,,1,0"
    verifier_csv; csv_refuse "Code manquant"
}

@test "meme code client deux fois" {
    creer_csv "$ENTETE" "A,1,C1,,1,0" "B,1,c1,,1,0"
    verifier_csv; csv_refuse "Code repete"
}

@test "champ non gere rempli (siren)" {
    creer_csv "$ENTETE,SIREN (s.siren)" "A,1,C1,,1,0,123"
    verifier_csv; csv_refuse "non pris en charge"
}

@test "fichier pas en UTF-8" {
    { echo "$ENTETE"; printf 'Soci\xe9te,1,C1,,1,0\n'; } > "$BATS_TEST_TMPDIR/latin.csv"
    CSV="$BATS_TEST_TMPDIR/latin.csv"
    verifier_csv; csv_refuse "UTF-8"
}

# ---- CSV acceptes ----

@test "ligne valide" {
    creer_csv "$ENTETE" "A,1,C1,,1,0"
    verifier_csv; csv_accepte
}

@test "accents et apostrophes acceptes (pas de risque d'injection SQL)" {
    creer_csv "$ENTETE" "L'Électricité d'Été'); DROP TABLE x;--,1,C1,,1,0"
    verifier_csv; csv_accepte
}

@test "le vrai fichier data/tiers_sae.csv est valide" {
    CSV="$DEPOT/data/tiers_sae.csv"
    verifier_csv; csv_accepte
}
