#!/usr/bin/env bats
# Tests de install.sh et de la partie "shell" de import_csv.sh.
load helper
setup() { preparer; creer_csv "$ENTETE" "Societe A,1,C1,,1,0"; }

# ---- install.sh ----

@test "install : refuse de demarrer sans fichier .env" {
    run ./install.sh
    [ "$status" -eq 1 ]
    [ ! -s "$LOG" ]
}

@test "install : s'arrete si Docker est en panne" {
    touch .env
    PANNE="info" run ./install.sh
    [ "$status" -ne 0 ]
    ! grep -q " up " "$LOG"
}

@test "install : verifie la config puis demarre les conteneurs" {
    touch .env
    run ./install.sh
    [ "$status" -eq 0 ]
    grep -q "config --quiet" "$LOG"
    grep -q "up -d --build" "$LOG"
}

# ---- import_csv.sh ----

@test "import : sans argument, affiche l'usage" {
    run ./import_csv.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"Usage"* ]]
}

@test "import : fichier CSV introuvable" {
    run ./import_csv.sh /nexiste/pas.csv
    [ "$status" -eq 1 ]
}

@test "import : envoie le CSV au PHP dans le conteneur" {
    run ./import_csv.sh "$CSV"
    [ "$status" -eq 0 ]
    grep -q "exec -T dolibarr php" "$LOG"
    cmp "$CSV" "$ENTREE"
}

@test "import : --simulate est accepte" {
    run ./import_csv.sh --simulate "$CSV"
    [ "$status" -eq 0 ]
}

@test "import : propage l'echec du PHP" {
    PANNE="exec" run ./import_csv.sh "$CSV"
    [ "$status" -ne 0 ]
}
