#!/usr/bin/env bash
set -euo pipefail

# Ouvre une session Systems Manager vers l'instance EC2 de TechSahel.
# L'installation et la configuration de l'application sont effectuées
# séparément, conformément au guide de déploiement.

INSTANCE_ID="${TECHSAHEL_INSTANCE_ID:-}"
REGION="${AWS_REGION:-eu-west-3}"

# Vérifier la présence de l'AWS CLI.
if ! command -v aws >/dev/null 2>&1; then
    echo "Erreur : AWS CLI n'est pas installé." >&2
    exit 1
fi

# Vérifier que l'identifiant de l'instance a été fourni.
if [[ -z "$INSTANCE_ID" ]]; then
    echo "Utilisation :"
    echo "TECHSAHEL_INSTANCE_ID=i-xxxxxxxx AWS_REGION=eu-west-3 $0"
    exit 2
fi

# Vérifier l'identité AWS utilisée.
aws sts get-caller-identity --region "$REGION" >/dev/null

# Vérifier que l'instance existe et qu'elle est démarrée.
ETAT="$(
    aws ec2 describe-instances 
        --instance-ids "$INSTANCE_ID" 
        --region "$REGION" 
        --query 'Reservations[0].Instances[0].State.Name' 
        --output text
)"

if [[ "$ETAT" != "running" ]]; then
    echo "Erreur : l'état de l'instance est '$ETAT', et non 'running'." >&2
    exit 1
fi

echo "Ouverture d'une session Systems Manager vers $INSTANCE_ID..."
echo "Suivre ensuite le guide de déploiement du projet."

aws ssm start-session 
    --target "$INSTANCE_ID" 
    --region "$REGION"
