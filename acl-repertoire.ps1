# Script d'affichage des droits sur un dossier
###################################################################
#  AUTEUR  : Thomas ZIMMER.                    
#  Date    : 10/12/2021                                        
#  Comment : En entrée, le script va demander un chemin de dossier
#            puis le niveau de récursivité, ensuite il va générer
#            un fichier CSV donnant les droits de chaque groupe
#            sur le dossier et ses sous-dossiers.
###################################################################

# Initialisation des variables globales pour stocker les résultats
$result = @()  
$GLOBAL:ListeDroits = @()

# Fonction qui récupère les droits d'accès pour un répertoire donné
Function Get_Droits {
    Param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [String[]] $dossier_source,  # Le répertoire à analyser
        [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
        [String[]]$Domain = "CHU-LYON"  # Domaine par défaut
    )

    # Récupération des droits d'accès sur le dossier spécifié
    # Le domaine est filtré pour ne récupérer que les utilisateurs du domaine spécifié
    $Liste_Droit_Rep = Get-Acl -Path $dossier_source | select -ExpandProperty Access | ?{ $_.IdentityReference -match "$Domain" }

    # Parcours des droits pour chaque utilisateur du domaine
    ForEach ($Droit_Rep in $Liste_Droit_Rep) {
        # Extraction du type de droit (Lecture, Ecriture, etc.)
        $fileSystemRights = $Droit_Rep | Select-Object -Expand FileSystemRights -First 1

        # Détermination du droit en français basé sur le code numérique
        Switch ($($fileSystemRights.Value__)) {
            '1179817' { $Droit_User = "Lecture" }
            '1180095' { $Droit_User = "Ecriture" }
            '1245631' { $Droit_User = "Affichage du contenu" }
            '2032127' { $Droit_User = "Controle Total" }
            Default { $Droit_User = $($fileSystemRights.Value__) }
        }

        # Création d'un objet pour stocker les informations sur le droit
        $Properties = @{
            Dossier = $dossier_source
            Nom     = $Droit_Rep.IdentityReference
            Herite  = $Droit_Rep.IsInherited
            Droit   = $Droit_User
        }

        # Ajout de l'objet à la liste globale
        $GLOBAL:ListeDroits += New-Object -TypeName PSObject -Property $Properties
    }
}

# Demande du répertoire à analyser
$Dossiers = Read-Host "Chemin du répertoire ?"

# Demande du niveau de récursivité
[int]$pronf = Read-Host "Niveau de récursivité ?"

# Si aucun niveau n'est spécifié, la profondeur par défaut est 0
if (!($pronf)) { $pronf = 0 }

# Appel de la fonction pour récupérer les droits sur le répertoire de base
Get_Droits -Dossier_Source $Dossiers -Domain "CHU-LYON"

# Si le niveau de récursivité est supérieur à 0, on cherche les sous-répertoires
if ($pronf -gt 0) {
    $pronf -= $pronf  # Remise à 0 de la profondeur
    # Recherche des sous-répertoires avec la profondeur spécifiée
    $search = (Get-ChildItem -path $Dossiers -Recurse -Depth $pronf)
    foreach ($dossier_source in $search) {
        # Appel de la fonction pour chaque sous-répertoire
        Get_Droits -Dossier_Source $($dossier_source.FullName) -Domain "CHU-LYON"
    }
}

# Récupération de la liste des répertoires distincts
$Liste_Rep = $($GLOBAL:ListeDroits.Dossier) | Sort | Get-Unique

# Parcours de la liste des répertoires pour traiter les droits d'accès
ForEach ($Rep in $Liste_Rep) {

    # Initialisation des variables pour les droits hérités et non hérités
    $Liste_lecture_Herite = $Liste_ecriture_Herite = $liste_lister_Herite = ""
    $Liste_lecture_Pas_Herite = $Liste_ecriture_Pas_Herite = $liste_lister_Pas_Herite = ""

    # Parcours de la liste des droits pour chaque utilisateur et répertoire
    foreach ($element in $global:ListeDroits) {
        # Vérifie si le dossier correspond à celui en cours d'analyse
        If ($element.Dossier -eq $Rep) {
            # Récupération des valeurs associées (nom de l'utilisateur, droit, héritage)
            [string]$nom = ($element.Nom)
            $nom += ", "
            $droit = $element.Droit
            $Herite = $element.Herite
            $chemin = $element.Dossier

            # Si le droit n'est pas hérité, on le place dans la liste des non hérités
            if ($Herite -eq $false) {
                Switch ($droit) {
                    "Controle Total" { $Liste_lecture_Pas_Herite += $nom; $Liste_ecriture_Pas_Herite += $nom; $liste_lister_Pas_Herite += $nom }
                    "Lecture" { $Liste_lecture_Pas_Herite += $nom }
                    "Ecriture" { $Liste_ecriture_Pas_Herite += $nom }
                    "Affichage du contenu" { $liste_lister_Pas_Herite += $nom }
                }
            }
            Else {  # Si le droit est hérité, on le place dans la liste des hérités
                Switch ($droit) {
                    "Controle Total" { $Liste_lecture_Herite += $nom; $Liste_ecriture_Herite += $nom; $liste_lister_Herite += $nom }
                    "Lecture" { $Liste_lecture_Herite += $nom }
                    "Ecriture" { $Liste_ecriture_Herite += $nom }
                    "Affichage du contenu" { $liste_lister_Herite += $nom }
                }
            }
        }
    }

    # Si des droits hérités existent, on les ajoute à la liste des résultats
    If (($Liste_lecture_Herite) -or ($Liste_ecriture_Herite) -or ($liste_lister_Herite)) {
        $details_herite = @{
            Repertoire    = $Rep
            date_creation = (Get-Date ((Get-Item $Rep).CreationTime) -Format "dd/MM/yyyy")
            Lecture       = $Liste_lecture_Herite
            Ecriture      = $Liste_ecriture_Herite
            Lister        = $liste_lister_Herite
            droit_herite  = "VRAI"
        }
        $result += New-Object PSObject -Property $details_herite
    }

    # Si des droits non hérités existent, on les ajoute aussi à la liste des résultats
    If (($Liste_lecture_Pas_Herite) -or ($Liste_ecriture_Pas_Herite) -or ($liste_lister_Pas_Herite)) {
        $details_Pas_herite = @{
            Repertoire    = $Rep
            date_creation = (Get-Date ((Get-Item $Rep).CreationTime) -Format "dd/MM/yyyy")
            Lecture       = $Liste_lecture_Pas_Herite
            Ecriture      = $Liste_ecriture_Pas_Herite
            Lister        = $liste_lister_Pas_Herite
            droit_herite  = "FAUX"
        }
        $result += New-Object PSObject -Property $details_Pas_herite
    }
}

# Export des résultats dans un fichier CSV
$result | Select-Object Repertoire, date_creation, Lecture, Ecriture, Lister, droit_herite | Export-Csv -Path "recup_acl-repertoire.csv" -NoTypeInformation -Delimiter ";" -Encoding UTF8

# Affichage du message de confirmation
Write-Host "Le fichier recup_acl-repertoire.csv se trouve au même emplacement que le script."
