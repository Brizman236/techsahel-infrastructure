# Sécurité de l'infrastructure TechSahel

## 1. Objectif

Ce document décrit les principaux contrôles de sécurité et les limites connues de l'infrastructure TechSahel.

La conception s'appuie sur le principe du moindre privilège et sur la segmentation réseau, dans un contexte de petite application hébergée sur AWS.

## 2. Contrôles réseau

- Le groupe de sécurité EC2 autorise les connexions entrantes HTTP sur TCP 80.
- SSH ne doit pas être exposé publiquement.
- Les connexions entrantes PostgreSQL sont limitées au groupe de sécurité EC2.
- RDS est configuré comme une base de données privée.
- Le port 8000 doit écouter uniquement sur l'interface de bouclage locale.

L'application utilise actuellement HTTP. Le trafic entre le navigateur public et EC2 n'est donc pas chiffré. HTTPS doit être configuré avant de traiter de véritables données clients.

## 3. IAM

L'instance EC2 utilise un rôle IAM associé à un instance profile.

Ce rôle permet d'accéder aux paramètres de configuration, aux secrets nécessaires à l'application et aux fonctionnalités requises pour l'administration via Systems Manager.

Les politiques IAM doivent être limitées aux actions et aux ARN de ressources nécessaires. Éviter les permissions génériques lorsque des permissions plus précises sont possibles.

L'application ne doit pas utiliser de clés d'accès AWS permanentes stockées dans le code source ou dans un fichier d'environnement.

## 4. Gestion des secrets

Les identifiants de connexion à la base de données et la clé de signature Flask sont conservés dans AWS Secrets Manager.

La configuration d'exécution est stockée dans Systems Manager Parameter Store.

Ne jamais versionner les valeurs secrètes, les fichiers d'environnement locaux, l'état Terraform ou les plans Terraform.

Déclarer une variable Terraform comme `sensitive` masque certaines valeurs dans les sorties de l'interface en ligne de commande, mais n'empêche pas leur présence dans l'état Terraform.

## 5. Sécurité de la base de données

- Maintenir RDS privé.
- Limiter l'accès au groupe de sécurité de l'application.
- Utiliser un utilisateur PostgreSQL dédié à l'application, avec les privilèges strictement nécessaires.
- Utiliser le chiffrement du stockage.
- Définir une politique adaptée de sauvegarde et de restauration.

Une configuration Single-AZ n'offre pas les mêmes garanties de disponibilité qu'une configuration RDS Multi-AZ.

## 6. Administration EC2

Utiliser Systems Manager Session Manager pour administrer l'instance.

Appliquer les mises à jour de sécurité du système d'exploitation, utiliser des permissions de fichiers appropriées, isoler les services et restreindre l'accès aux fichiers de configuration de l'application.

## 7. Assets statiques

Les images des produits sont stockées dans S3 et référencées par URL.

Si le bucket ou un préfixe d'objets est accessible publiquement, seuls les assets destinés à être publics doivent y être placés. Ne jamais y stocker de secrets, de documents internes ou de demandes clients.

## 8. Journaux et supervision

L'application expose un endpoint de santé et produit des journaux applicatifs.

Avant un usage en production, mettre en place une supervision et des alertes couvrant les erreurs applicatives, l'état de l'instance, la santé de la base de données, les échecs d'authentification ou d'autorisation et les modifications de configuration inattendues.

## 9. Limites connues

Cette infrastructure constitue un workload de portfolio et non une référence complète de sécurité pour la production.

Les points à approfondir comprennent HTTPS, la conservation centralisée des journaux, les alertes, la gestion automatisée des correctifs, les tests de restauration, la haute disponibilité et la gestion distante et chiffrée de l'état Terraform.
