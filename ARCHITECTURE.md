# PHPQA Architecture

Ce document explique l'architecture et l'organisation du projet PHPQA centralisé.

## Structure du projet

```
phpqa/
├── .castor/
│   └── phpqa.php              # Tâches Castor centralisées
├── .github/
│   └── workflows/
│       └── reusable-ci.yml    # Workflow GitHub Actions réutilisable
├── examples/
│   ├── README.md
│   ├── .phpqa-config-library.php
│   ├── .phpqa-config-application.php
│   ├── castor-library.php
│   ├── castor-application.php
│   ├── ci-library.yml
│   └── ci-application.yml
├── scripts/
│   └── migrate-project.sh     # Script de migration automatique
├── Dockerfile                 # Image Docker personnalisée
├── README.md
├── INTEGRATION.md             # Guide d'intégration
└── ARCHITECTURE.md            # Ce fichier
```

## Composants

### 1. Image Docker (`Dockerfile`)

Image Docker basée sur `jakzal/phpqa` avec :
- Outils QA PHP (PHPStan, PHPUnit, Infection, etc.)
- Castor pré-installé
- PIE (PHP Installer for Extensions)
- Support des tests navigateur (Chromium, Firefox)

**Publié sur:** `ghcr.io/spomky-labs/phpqa:X.Y`

### 2. Tâches Castor (`.castor/phpqa.php`)

Fichier PHP contenant toutes les tâches Castor réutilisables dans le namespace `phpqa`.

#### Fonctions principales

**Configuration :**
- `get_config()` - Charge `.phpqa-config.php` ou utilise des valeurs par défaut

**Tâches QA :**
- `phpunit()` - Tests avec couverture
- `phpstan()` / `phpstan_baseline()` - Analyse statique
- `ecs()` / `ecs_fix()` - Coding standards
- `rector()` / `rector_fix()` - Refactoring
- `deptrac()` - Architecture
- `lint()` - Syntaxe
- `infect()` - Mutation testing
- `validate()` - Validation composer.json
- `check_licenses()` - Vérification des licences
- `js()` - Tests JavaScript

**Utilitaires :**
- `phpqa()` - Exécute une commande via Docker PHPQA
- `install()` - Installe les dépendances
- `prepare_pr()` - Prépare le code pour une PR
- `all()` - Lance toutes les vérifications

**Applications :**
- `console()` - Exécute des commandes Symfony (namespace `app`)

#### Principe de fonctionnement

```php
<?php
// Dans votre projet
use function Castor\import;
import(__DIR__ . '/../phpqa/.castor/phpqa.php');

// Les tâches sont maintenant disponibles
// castor qa:phpunit
// castor qa:phpstan
// etc.
```

### 3. Workflow GitHub Actions (`.github/workflows/reusable-ci.yml`)

Workflow réutilisable avec paramètres configurables.

#### Jobs principaux

1. **pre_checks** - Vérifications préliminaires
2. **prepare_dependencies** - Installation et cache des dépendances
3. **phpstan, ecs, rector, validate, lint** - Analyses en parallèle
4. **check_licenses** - Vérification licences (optionnel)
5. **deptrac** - Architecture (optionnel)
6. **js_tests** - Tests JS (optionnel)
7. **tests** - Tests unitaires/fonctionnels (matrice PHP)
8. **tests_experimental** - Tests PHP expérimental
9. **infection** - Mutation testing (optionnel)
10. **exported_files** - Vérification fichiers exportés (optionnel)

#### Paramètres

Tous configurables via `inputs:` dans le workflow appelant :

```yaml
jobs:
  ci:
    uses: spomky-labs/phpqa/.github/workflows/reusable-ci.yml@main
    with:
      project_type: 'library'
      php_versions: '["8.2", "8.3", "8.4"]'
      enable_infection: true
      # ... autres paramètres
```

### 4. Configuration projet (`.phpqa-config.php`)

Fichier PHP optionnel à la racine de chaque projet.

```php
<?php
return [
    'type' => 'library|bundle|application',
    'php_version' => '8.4',
    'source_dirs' => ['src', 'tests'],
    'check_licenses' => true,
    'infection_enabled' => true,
    'deptrac_enabled' => true,
    'js_enabled' => false,
    'docker_enabled' => true,
    'console_path' => 'bin/console',
];
```

Si absent, des valeurs par défaut sont utilisées.

### 5. Script de migration (`scripts/migrate-project.sh`)

Script bash pour migrer automatiquement un projet existant :

```bash
./scripts/migrate-project.sh /path/to/project library
```

Effectue :
1. Backup de l'ancien `castor.php`
2. Création de `.phpqa-config.php`
3. Création du nouveau `castor.php` avec import
4. Création du workflow GitHub Actions
5. Résumé des changements

## Flux de données

### Exécution locale (Castor)

```
Développeur
    ↓
castor qa:phpunit
    ↓
.castor/phpqa.php::phpunit()
    ↓
get_config() → .phpqa-config.php
    ↓
phpqa(command, options)
    ↓
Docker ghcr.io/spomky-labs/phpqa:X.Y
    ↓
Exécution dans le conteneur
```

### Exécution GitHub Actions

```
GitHub Event (push/PR)
    ↓
.github/workflows/ci.yml
    ↓
uses: spomky-labs/phpqa/.github/workflows/reusable-ci.yml
    ↓
Jobs en parallèle (prepare, phpstan, ecs, etc.)
    ↓
Container: ghcr.io/spomky-labs/phpqa:X.Y
    ↓
castor qa:* (depuis le container)
    ↓
Résultats
```

## Avantages de l'architecture

### Centralisation
- Un seul endroit pour maintenir les tâches QA
- Tous les projets bénéficient des améliorations
- Cohérence garantie

### Flexibilité
- Configuration optionnelle avec valeurs par défaut
- Support de différents types de projets
- Tâches spécifiques au projet possibles

### Performance
- Cache Composer partagé dans CI
- Jobs GitHub Actions en parallèle
- Réutilisation d'image Docker

### Maintenabilité
- Séparation claire des responsabilités
- Documentation centralisée
- Migration facilitée (script)

## Extensibilité

### Ajouter une nouvelle tâche

Dans `.castor/phpqa.php` :

```php
#[AsTask(description: 'Ma nouvelle tâche', namespace: 'qa')]
function my_task(): void
{
    $config = get_config();
    phpqa(['mon-outil', '--option']);
}
```

Immédiatement disponible dans tous les projets !

### Ajouter un job GitHub Actions

Dans `.github/workflows/reusable-ci.yml` :

```yaml
my_job:
  name: "Mon Job"
  needs: [prepare_dependencies]
  runs-on: ubuntu-latest
  container:
    image: ghcr.io/spomky-labs/phpqa:${{ inputs.default_php_version }}
  steps:
    - uses: actions/checkout@v5
    - run: castor qa:my-task
```

### Ajouter une option de configuration

1. Ajouter dans `get_config()` defaults :
```php
$defaults = [
    // ...
    'my_option' => true,
];
```

2. Utiliser dans les tâches :
```php
$config = get_config();
if ($config['my_option']) {
    // ...
}
```

3. Documenter dans `INTEGRATION.md`

## Convention de nommage

- **Tâches QA** : namespace `qa:`, ex: `qa:phpunit`
- **Tâches Application** : namespace `app:`, ex: `app:console`
- **Fonctions internes** : pas de namespace, ex: `phpqa()`, `get_config()`
- **Jobs CI** : snake_case, ex: `prepare_dependencies`
- **Inputs CI** : snake_case, ex: `enable_infection`

## Bonnes pratiques

### Pour les tâches Castor

1. Toujours utiliser `get_config()` pour la configuration
2. Gérer les cas où l'outil n'est pas disponible
3. Fournir des messages clairs (`io()->success()`, etc.)
4. Documenter avec `#[AsTask(description: '...')]`

### Pour le workflow CI

1. Utiliser des jobs parallèles quand possible
2. Réutiliser le cache des dépendances
3. Permettre la désactivation via `inputs`
4. Donner des noms explicites aux jobs

### Pour la configuration projet

1. Ne mettre que ce qui diffère des valeurs par défaut
2. Commenter les options non évidentes
3. Versionner le fichier `.phpqa-config.php`

## Dépendances

- **Castor** : >= 0.23.0
- **Docker** : pour l'exécution locale
- **GitHub Actions** : pour CI/CD
- **PHP** : >= 8.2

## Compatibilité

### Projets supportés
- Libraries PHP
- Bundles Symfony
- Applications Symfony
- Tout projet PHP avec Composer

### Limitations
- Nécessite que phpqa soit accessible (même dossier parent recommandé)
- Les workflows réutilisables GitHub Actions nécessitent un accès public ou token

## Évolution future

### Possibilités d'amélioration
1. Package Composer pour distribution
2. Support de monorepos
3. Tâches conditionnelles plus fines
4. Intégration avec d'autres CI (GitLab CI, etc.)
5. Dashboard de métriques QA
