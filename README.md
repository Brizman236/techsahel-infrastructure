# Infrastructure TechSahel

Code Terraform et documentation pour déployer sur AWS l'infrastructure de l'application de catalogue de produits TechSahel.

## Présentation du projet

TechSahel est une entreprise technologique sénégalaise fictive. Son application web permet aux visiteurs de consulter un catalogue de produits, de rechercher des articles, d'afficher leurs détails et d'envoyer des demandes de devis.

Ce dépôt contient le code de l'infrastructure AWS et la documentation opérationnelle. Le code source de l'application est conservé dans un dépôt séparé.

## Architecture

L'infrastructure est déployée dans la région AWS `eu-west-3` (Paris).

```text
Internet
   |
   v
Internet Gateway
   |
   v
Sous-réseau public
   |
   v
EC2 : Nginx + Gunicorn + Flask
   |                         |
   |                         +----> Amazon S3
   |                                Images des produits
   |
   +----> Sous-réseaux privés RDS
   |       |
   |       +----> Amazon RDS for PostgreSQL
   |
   +----> AWS Systems Manager
   |       Configuration de l'application
   |
   +----> AWS Secrets Manager
           Secrets de l'application
```

### Principaux services AWS

- **Amazon VPC :** isolation et organisation du réseau.
- **Amazon EC2 :** hébergement de l'application.
- **Amazon RDS for PostgreSQL :** stockage des données relationnelles.
- **Amazon S3 :** stockage des images des produits.
- **AWS Systems Manager Parameter Store :** stockage de la configuration de l'application.
- **AWS Secrets Manager :** stockage des informations sensibles.
- **AWS IAM :** gestion des permissions attribuées à l'instance EC2.
- **AWS Systems Manager Session Manager :** administration de l'instance sans exposer SSH sur Internet.

## Structure du dépôt

```text
techsahel-infrastructure/
├── README.md
├── .gitignore
├── docs/
│   ├── architecture.md
│   ├── deployment-guide.md
│   └── security.md
├── scripts/
│   ├── create-secrets.sh
│   └── deploy-app.sh
└── terraform/
    ├── main.tf
    ├── providers.tf
    ├── versions.tf
    ├── variables.tf
    ├── outputs.tf
    ├── network.tf
    ├── security.tf
    ├── iam.tf
    ├── ec2.tf
    ├── rds.tf
    ├── secrets.tf
    └── terraform.tfvars.example
```

## Prérequis

Les outils suivants sont nécessaires :

- Git
- AWS CLI
- Terraform
- Un compte AWS disposant des permissions nécessaires à la création des ressources

Vérifier l'identité AWS utilisée avant toute opération :

```bash
aws sts get-caller-identity
aws configure get region
terraform version
```

La région attendue pour ce projet est `eu-west-3`.

Ne jamais enregistrer de clés d'accès AWS ou de valeurs secrètes dans ce dépôt.

## Ordre de déploiement

Le processus prévu est le suivant :

1. Examiner le code Terraform.
2. Créer les secrets de l'application dans AWS Secrets Manager.
3. Renseigner localement les variables Terraform nécessaires.
4. Initialiser Terraform et examiner le plan d'exécution.
5. Créer les ressources AWS avec Terraform.
6. Configurer le système d'exploitation et installer l'application sur EC2.
7. Vérifier l'application, la connexion à la base de données et le point de contrôle de santé.

Consulter [docs/deployment-guide.md](docs/deployment-guide.md) pour la procédure détaillée.

## Commandes Terraform

Depuis le répertoire `terraform/` :

```bash
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan
```

Après avoir vérifié le plan :

```bash
terraform apply
```

Pour consulter les sorties :

```bash
terraform output
```

Les fichiers d'état et les plans Terraform ne doivent pas être publiés. Ils peuvent contenir des informations sensibles.

## Déploiement de l'application

L'application Flask est conservée dans un dépôt séparé. Sur EC2, Nginx reçoit les requêtes HTTP et les transmet à Gunicorn, qui exécute l'application Flask.

La configuration de l'application est fournie par AWS Systems Manager Parameter Store. Les informations sensibles sont récupérées dans AWS Secrets Manager à l'aide du rôle IAM de l'instance.

Le script de déploiement fourni dans ce dépôt facilite l'ouverture d'une session administrative sur EC2. Il ne remplace pas les étapes d'installation et de configuration de l'application.

## Sécurité

- RDS ne doit pas être accessible publiquement.
- L'accès PostgreSQL doit être limité au groupe de sécurité de l'application.
- SSH ne doit pas être exposé sur Internet.
- Session Manager doit être utilisé pour l'administration de l'instance.
- Les fichiers `terraform.tfvars`, les fichiers d'état et les secrets locaux ne doivent pas être versionnés.
- Les politiques IAM et les règles des groupes de sécurité doivent être examinées avant chaque application des changements.
- L'accès public aux images S3 est un choix intentionnel : seuls les objets destinés à être publics doivent être placés dans le préfixe concerné.

## Limites actuelles

Ce projet est conçu comme un workload de portfolio et d'apprentissage. Il ne faut pas supposer que tous les contrôles nécessaires à un environnement de production sont déjà activés.

Il convient notamment d'évaluer HTTPS, le nom de domaine, la durée de conservation des sauvegardes, la protection contre la suppression, la supervision et la gestion de l'état Terraform distant.
