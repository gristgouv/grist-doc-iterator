# Tests de déploiement pour Grist

## Motivation

Ce projet vise à fournir quelques tests simples pour s'assurer que l'instance cible est correctement configurée. Il est basé sur des problèmes rencontrés par l'[ANCT](https://anct.gouv.fr) dans le passé.

## Installation

Après avoir cloné le dépôt, installez les dépendances en utilisant npm :
```bash
$ npm install
```

## Exécuter les tests

Vous pouvez exécuter le test en utilisant cette commande :
```bash
$ GRIST_DOMAIN='https://my-grist.tld' USER_API_KEY='some-user-api-key' ORG_ID='1234' npm run test:api
```

Les variables d'environnement ci-dessus sont :
 - `GRIST_DOMAIN` est le domaine de votre instance Grist (obligatoire) ;
 - `USER_API_KEY` est la clé API de l'utilisateur avec lequel vous souhaitez exécuter les tests (obligatoire) ;
 - `ORG_ID` est l'ID de l'organisation sur laquelle vous souhaitez exécuter les tests (optionnel, par défaut l'ID de l'espace personnel) ;

Les tests créent un espace de travail dédié (nommé `test__<date au format ISO>`), qui est automatiquement supprimé après l'exécution des tests.

### Exécuter un test isolément

Vous pouvez exécuter un test isolément en utilisant l'option `-g` de mocha. Par exemple, la commande suivante exécute uniquement les tests dont le titre contient `"snapshots"` :
```bash
$ GRIST_DOMAIN='https://my-grist.tld' USER_API_KEY='some-user-api-key' [...] npm run test:api -- -g 'snapshots' 
```

### Dépannage

Si vous rencontrez des problèmes avec vos tests, vous pouvez définir la variable d'environnement `NO_CLEANUP` à `1` afin que l'espace de travail créé pendant les tests ne soit pas supprimé et que vous puissiez inspecter les documents créés.
