## Hi there 👋

<!--
**SoulBoundPrompter/SoulBoundPrompter** is a ✨ _special_ ✨ repository because its `README.md` (this file) appears on your GitHub profile.

Here are some ideas to get you started:

- 🔭 I’m currently working on ...
- 🌱 I’m currently learning ...
- 👯 I’m looking to collaborate on ...
- 🤔 I’m looking for help with ...
- 💬 Ask me about ...
- 📫 How to reach me: ...
- 😄 Pronouns: ...
- ⚡ Fun fact: ...
-->
# SoulBound Prompter - Protection des Données Sensibles pour LLM

## DESCRIPTION

SoulBound Prompter est un outil local qui anonymise automatiquement vos données sensibles avant envoi vers des LLM (ChatGPT, Claude, etc.), puis restaure vos vraies données dans les réponses.

**Objectif :** Protéger votre vie privée tout en bénéficiant de l'IA sans exposer d'informations confidentielles.

### FICHIER À UTILISER
- `SoulBoundPrompter.ps1` - Application complète et autonome

## FONCTIONNALITÉS PRINCIPALES

### Anonymisation Intelligente
- 14+ patterns par défaut : Emails, téléphones, noms, IBAN, SIRET, etc.
- Détection automatique des données sensibles françaises
- Patterns personnalisés via expressions régulières
- Aide intégrée avec lien vers Regex101.com

### Processus Sécurisé en 4 Étapes
1. **Texte original** - Collez votre document avec données sensibles
2. **Anonymisation** - Remplacement automatique par des codes
3. **Envoi LLM** - Texte sécurisé pour ChatGPT/Claude/etc.
4. **Restauration** - Vos vraies données remises en place

### Interface
- Panneaux redimensionnables
- Police Segoe UI parce que pourquoi pas
- Messages d'aide détaillés

## UTILISATION RAPIDE

### Démarrage
```powershell
# Lancez simplement le fichier
.\SoulBoundPrompter.ps1
```

### Workflow en 4 étapes

#### ÉTAPE 1 - Texte Original
- Collez votre document contenant des données sensibles
- Cliquez "1. ANONYMISER LE TEXTE"

#### ÉTAPE 2 - Texte Anonymisé
- Vérifiez le texte sécurisé (données remplacées par des nom de variable)
- Cliquez "2. COPIER TEXTE SÉCURISÉ"
- Envoyer votre texte sécurisé vers votre LLM préféré

#### ÉTAPE 3 - Réponse du LLM
- Collez la réponse reçue de votre LLM (ChatGPT, Claude...)
- Cliquez "3. RESTAURER DONNÉES RÉELLES"

#### ÉTAPE 4 - Résultat Final
- Récupérez votre texte avec les vraies données restaurées
- Cliquez "4. COPIER RÉSULTAT FINAL"

### Interface à Deux Panneaux

#### Panneau Gauche - Workflow Principal
- Zones de texte multilignes avec scrollbars
- Boutons numérotés suivant le processus logique
- Bouton "TOUT EFFACER" pour recommencer (messages d'alerte avant supression des différents champs)

#### Panneau Droit - Configuration
- Liste des patterns intégrés (scrollable et consultable)
- Création de patterns personnalisés avec nom + regex
- Bouton "AIDE REGEX ?" avec lien vers Regex101.com
- Gestion des patterns : ajout/suppression

## DONNÉES DÉTECTÉES AUTOMATIQUEMENT

### Données Personnelles Françaises
- Adresses email (ex: john@exemple.com)
- Numéros de téléphone français
- Noms et prénoms complets
- Numéros de Sécurité Sociale
- Codes postaux français

### Données Bancaires & Entreprises
- IBAN - Comptes bancaires internationaux
- SIRET - Identifiants entreprises (14 chiffres)
- SIREN - Identifiants entreprises (9 chiffres)
- RIB - Relevés d'identité bancaire
- Numéros de cartes bancaires
- Numéros TVA intracommunautaire

### Données Techniques
- Adresses IP (192.168.1.1)
- Plaques d'immatriculation véhicules
- Numéros de passeport français

### Format de Remplacement
- `john.doe@example.com` → `[EMAIL_1]`
- `Jean Dupont` → `[NOMCOMPLET_1]`
- `01 23 45 67 89` → `[TELEPHONE_1]`

## PERSONNALISATION AVANCÉE

### Créer vos Propres Patterns

#### Exemples de Patterns Utiles
```regex
# Numéro de client
CLIENT_[0-9]{6}

# Référence interne  
REF-[A-Z]{3}-[0-9]{4}

# Code produit
PROD_[A-Z0-9]{8}

# Identifiant employé
EMP[0-9]{5}
```

#### Aide Intégrée
- Bouton "AIDE REGEX ?" avec explications
- Lien direct vers Regex101.com pour créer vos patterns
- Validation en temps réel des expressions régulières

### Interface Responsive
- Fenêtre redimensionnable (min: 1100x750, recommandé: 1200x800)
- Panneaux ajustables

## SÉCURITÉ & CONFIDENTIALITÉ

### Traitement 100% Local
- Aucune donnée envoyée sur internet par l'application
- Traitement en mémoire uniquement
- Vous contrôlez l'envoi vers les LLM

### Restauration Garantie
- Mappage complet de toutes les correspondances
- Aucune perte de données possible
- Réversibilité du processus

### Recommandations
- Vérifiez toujours le texte anonymisé avant envoi
- Ajoutez vos patterns spécifiques si nécessaire
- Gardez une copie de vos documents originaux

## PRÉREQUIS TECHNIQUES

### Système
- Windows (7, 8, 10, 11)
- PowerShell 5.1+ (inclus par défaut)
- Microsoft .NET Framework (généralement déjà installé)

### Installation
```powershell
# Aucune installation requise !
# Téléchargez simplement le fichier et lancez-le :
.\SoulBoundPrompter.ps1
```

### Permissions
```powershell
# Si problème d'exécution, autorisez temporairement :
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned

# Ou lancez directement avec :
powershell -ExecutionPolicy Bypass -File ".\SoulBoundPrompter.ps1"
```

## AVANTAGES CLÉS

### Simplicité Maximale
- Un seul fichier - Aucune dépendance externe
- Interface intuitive avec workflow guidé en 4 étapes
- Messages d'aide contextuels 

### Sécurité Renforcée
- Traitement 100% local - Vos données ne quittent jamais votre machine
- Patterns français intégrés pour la détection automatique
- Réversibilité - Récupération complète des données originales
- Validation des regex pour éviter les erreurs

### Extensibilité
- Patterns personnalisés via expressions régulières
- Aide intégrée avec lien vers Regex101.com
- Interface responsive avec panneaux redimensionnables
- Configuration persistante de vos patterns

## CONCLUSION

SoulBound Prompter vous permet d'utiliser les LLM publics en toute sécurité, en limitant exposition vos données sensibles.

### Mission Accomplie
- Protection automatique pour certains types de données françaises
- Interface intuitive
- Workflow guidé en 4 étapes simples
- Extensibilité via patterns personnalisés
- Sécurité locale - Aucune donnée envoyée par l'app

### Prêt à Utiliser
Lancez `SoulBoundPrompteur.ps1` et protégez vos données sensibles dès maintenant !

Votre vie privée est préservée, votre productivité avec l'IA est maximisée.

## LICENCE ET CONTRIBUTIONS

### Licence GPL v3
Ce projet est distribué sous licence GNU General Public License v3.0. 

**Obligations :**
- Respecter les conditions de réutilisation du programme
- Conserver une copie de la licence dans le même dossier que le script
- Maintenir l'attribution des auteurs originaux

### Contributions Bienvenues
Nous accueillons toutes les contributions pour améliorer le projet :

- **Signalement de bugs :** Créez une issue pour tout problème rencontré
- **Suggestions d'amélioration :** Proposez de nouvelles fonctionnalités
- **Code et documentation :** Soumettez vos pull requests
- **Nouveaux patterns :** Partagez vos expressions régulières utiles

**Comment contribuer :**
1. Forkez le repository
2. Créez une branche pour votre fonctionnalité
3. Testez vos modifications
4. Soumettez une pull request avec description détaillée

### Support Communautaire
- Utilisez les issues GitHub pour les questions techniques
- Partagez vos cas d'usage et retours d'expérience
- Aidez les autres utilisateurs dans leurs problématiques 
