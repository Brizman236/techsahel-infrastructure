# Architecture de TechSahel

## 1. Objectif

Ce document présente l'architecture de l'infrastructure AWS utilisée pour héberger l'application de catalogue de produits TechSahel.

L'application est un monolithe Flask de petite taille. Elle ne nécessite ni Kubernetes, ni microservices, ni plateforme applicative distribuée.

## 2. Architecture réseau

Le VPC utilise le bloc CIDR `10.0.0.0/16`.

| Composant | CIDR | Fonction |
|---|---|---|
| VPC | `10.0.0.0/16` | Réseau principal |
| Sous-réseau public | `10.0.1.0/24` | Hébergement de l'instance EC2 |
| Sous-réseau privé A | `10.0.2.0/24` | Groupe de sous-réseaux RDS |
| Sous-réseau privé B | `10.0.4.0/24` | Groupe de sous-réseaux RDS dans une autre zone de disponibilité |

Le sous-réseau public possède une route vers Internet via une Internet Gateway. Dans la configuration décrite, les sous-réseaux privés de la base de données ne possèdent pas de route par défaut vers Internet.

La présence de deux sous-réseaux dans un groupe de sous-réseaux RDS ne signifie pas que l'instance de base de données fonctionne en mode Multi-AZ.

## 3. Circulation des requêtes

Le parcours d'une requête HTTP publique est le suivant :

1. Le navigateur se connecte à l'adresse IP publique d'EC2 sur le port TCP 80.
2. Nginx reçoit la requête.
3. Nginx transmet la requête à Gunicorn sur `127.0.0.1:8000`.
4. Gunicorn exécute l'application Flask.
5. Flask récupère les données relationnelles dans PostgreSQL lorsque cela est nécessaire.
6. Les images des produits sont chargées directement par le navigateur depuis leurs URL S3.

Le port 8000 doit rester accessible uniquement en local sur l'instance EC2.

L'endpoint public actuel utilise HTTP. Les échanges entre le navigateur et le serveur ne sont donc pas chiffrés. HTTPS nécessitera une configuration complémentaire, notamment un nom de domaine et un certificat TLS.

## 4. Architecture de la base de données

Amazon RDS for PostgreSQL stocke :

- les catégories de produits ;
- les produits ;
- les demandes de devis des clients.

Les images sont stockées séparément dans Amazon S3. La base de données conserve des références vers ces images, et non leurs fichiers binaires.

L'instance RDS est privée et n'accepte les connexions PostgreSQL que depuis le groupe de sécurité de l'application.

## 5. Configuration et secrets

La configuration de l'application est stockée dans AWS Systems Manager Parameter Store.

Les valeurs sensibles, notamment les identifiants de connexion à la base de données et la clé de signature Flask, sont stockées dans AWS Secrets Manager.

L'instance EC2 reçoit un rôle IAM par l'intermédiaire de son instance profile. L'application utilise ce rôle pour obtenir des identifiants AWS temporaires via l'Instance Metadata Service, plutôt que de conserver des clés AWS permanentes sur le serveur.

Les politiques IAM doivent accorder uniquement les actions et les accès aux ressources nécessaires au workload.

## 6. Administration de l'instance

AWS Systems Manager Session Manager permet d'administrer EC2 sans exposer SSH sur Internet.

Son fonctionnement nécessite :

- un rôle IAM adapté pour l'instance ;
- un agent SSM fonctionnel ;
- une connectivité réseau vers les endpoints Systems Manager nécessaires ;
- une identité administrateur autorisée à ouvrir des sessions.

## 7. Disponibilité et périmètre opérationnel

L'architecture utilise une seule instance EC2 pour l'application et une instance RDS en mode Single-AZ. Elle convient à un workload d'apprentissage, mais ne garantit pas la redondance de l'hôte applicatif ni le basculement automatique Multi-AZ de la base de données.

Les sauvegardes, la supervision, les procédures de restauration, HTTPS et la gestion de l'état Terraform doivent être évalués en fonction des exigences de disponibilité.

## 8. Gestion de l'infrastructure

Terraform gère les ressources AWS décrites dans le code. La configuration du système d'exploitation et l'installation de l'application sur EC2 restent des opérations distinctes.

Cette séparation permet de faire évoluer indépendamment le code de l'infrastructure et le code source de l'application.
