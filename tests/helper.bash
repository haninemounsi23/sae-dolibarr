# Outils communs aux tests.

DEPOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"

# Prepare un dossier de test avec une copie des scripts et un FAUX docker.
# Le faux docker note ce qu'on lui demande dans un fichier, sans rien lancer.
preparer() {
    DOSSIER="$BATS_TEST_TMPDIR/projet"
    mkdir -p "$DOSSIER" "$BATS_TEST_TMPDIR/bin"
    cp "$DEPOT/install.sh" "$DEPOT/import_csv.sh" "$DEPOT/compose.auto.yaml" "$DOSSIER/"

    export LOG="$BATS_TEST_TMPDIR/docker.log"
    export ENTREE="$BATS_TEST_TMPDIR/docker.entree"
    : > "$LOG"

    cat > "$BATS_TEST_TMPDIR/bin/docker" <<'FAUX'
#!/usr/bin/env bash
echo "$*" >> "$LOG"
[[ "$*" == *" exec "* ]] && cat > "$ENTREE"
# Si PANNE="mot", le faux docker echoue quand la commande contient ce mot.
[[ -n ${PANNE:-} && "$*" == *"$PANNE"* ]] && exit 1
exit 0
FAUX
    chmod +x "$BATS_TEST_TMPDIR/bin/docker"
    export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
    cd "$DOSSIER"
}

# Ecrit un fichier CSV : la 1re ligne est l'en-tete, les autres sont les tiers.
creer_csv() {
    CSV="$BATS_TEST_TMPDIR/test.csv"
    printf '%s\n' "$@" > "$CSV"
}

ENTETE='Nom (s.nom),Etat (s.status),Code client (s.code_client),Code fournisseur (s.code_fournisseur),Client (s.client),Fournisseur (s.fournisseur)'

# Lance la verification PHP du CSV (sans base de donnees).
# Si le CSV est bon, le script essaie ensuite de se connecter a la base,
# qui n'existe pas ici : l'erreur "Connection refused" prouve donc que le CSV est valide.
verifier_csv() {
    local code
    code=$(awk "/<<'PHP'/{f=1; next} /^PHP\$/{f=0} f" "$DEPOT/import_csv.sh")
    DOLI_DB_HOST=127.0.0.1:1 DOLI_DB_PASSWORD=x run php -r "$code" -- 1 < "$CSV"
}

csv_accepte() {
    [[ "$output" == *"Connection refused"* ]]
}

csv_refuse() {  # $1 = message d'erreur attendu
    [ "$status" -eq 1 ]
    [[ "$output" == *"$1"* ]]
}
