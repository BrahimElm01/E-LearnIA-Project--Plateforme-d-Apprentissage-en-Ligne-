# Configuration de la génération de cours avec IA

## Vue d'ensemble

Le système de génération de cours utilise maintenant l'API Hugging Face (gratuite) pour générer du contenu riche et personnalisé. En cas d'échec de l'IA, le système utilise automatiquement la logique de fallback basée sur des templates.

## Configuration

### 1. Configuration dans `application.properties`

```properties
# Course Generator AI Configuration
course.generator.ai.enabled=true                    # Activer/désactiver l'IA
course.generator.ai.provider=huggingface            # Fournisseur IA (actuellement: huggingface)
course.generator.ai.huggingface.model=mistralai/Mistral-7B-Instruct-v0.2  # Modèle à utiliser
course.generator.ai.huggingface.api.key=            # Clé API (optionnelle pour modèles publics)
course.generator.ai.timeout=30                     # Timeout en secondes
```

### 2. Modèles Hugging Face disponibles (gratuits)

#### Modèles recommandés pour le français :

1. **mistralai/Mistral-7B-Instruct-v0.2** (par défaut)
   - Modèle instruct, bon pour la génération de texte structuré
   - Supporte le français
   - Gratuit (sans clé API requise)

2. **microsoft/DialoGPT-medium**
   - Bon pour les conversations
   - Supporte plusieurs langues

3. **bigscience/bloom-560m**
   - Léger et rapide
   - Supporte le français

4. **meta-llama/Llama-2-7b-chat-hf**
   - Nécessite une clé API Hugging Face
   - Très performant

### 3. Obtenir une clé API Hugging Face (optionnel)

1. Créer un compte sur [Hugging Face](https://huggingface.co/)
2. Aller dans Settings → Access Tokens
3. Créer un nouveau token
4. Ajouter le token dans `application.properties` :
   ```properties
   course.generator.ai.huggingface.api.key=votre_token_ici
   ```

**Note** : La plupart des modèles publics fonctionnent sans clé API. Une clé est nécessaire uniquement pour les modèles privés ou avec des limites de taux plus élevées.

## Fonctionnement

### Flux de génération

1. **Tentative avec IA** (si activée)
   - Génère le titre avec IA
   - Génère la description avec IA
   - Génère le résumé avec IA
   - Génère les objectifs avec IA
   - Génère les leçons avec IA
   - Génère le quiz (utilise la logique actuelle)

2. **Fallback automatique**
   - Si l'IA échoue ou est désactivée
   - Utilise la logique de templates existante
   - Garantit toujours une génération de cours

### Prompts utilisés

Le système utilise des prompts structurés pour chaque élément :

- **Titre** : Prompt court pour un titre accrocheur
- **Description** : Prompt détaillé pour une description complète (200-400 mots)
- **Résumé** : Prompt pour un résumé concis (100-150 mots)
- **Objectifs** : Prompt pour générer 4-6 objectifs mesurables
- **Leçons** : Prompt structuré pour générer le plan de cours

## Avantages de l'intégration IA

1. **Contenu plus riche** : Descriptions détaillées et personnalisées
2. **Adaptation au sujet** : Le contenu s'adapte mieux au sujet spécifique
3. **Objectifs pertinents** : Objectifs d'apprentissage plus précis
4. **Plan de cours structuré** : Leçons mieux organisées et progressives
5. **Fallback robuste** : Garantit toujours une génération même si l'IA échoue

## Dépannage

### L'IA ne génère pas de contenu

1. Vérifier que `course.generator.ai.enabled=true`
2. Vérifier la connexion internet
3. Vérifier que le modèle Hugging Face est accessible
4. Consulter les logs pour les erreurs détaillées

### Contenu généré de mauvaise qualité

1. Essayer un autre modèle dans `application.properties`
2. Ajouter une clé API Hugging Face pour accéder à de meilleurs modèles
3. Le système utilisera automatiquement le fallback si la qualité est insuffisante

### Timeout

Si vous rencontrez des timeouts :
1. Augmenter `course.generator.ai.timeout` dans `application.properties`
2. Utiliser un modèle plus léger (ex: `bigscience/bloom-560m`)

## Exemple de configuration optimale

```properties
# Activer l'IA
course.generator.ai.enabled=true

# Utiliser un modèle performant (nécessite clé API)
course.generator.ai.huggingface.model=meta-llama/Llama-2-7b-chat-hf
course.generator.ai.huggingface.api.key=votre_token_huggingface

# Timeout plus long pour les modèles lourds
course.generator.ai.timeout=60
```

## Notes importantes

- L'API Hugging Face est **gratuite** pour les modèles publics
- Les modèles peuvent avoir des limites de taux (rate limits)
- Le système inclut un mécanisme de retry automatique
- Le fallback garantit toujours une génération de cours fonctionnelle
- Les vidéos YouTube sont toujours générées avec la logique actuelle (base de données de vidéos)






