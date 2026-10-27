# Guide de déploiement de TechSahel

## 1. Objectif

Ce guide décrit les étapes nécessaires pour déployer l'infrastructure AWS de TechSahel à partir du code Terraform fourni dans ce dépôt.

Le déploiement repose sur deux dépôts distincts :

- **Dépôt infrastructure :** contient le code Terraform et les instructions de déploiement.
- **Dépôt application :** contient le code source de l'application Flask.

Terraform gère la création des ressources AWS. La configuration du système d'exploitation et l'installation de l'application sur EC2 restent des opérations manuelles.

## 2. Prérequis

Installer les outils suivants sur la machine utilisée pour le déploiement :

- Git
- AWS CLI
- Terraform

Vérifier l'identité AWS utilisée :

```bash
aws sts get-caller-identity
```

Vérifier la version de Terraform :

```bash
terraform version
```

La région utilisée par le projet est `eu-west-3` (Paris).

Avant de continuer, s'assurer que l'identité AWS dispose des permissions nécessaires pour créer les ressources prévues.

## 3. Créer les secrets dans AWS Secrets Manager

Avant d'exécuter Terraform, créer les deux secrets suivants dans AWS Secrets Manager, dans la région `eu-west-3` :

| Nom du secret | Contenu attendu |
|---|---|
| `techsahel/production/database` | Identifiants de connexion PostgreSQL utilisés par l'application |
| `techsahel/production/flask` | Clé de signature de l'application Flask |

### 3.1. Secret de la base de données

Créer un secret contenant les informations de connexion attendues par le chargeur de configuration de l'application.

Exemple de structure JSON :

```json
{
  "dbname": "product_catalog",
  "engine": "postgres",
  "host": "ENDPOINT_RDS",
  "password": "MOT_DE_PASSE_POSTGRESQL",
  "port": 5432,
  "username": "UTILISATEUR_APPLICATION"
}
```

Remplacer les valeurs d'exemple par les informations réelles.

L'endpoint RDS sera connu après la création de la base de données. Si nécessaire, créer initialement le secret avec une valeur provisoire, puis le mettre à jour avec l'endpoint réel avant de démarrer l'application.

L'utilisateur PostgreSQL de l'application doit également exister dans la base et disposer des privilèges nécessaires. La création du secret ne crée pas automatiquement cet utilisateur.

### 3.2. Secret de signature Flask

Créer un secret nommé :

```text
techsahel/production/flask
```

Sa valeur doit être une clé de signature robuste, générée aléatoirement.

Ne pas utiliser une valeur d'exemple ni une clé prévisible.

### 3.3. Récupérer les ARN des secrets

Après la création des deux secrets, récupérer leur ARN complet dans AWS Secrets Manager.

Un ARN de secret comprend notamment la région, l'identifiant du compte, le nom du secret et un suffixe généré par AWS.

Ne pas conserver les caractères `??????` dans la configuration finale.

## 4. Créer les paramètres dans AWS Systems Manager Parameter Store

Créer les paramètres nécessaires à l'application dans la région `eu-west-3`, sous le chemin :

```text
/techsahel/production/
```

Les paramètres attendus sont les suivants :

| Nom du paramètre | Fonction |
|---|---|
| `APP_ENV` | Environnement d'exécution de l'application |
| `APP_NAME` | Nom de l'application |
| `ASSET_BASE_URL` | URL de base des images et assets |
| `LOG_LEVEL` | Niveau de journalisation |
| `STORAGE_BACKEND` | Mode de stockage des assets |
| `ITEMS_PER_PAGE` | Nombre de produits affichés par page |
| `DB_HOST` | Endpoint de la base PostgreSQL |
| `DB_NAME` | Nom de la base de données |
| `DB_PORT` | Port PostgreSQL |
| `DB_USER` | Nom de l'utilisateur PostgreSQL |

Les noms et les types de paramètres doivent correspondre à ceux attendus par le code de configuration de l'application.

Utiliser des paramètres de type `String` pour les valeurs non sensibles. Ne pas stocker de mots de passe dans ces paramètres : les valeurs sensibles doivent rester dans Secrets Manager.

Vérifier que le chemin et les paramètres créés correspondent aux permissions IAM prévues dans le code Terraform.

## 5. Modifier `terraform/variables.tf`

Cette étape est nécessaire pour adapter le code fourni à l'environnement AWS utilisé par la personne qui effectue le déploiement.

Ouvrir :

```text
terraform/variables.tf
```

Rechercher les trois variables suivantes :

```hcl
variable "catalog_app_user_secret_arn" {
  description = "TechSahel Application runtime database user ARN secret"
  type        = string
  default     = "arn:aws:secretsmanager:eu-west-3:936719391688:secret:techsahel/production/database-??????"
}

variable "flask_signing_key_arn" {
  description = "TechSahel Flask App signing key secret ARN"
  type        = string
  default     = "arn:aws:secretsmanager:eu-west-3:936719391688:secret:techsahel/production/flask-??????"
}

variable "app_config_params" {
  description = "TechSahel Application Parameters Path"
  type        = string
  default     = "arn:aws:ssm:eu-west-3:936719391688:parameter/techsahel/production/*"
}
```

Remplacer uniquement les valeurs de `default` par les identifiants correspondant aux ressources créées dans son propre compte AWS.

- `catalog_app_user_secret_arn` : ARN complet du secret contenant les identifiants PostgreSQL.
- `flask_signing_key_arn` : ARN complet du secret contenant la clé de signature Flask.
- `app_config_params` : ARN du chemin des paramètres SSM, avec le caractère générique `*` si la politique IAM doit couvrir les paramètres situés sous ce chemin.

Conserver les noms des variables et les autres déclarations Terraform inchangés.

**Aucun nouveau fichier de variables n'est nécessaire.** Les valeurs sont renseignées directement dans `variables.tf`, conformément à la procédure de ce projet.

Les ARN ne sont pas les valeurs des secrets eux-mêmes. Ne jamais inscrire de mot de passe ou de clé de signature Flask dans ce fichier.

## 6. Initialiser et vérifier Terraform

Depuis la racine du dépôt :

```bash
cd terraform
```

Initialiser Terraform :

```bash
terraform init
```

Formater les fichiers :

```bash
terraform fmt -recursive
```

Valider la configuration :

```bash
terraform validate
```

Si la validation échoue, corriger les erreurs avant de poursuivre.

## 7. Examiner et appliquer le plan Terraform

Générer le plan :

```bash
terraform plan
```

Examiner attentivement les opérations prévues :

- création des ressources ;
- modifications éventuelles des ressources existantes ;
- suppressions ou remplacements éventuels.

Ne pas appliquer un plan contenant des suppressions ou remplacements inattendus.

Si le plan correspond au résultat attendu, créer l'infrastructure :

```bash
terraform apply
```

Terraform demandera une confirmation avant d'appliquer les changements.

Après le déploiement, consulter les sorties :

```bash
terraform output
```

Récupérer notamment l'endpoint RDS et les informations nécessaires à la configuration de l'instance EC2.

## 8. Mettre à jour la configuration de la base de données

Après la création de RDS, vérifier que le secret `techsahel/production/database` contient :

- le véritable endpoint RDS ;
- le nom de la base de données ;
- le port ;
- le nom de l'utilisateur applicatif ;
- le mot de passe correspondant.

Si des valeurs provisoires ont été utilisées, mettre à jour le secret dans Secrets Manager.

Vérifier également que l'utilisateur applicatif existe dans PostgreSQL et dispose des permissions nécessaires.

Ne pas démarrer l'application tant que les informations de connexion ne sont pas correctes.

## 9. Configurer l'instance EC2

Se connecter à l'instance à l'aide d'AWS Systems Manager Session Manager.

Effectuer manuellement les opérations suivantes :

1. Installer les dépendances système nécessaires.
2. Récupérer le code source depuis le dépôt de l'application.
3. Créer l'utilisateur système dédié à l'application.
4. Configurer le mécanisme de chargement des paramètres SSM et des secrets.
5. Définir les permissions des fichiers.
6. Configurer Gunicorn.
7. Créer et activer le service systemd.
8. Configurer Nginx comme reverse proxy vers Gunicorn.
9. Démarrer les services et vérifier leur état.

Les détails de cette configuration doivent être documentés dans les procédures propres à l'application.

Le script `scripts/deploy-app.sh` permet d'ouvrir une session Session Manager, mais ne réalise pas automatiquement toutes ces opérations.

## 10. Vérifier le déploiement

Vérifier l'état du service applicatif :

```bash
sudo systemctl status techsahel
```

Vérifier Nginx :

```bash
sudo systemctl status nginx
```

Consulter les journaux :

```bash
sudo journalctl -u techsahel --since "15 minutes ago"
sudo journalctl -u nginx --since "15 minutes ago"
```

Depuis un navigateur, tester les fonctionnalités principales :

- page d'accueil ;
- catalogue de produits ;
- recherche ;
- fiches détaillées ;
- soumission d'une demande de devis ;
- affichage des images ;
- endpoint `/health`.

Vérifier que l'endpoint de santé renvoie le statut attendu de l'application et de la base de données.

## 11. Nettoyage de l'infrastructure

La destruction des ressources peut entraîner la perte définitive de données.

Avant toute destruction :

1. Vérifier les ressources concernées.
2. Sauvegarder les données à conserver.
3. Examiner les conséquences sur la base de données et les sauvegardes.
4. Générer un plan de destruction.
5. Confirmer que la suppression est intentionnelle.

```bash
terraform plan -destroy
```

Ne pas lancer `terraform destroy` sans avoir examiné les conséquences.

## 12. Points de sécurité à retenir

- Ne jamais publier les mots de passe, les clés de signature ou les fichiers d'état Terraform.
- Ne pas versionner les configurations locales contenant des valeurs sensibles.
- Vérifier que RDS reste privé.
- Limiter l'accès PostgreSQL au groupe de sécurité de l'application.
- Utiliser Session Manager pour administrer EC2.
- Vérifier les permissions IAM avant chaque déploiement.
- Garder à l'esprit que l'endpoint HTTP public actuel ne chiffre pas les échanges entre le navigateur et le serveur.
