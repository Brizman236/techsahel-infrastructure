#!/usr/bin/env bash
set -euo pipefail

# Crée les deux secrets nécessaires à l'application TechSahel.
# Exécuter ce script depuis une machine locale de confiance
# disposant de l'AWS CLI et des permissions nécessaires.

REGION="${AWS_REGION:-eu-west-3}"
DB_SECRET_NAME="techsahel/production/database"
FLASK_SECRET_NAME="techsahel/production/flask"

# Vérifier la présence de l'AWS CLI.
command -v aws >/dev/null 2>&1 || {
    echo "Erreur : AWS CLI n'est pas installé." >&2
    exit 1
}

# Vérifier que les identifiants AWS sont fonctionnels.
aws sts get-caller-identity --region "$REGION" >/dev/null

# Créer un répertoire temporaire protégé hors du dépôt.
TEMP_DIR="$(mktemp -d)"
chmod 700 "$TEMP_DIR"
trap 'rm -rf "$TEMP_DIR"' EXIT

# Créer un secret uniquement s'il n'existe pas déjà.
# Un secret existant n'est jamais écrasé par ce script.
creer_secret_si_absent() {
    local nom="$1"
    local fichier="$2"

    if aws secretsmanager describe-secret \
        --secret-id "$nom" \
        --region "$REGION" >/dev/null 2>&1; then
        echo "Le secret existe déjà : $nom"
        echo "Sa valeur n'a pas été modifiée."
    else
        aws secretsmanager create-secret \
            --name "$nom" \
            --description "Secret de l'application TechSahel" \
            --secret-string "file://$fichier" \
            --region "$REGION" >/dev/null

        echo "Secret créé : $nom"
    fi
}

# Demander les informations de connexion à PostgreSQL.
read -r -p "Nom de l'utilisateur PostgreSQL de l'application : " DB_USER
read -r -s -p "Mot de passe PostgreSQL : " DB_PASSWORD
printf '\n'

read -r -p "Endpoint de la base (ou valeur provisoire) : " DB_HOST
read -r -p "Nom de la base [product_catalog] : " DB_NAME
DB_NAME="${DB_NAME:-product_catalog}"

# Construire le JSON sans afficher les valeurs sensibles.
python3 - "$TEMP_DIR/database.json" 
    "$DB_NAME" "$DB_HOST" "$DB_USER" "$DB_PASSWORD" <<'PY'
import json
import sys

chemin, nom_base, hote, utilisateur, mot_de_passe = sys.argv[1:]

secret = {
    "dbname": nom_base,
    "engine": "postgres",
    "host": hote,
    "password": mot_de_passe,
    "port": 5432,
    "username": utilisateur,
}

with open(chemin, "w", encoding="utf-8") as fichier:
    json.dump(secret, fichier)
PY

chmod 600 "$TEMP_DIR/database.json"
unset DB_PASSWORD

# Demander la clé de signature Flask.
read -r -s -p "Clé de signature Flask (valeur aléatoire robuste) : " FLASK_KEY
printf '\n'

if [[ -z "$FLASK_KEY" ]]; then
    echo "Erreur : la clé de signature Flask ne peut pas être vide." >&2
    exit 1
fi

printf '%s' "$FLASK_KEY" > "$TEMP_DIR/flask-key.txt"
chmod 600 "$TEMP_DIR/flask-key.txt"
unset FLASK_KEY

# Créer les secrets s'ils sont absents.
creer_secret_si_absent "$DB_SECRET_NAME" "$TEMP_DIR/database.json"
creer_secret_si_absent "$FLASK_SECRET_NAME" "$TEMP_DIR/flask-key.txt"

echo "Vérification de création des secrets terminée."
echo "Vérifier les valeurs et mettre à jour l'endpoint après la création de RDS."
