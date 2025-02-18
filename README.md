# Script PowerShell : Affichage des droits sur un dossier

## Description

Le script PowerShell a pour objectif de rechercher et d'afficher les droits d'accès des groupes d'utilisateurs sur un répertoire donné. Il permet de visualiser les droits sur les dossiers spécifiés, en incluant les droits hérités ou non hérités, et génère un fichier CSV contenant les résultats.

## Fonctionnement

1. **Demande du répertoire source**  
   Le script demande à l'utilisateur de saisir le chemin du répertoire à analyser.

2. **Demande du niveau de récursivité**  
   Ensuite, l'utilisateur est invité à entrer le niveau de récursivité pour l'exploration des sous-répertoires. Ce niveau définit la profondeur d'analyse des répertoires (par exemple, un niveau = un sous-répertoire direct, un niveau 0 = pas de récursivité).

3. **Récupération des droits d'accès**  
   Le script examine les droits des groupes sur chaque répertoire, en vérifiant si les droits sont hérités ou non. Les droits analysés incluent :
   - **Lecture**
   - **Écriture**
   - **Affichage du contenu**
   - **Contrôle total**

4. **Création du fichier CSV**  
   Le script génère un fichier CSV nommé `recup_acl-repertoire.csv` qui contient les informations suivantes pour chaque répertoire :
   - **Répertoire** : Chemin complet du répertoire.
   - **Date de création** : Date de création du répertoire.
   - **Lecture** : Groupes ayant le droit de lecture.
   - **Écriture** : Groupes ayant le droit d'écriture.
   - **Lister** : Groupes ayant le droit d'exécution (Lister).
   - **Droit hérité** : Si les droits sont hérités (`VRAI`) ou non hérités (`FAUX`).

5. **Affichage de l'emplacement du fichier**  
   Une fois le fichier généré, un message s'affiche pour informer l'utilisateur que le fichier a été créé dans le même répertoire que celui du script.

## Détail des colonnes dans le fichier CSV

Le fichier CSV généré contient les colonnes suivantes :

- **Répertoire** : Chemin du répertoire analysé.
- **Date création** : Date de création du répertoire.
- **Lecture** : Liste des groupes ayant le droit de lecture.
- **Écriture** : Liste des groupes ayant le droit d'écriture.
- **Lister** : Liste des groupes ayant le droit d'exécution (Lister).
- **Droit hérité** : Si les droits sont hérités (`VRAI`) ou non hérités (`FAUX`).
