# PHPQA Integration Guide

Ce guide explique comment intégrer PHPQA centralisé dans vos projets PHP (Library, Bundle ou Application).

## Vue d'ensemble

PHPQA centralisé permet de :
- ✅ Utiliser les mêmes tâches Castor dans tous vos projets
- ✅ Utiliser les mêmes workflows GitHub Actions
- ✅ Avoir une configuration minimale par projet
- ✅ Maintenir la configuration QA en un seul endroit

## Configuration d'un projet

### 1. Prérequis

Assurez-vous que votre projet est à proximité du dépôt `phpqa` :

```
~/Projects/
├── phpqa/              # Ce dépôt
├── votre-library/      # Votre projet
├── votre-bundle/       # Votre projet
└── votre-app/          # Votre projet
```

### 2. Créer le fichier de configuration (optionnel)

Créez `.phpqa-config.php` à la racine de votre projet :

```php
<?php

return [
    'type' => 'library', // ou 'bundle', 'application'
    'php_version' => '8.4',
    'source_dirs' => ['src', 'tests'],
    'check_licenses' => true,
    'infection_enabled' => true,
    'deptrac_enabled' => true,
    'js_enabled' => false,
];
```

**📝 Note :** Ce fichier est optionnel. Sans configuration, des valeurs par défaut sensées seront utilisées.

#### Exemples de configurations

##### Pour une Library/Bundle :
```php
<?php
return [
    'type' => 'library',
    'check_licenses' => true,
    'infection_enabled' => true,
    'deptrac_enabled' => true,
];
```

##### Pour une Application :
```php
<?php
return [
    'type' => 'application',
    'check_licenses' => false,
    'infection_enabled' => false,
    'js_enabled' => true,
    'console_path' => 'bin/console',
];
```

### 3. Créer le fichier castor.php

Créez `castor.php` à la racine de votre projet :

#### Pour une Library/Bundle (minimal) :

```php
<?php

declare(strict_types=1);

use function Castor\import;

// Import centralized PHPQA tasks
import(__DIR__ . '/../phpqa/.castor/phpqa.php');
```

#### Pour une Application (avec tâches spécifiques) :

```php
<?php

declare(strict_types=1);

use Castor\Attribute\AsTask;
use function Castor\import;
use function Castor\run;

// Import centralized PHPQA tasks
import(__DIR__ . '/../phpqa/.castor/phpqa.php');

// Add application-specific tasks
#[AsTask(description: 'Start the application')]
function start(): void
{
    run(['docker', 'compose', 'up', '-d']);
}

#[AsTask(description: 'Stop the application')]
function stop(): void
{
    run(['docker', 'compose', 'down']);
}
```

### 4. Configurer GitHub Actions

Créez `.github/workflows/ci.yml` :

#### Pour une Library/Bundle :

```yaml
name: 📁 PHP CI

on:
  push:
    branches: ['*.x']
    tags: ['*']
  pull_request: ~
  workflow_dispatch: ~

jobs:
  ci:
    uses: spomky-labs/phpqa/.github/workflows/reusable-ci.yml@main
    with:
      project_type: 'library'
      php_versions: '["8.2", "8.3", "8.4"]'
      experimental_php_versions: '["8.5"]'
      enable_infection: true
      enable_deptrac: true
      enable_license_check: true
```

#### Pour une Application :

```yaml
name: 📁 PHP CI

on:
  push:
    branches: ['main', 'develop']
    tags: ['*']
  pull_request: ~
  workflow_dispatch: ~

jobs:
  ci:
    uses: spomky-labs/phpqa/.github/workflows/reusable-ci.yml@main
    with:
      project_type: 'application'
      php_versions: '["8.4"]'
      enable_infection: false
      enable_license_check: false
      enable_js_tests: true
```

## Utilisation

### Commandes Castor disponibles

Toutes les commandes sont dans le namespace `qa:` :

```bash
# Tests et couverture
castor qa:phpunit

# Analyse statique
castor qa:phpstan
castor qa:phpstan-baseline

# Style de code
castor qa:ecs
castor qa:ecs-fix

# Refactoring
castor qa:rector
castor qa:rector-fix

# Architecture
castor qa:deptrac

# Validation
castor qa:lint
castor qa:validate
castor qa:check-licenses

# Mutation testing
castor qa:infect

# Tests JavaScript (si activé)
castor qa:js

# Préparation PR
castor qa:prepare-pr

# Exécuter toutes les vérifications
castor qa:all

# Utilitaires
castor qa:install           # Installer les dépendances
castor qa:update-image      # Mettre à jour l'image Docker PHPQA
```

#### Commandes pour applications

Si votre projet est de type `application`, vous avez aussi :

```bash
castor app:console [commande]  # Exécuter une commande Symfony
```

### Lister toutes les commandes

```bash
castor list
```

## Options de configuration

### .phpqa-config.php

| Option | Type | Défaut | Description |
|--------|------|--------|-------------|
| `type` | string | `'library'` | Type de projet : `library`, `bundle`, `application` |
| `php_version` | string | Version courante | Version PHP pour Docker |
| `source_dirs` | array | `['src', 'tests']` | Répertoires à analyser |
| `check_licenses` | bool | `true` | Activer la vérification des licences |
| `allowed_licenses` | array | MIT, Apache-2.0... | Licences autorisées |
| `infection_enabled` | bool | `true` | Activer Infection |
| `deptrac_enabled` | bool | `true` | Activer Deptrac |
| `js_enabled` | bool | `false` | Activer les tests JS |
| `docker_enabled` | bool | `true` | Utiliser Docker |
| `console_path` | string | `'bin/console'` | Chemin vers la console Symfony |

### Workflow GitHub Actions

| Paramètre | Type | Défaut | Description |
|-----------|------|--------|-------------|
| `project_type` | string | `'library'` | Type de projet |
| `php_versions` | JSON array | `["8.2", "8.3", "8.4"]` | Versions PHP à tester |
| `experimental_php_versions` | JSON array | `["8.5"]` | Versions PHP expérimentales |
| `default_php_version` | string | `'8.4'` | Version PHP pour l'analyse |
| `enable_lowest_deps` | bool | `true` | Test avec dépendances minimales |
| `enable_infection` | bool | `true` | Activer Infection |
| `enable_deptrac` | bool | `true` | Activer Deptrac |
| `enable_license_check` | bool | `true` | Vérification des licences |
| `enable_js_tests` | bool | `false` | Tests JavaScript |
| `enable_exported_files_check` | bool | `true` | Vérification des fichiers exportés |
| `exported_files` | string | Liste de fichiers | Fichiers attendus dans l'export |

## Migration d'un projet existant

### Étape 1 : Sauvegarder votre castor.php actuel

```bash
mv castor.php castor.php.old
```

### Étape 2 : Identifier les tâches personnalisées

Examinez `castor.php.old` et identifiez les tâches spécifiques à votre projet (celles qui ne sont pas liées à PHPQA).

### Étape 3 : Créer le nouveau castor.php

Créez un nouveau `castor.php` qui importe PHPQA et ajoute vos tâches spécifiques :

```php
<?php

declare(strict_types=1);

use function Castor\import;

// Import centralized PHPQA tasks
import(__DIR__ . '/../phpqa/.castor/phpqa.php');

// Add your project-specific tasks here
// (copied from castor.php.old)
```

### Étape 4 : Tester

```bash
# Lister les commandes disponibles
castor list

# Tester une commande
castor qa:phpstan
```

### Étape 5 : Migrer le workflow GitHub Actions

Remplacez votre `.github/workflows/ci.yml` par le workflow réutilisable :

```yaml
jobs:
  ci:
    uses: spomky-labs/phpqa/.github/workflows/reusable-ci.yml@main
    with:
      # Vos paramètres
```

## Exemples complets

Des exemples complets sont disponibles dans le dossier `examples/` :

- `examples/.phpqa-config-library.php` - Configuration pour une library
- `examples/.phpqa-config-application.php` - Configuration pour une application
- `examples/castor-library.php` - castor.php minimal pour library
- `examples/castor-application.php` - castor.php pour application
- `examples/ci-library.yml` - Workflow GitHub Actions pour library
- `examples/ci-application.yml` - Workflow GitHub Actions pour application

## Avantages

### ✅ Centralisation
- Une seule source de vérité pour toutes les tâches QA
- Mise à jour facilitée : un seul endroit à modifier
- Cohérence entre tous vos projets

### ✅ Simplicité
- Configuration minimale par projet
- Pas de duplication de code
- Maintenance réduite

### ✅ Flexibilité
- Configuration optionnelle avec valeurs par défaut sensées
- Possibilité d'ajouter des tâches spécifiques au projet
- Support de différents types de projets (library, bundle, application)

### ✅ Évolutivité
- Facile d'ajouter de nouveaux outils
- Les projets existants bénéficient automatiquement des améliorations
- Workflows GitHub Actions réutilisables

## Dépannage

### "castor: command not found"

Installez Castor :

```bash
# Via Composer
composer global require castor/castor

# Ou téléchargez le binaire
# https://github.com/jolicode/castor/releases
```

### "Cannot find phpqa.php"

Vérifiez que le chemin dans `import()` est correct :

```php
// Le chemin doit pointer vers le dossier phpqa
import(__DIR__ . '/../phpqa/.castor/phpqa.php');
```

### "Docker image not found"

Mettez à jour l'image Docker :

```bash
castor qa:update-image
```

### Le workflow GitHub Actions ne trouve pas le fichier réutilisable

Assurez-vous que :
1. Le workflow est bien publié sur GitHub
2. L'organisation/utilisateur est correct : `spomky-labs/phpqa`
3. La branche est correcte : `@main`

## Support

Pour toute question ou problème :
1. Consultez ce guide
2. Vérifiez les exemples dans `examples/`
3. Ouvrez une issue sur le dépôt phpqa
