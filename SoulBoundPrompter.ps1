# SoulBound Prompter 

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Set console encoding to UTF-8 to handle accents properly
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

# Variables globales
$global:anonymizationMap = @{}
$global:reverseMap = @{}
$global:userAddedPatterns = @{}
$global:counter = 1

# Patterns par defaut integres
$global:defaultPatterns = @{
    'Email' = '\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'
    'Telephone' = '(?:\+33|0)[1-9][0-9]{8}'
    'NomComplet' = '\b[A-Z][a-z]{2,15}\s+[A-Z][a-z]{2,15}\b'
    'AdresseIP' = '\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b'
    'CodePostal' = '\b[0-9]{5}\b'
    'IBAN' = '\b[A-Z]{2}[0-9]{2}[A-Z0-9]{4}[0-9]{7}[A-Z0-9]{0,16}\b'
    'SIRET' = '\b[0-9]{14}\b'
    'SIREN' = '\b[0-9]{9}\b'
    
    # Patterns pour données de santé
    'NumSecu' = '\b[1-2][0-9]{2}(0[1-9]|1[0-2])[0-9]{2}[0-9]{3}[0-9]{3}(0[1-9]|[1-8][0-9]|9[0-7])\b'
    'INS' = '\b[0-9]{15}\b'
    'CodeALD' = '\bALD[0-9]{1,2}\b'
    'FINESS' = '\b[0-9]{9}\b'
    'DossierMedical' = '\b(?:DOS|MED|PAT)[0-9]{6,10}\b'
    'CodePathologie' = '\b[A-Z][0-9]{2}\.[0-9]{1,2}\b'
    'NumAmeli' = '\b[0-9]{13}\b'
    'CodeMutuelle' = '\b[0-9]{3}[A-Z]{2}[0-9]{6}\b'
    
    # Adresses géographiques détaillées
    'AdresseComplete' = '\b[0-9]{1,4}[,]?\s+(?:rue|avenue|boulevard|place|impasse|chemin|route)[^,\n]{5,50}[,]?\s+[0-9]{5}\s+[A-Z][a-z]{2,30}\b'
    'VilleCodePostal' = '\b[0-9]{5}\s+[A-Z][a-z]{2,30}\b'
    
    # Patterns financiers étendus
    'RIB' = '\b[0-9]{5}\s[0-9]{5}\s[A-Z0-9]{11}\s[0-9]{2}\b'
    'CarteBancaire' = '\b[0-9]{4}[\s-]?[0-9]{4}[\s-]?[0-9]{4}[\s-]?[0-9]{4}\b'
    'NumPasseport' = '\b[0-9]{2}[A-Z]{2}[0-9]{5}\b'
    'PlaqueMoto' = '\b[A-Z]{2}[-\s]?[0-9]{3}[-\s]?[A-Z]{2}\b'
    'TVAIntra' = '\bFR[0-9A-Z]{2}[0-9]{9}\b'
    
    # Identifiants techniques
    'UUID' = '\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b'
    'TokenID' = '\b[A-Za-z0-9]{20,}\b'
}

# Fonction d'anonymisation
function Anonymize-Text {
    param([string]$text)
    
    $global:anonymizationMap = @{}
    $global:reverseMap = @{}
    $global:counter = 1
    $result = $text
    $totalMatches = 0
    
    # Patterns par defaut
    foreach ($patternName in $global:defaultPatterns.Keys) {
        $pattern = $global:defaultPatterns[$patternName]
        $matches = [regex]::Matches($result, $pattern)
        $totalMatches += $matches.Count
        
        foreach ($match in $matches) {
            $originalValue = $match.Value
            
            if (-not $global:anonymizationMap.ContainsKey($originalValue)) {
                $placeholder = "[$($patternName.ToUpper())_$global:counter]"
                $global:anonymizationMap[$originalValue] = $placeholder
                $global:reverseMap[$placeholder] = $originalValue
                $global:counter++
            }
            
            $result = $result -replace [regex]::Escape($originalValue), $global:anonymizationMap[$originalValue]
        }
    }
    
    # Patterns utilisateur
    foreach ($patternName in $global:userAddedPatterns.Keys) {
        $pattern = $global:userAddedPatterns[$patternName]
        $matches = [regex]::Matches($result, $pattern)
        $totalMatches += $matches.Count
        
        foreach ($match in $matches) {
            $originalValue = $match.Value
            
            if (-not $global:anonymizationMap.ContainsKey($originalValue)) {
                $placeholder = "[USER_$($patternName.ToUpper())_$global:counter]"
                $global:anonymizationMap[$originalValue] = $placeholder
                $global:reverseMap[$placeholder] = $originalValue
                $global:counter++
            }
            
            $result = $result -replace [regex]::Escape($originalValue), $global:anonymizationMap[$originalValue]
        }
    }
    
    return $result
}

# Fonction de desanonymisation
function Deanonymize-Text {
    param([string]$text)
    
    $result = $text
    $replacements = 0
    
    # Restauration des données anonymisées
    foreach ($placeholder in $global:reverseMap.Keys) {
        $originalValue = $global:reverseMap[$placeholder]
        if ($result.Contains($placeholder)) {
            $result = $result.Replace($placeholder, $originalValue)
            $replacements++
        }
    }
    
    # Nettoyage formatage LLM
    $result = $result -replace '&quot;', '"'
    $result = $result -replace '&lt;', '<'
    $result = $result -replace '&gt;', '>'
    $result = $result -replace '&amp;', '&'
    $result = $result -replace '\*\*(.*?)\*\*', '$1'
    $result = $result -replace '\*(.*?)\*', '$1'
    $result = $result -replace '`(.*?)`', '$1'
    
    return $result
}

# Interface XML Responsive
$interfaceXML = @"
<Interface>
    <Form Text="SoulBound Prompter - Protection des donnees sensibles" Width="1200" Height="800" BackColor="DimGray" StartPosition="CenterScreen" MinWidth="1100" MinHeight="750">
        <Title Text="SoulBound Prompter - Protection LLM" XPercent="2" YPercent="1" WidthPercent="96" HeightPercent="3" FontSize="18" FontStyle="Bold" Color="White"/>
        <Subtitle Text="Anonymisez vos donnees avant envoi vers un LLM, puis restaurez-les" XPercent="2" YPercent="4.5" WidthPercent="96" HeightPercent="2" FontSize="10" FontStyle="Regular" Color="LightGray"/>
        
        <LeftPanel XPercent="2" YPercent="8" WidthPercent="47" HeightPercent="88" BackColor="Gainsboro" BorderStyle="FixedSingle">
            <StepLabel1 Text="ETAPE 1 - Texte original" XPercent="4" YPercent="2" WidthPercent="92" HeightPercent="4" FontSize="11" FontStyle="Bold" Color="DarkSlateBlue"/>
            <InputLabel Text="Collez ici votre texte contenant des donnees sensibles :" XPercent="4" YPercent="6" WidthPercent="92" HeightPercent="3" FontSize="9" FontStyle="Regular" Color="DarkSlateGray"/>
            <InputBox XPercent="4" YPercent="10" WidthPercent="92" HeightPercent="14" Multiline="true" ScrollBars="Vertical"/>
            
            <AnonymizeBtn Text="1. ANONYMISER LE TEXTE" XPercent="4" YPercent="26" WidthPercent="44" HeightPercent="6" BackColor="DarkGreen" ForeColor="White"/>
            <CopyBtn Text="2. COPIER TEXTE SECURISE" XPercent="50" YPercent="26" WidthPercent="46" HeightPercent="6" BackColor="DarkBlue" ForeColor="White"/>
            
            <StepLabel2 Text="ETAPE 2 - Texte anonymise" XPercent="4" YPercent="34" WidthPercent="92" HeightPercent="4" FontSize="11" FontStyle="Bold" Color="DarkSlateBlue"/>
            <SecureLabel Text="Texte pret pour envoi au LLM (donnees remplacees par des codes) :" XPercent="4" YPercent="38" WidthPercent="92" HeightPercent="3" FontSize="9" FontStyle="Regular" Color="DarkSlateGray"/>
            <SecureBox XPercent="4" YPercent="42" WidthPercent="92" HeightPercent="12" Multiline="true" ScrollBars="Vertical" ReadOnly="true" BackColor="PaleGreen"/>
            
            <StepLabel3 Text="ETAPE 3 - Reponse du LLM" XPercent="4" YPercent="56" WidthPercent="92" HeightPercent="4" FontSize="11" FontStyle="Bold" Color="DarkSlateBlue"/>
            <ResponseLabel Text="Collez ici la reponse recue du LLM :" XPercent="4" YPercent="60" WidthPercent="92" HeightPercent="3" FontSize="9" FontStyle="Regular" Color="DarkSlateGray"/>
            <ResponseBox XPercent="4" YPercent="64" WidthPercent="92" HeightPercent="12" Multiline="true" ScrollBars="Vertical"/>
            
            <DeanonymizeBtn Text="3. RESTAURER DONNEES REELLES" XPercent="4" YPercent="78" WidthPercent="44" HeightPercent="6" BackColor="DarkOrange" ForeColor="White"/>
            <ClearBtn Text="TOUT EFFACER" XPercent="50" YPercent="78" WidthPercent="28" HeightPercent="6" BackColor="DarkRed" ForeColor="White"/>
            
            <StepLabel4 Text="ETAPE 4 - Resultat final" XPercent="4" YPercent="84" WidthPercent="92" HeightPercent="3" FontSize="11" FontStyle="Bold" Color="DarkSlateBlue"/>
            <ResultLabel Text="Reponse finale avec vos donnees reelles restaurees :" XPercent="4" YPercent="87" WidthPercent="92" HeightPercent="2" FontSize="9" FontStyle="Regular" Color="DarkSlateGray"/>
            <ResultBox XPercent="4" YPercent="89" WidthPercent="92" HeightPercent="3" ReadOnly="true" BackColor="LightSteelBlue" Multiline="true" ScrollBars="Vertical"/>
            <CopyResultBtn Text="4. COPIER RESULTAT FINAL" XPercent="4" YPercent="93" WidthPercent="40" HeightPercent="4" BackColor="Indigo" ForeColor="White"/>
        </LeftPanel>
        
        <RightPanel XPercent="51" YPercent="8" WidthPercent="47" HeightPercent="88" BackColor="Gainsboro" BorderStyle="FixedSingle">
            <ConfigTitle Text="CONFIGURATION DES DONNEES SENSIBLES" XPercent="4" YPercent="2" WidthPercent="92" HeightPercent="5" FontSize="12" FontStyle="Bold" Color="DarkSlateBlue"/>
            
            <DefaultLabel Text="Types de donnees automatiquement detectees :" XPercent="4" YPercent="9" WidthPercent="92" HeightPercent="4" FontSize="10" FontStyle="Bold" Color="DarkGreen"/>
            <DefaultList XPercent="4" YPercent="14" WidthPercent="92" HeightPercent="24" BackColor="LightGray"/>
            
            <CustomLabel Text="AJOUTER VOS PROPRES PATTERNS :" XPercent="4" YPercent="40" WidthPercent="92" HeightPercent="4" FontSize="10" FontStyle="Bold" Color="DarkBlue"/>
            
            <NameLabel Text="Nom du pattern :" XPercent="4" YPercent="46" WidthPercent="40" HeightPercent="4" FontSize="9" Color="DarkSlateGray"/>
            <NameBox XPercent="4" YPercent="50" WidthPercent="48" HeightPercent="6"/>
            
            <PatternLabel Text="Expression reguliere (regex) :" XPercent="4" YPercent="58" WidthPercent="60" HeightPercent="4" FontSize="9" Color="DarkSlateGray"/>
            <PatternBox XPercent="4" YPercent="62" WidthPercent="92" HeightPercent="6"/>
            
            <AddBtn Text="AJOUTER PATTERN" XPercent="4" YPercent="70" WidthPercent="38" HeightPercent="6" BackColor="DarkBlue" ForeColor="White"/>
            <HelpBtn Text="AIDE REGEX ?" XPercent="44" YPercent="70" WidthPercent="25" HeightPercent="6" BackColor="Orange" ForeColor="White"/>
            
            <CustomPatternsLabel Text="Vos patterns personnalises :" XPercent="4" YPercent="78" WidthPercent="92" HeightPercent="4" FontSize="10" FontStyle="Bold" Color="DarkGreen"/>
            <CustomList XPercent="4" YPercent="83" WidthPercent="92" HeightPercent="9" BackColor="WhiteSmoke"/>
            <RemoveBtn Text="SUPPRIMER SELECTION" XPercent="4" YPercent="93" WidthPercent="43" HeightPercent="4" BackColor="DarkRed" ForeColor="White"/>
        </RightPanel>
    </Form>
</Interface>
"@

# Fonction pour calculer position/taille responsive
function Get-ResponsiveValue {
    param($percentValue, $containerSize)
    return [int](($percentValue / 100) * $containerSize)
}

# Fonction pour parser XML et créer l'interface responsive
function Create-InterfaceFromXML {
    param([xml]$xmlData)
    
    $formNode = $xmlData.Interface.Form
    $form = New-Object System.Windows.Forms.Form
    $form.Text = $formNode.Text
    $form.Size = New-Object System.Drawing.Size([int]$formNode.Width, [int]$formNode.Height)
    $form.StartPosition = $formNode.StartPosition
    $form.BackColor = [System.Drawing.Color]::FromName($formNode.BackColor)
    
    # Configuration responsive
    if ($formNode.MinWidth) { $form.MinimumSize = New-Object System.Drawing.Size([int]$formNode.MinWidth, [int]$formNode.MinHeight) }
    
    # Variables pour stocker les contrôles
    $controls = @{}
    
    # Créer le titre avec position responsive
    $title = New-Object System.Windows.Forms.Label
    $titleNode = $formNode.Title
    $title.Text = $titleNode.Text
    $title.Location = New-Object System.Drawing.Point((Get-ResponsiveValue $titleNode.XPercent $form.Width), (Get-ResponsiveValue $titleNode.YPercent $form.Height))
    $title.Size = New-Object System.Drawing.Size((Get-ResponsiveValue $titleNode.WidthPercent $form.Width), (Get-ResponsiveValue $titleNode.HeightPercent $form.Height))
    $title.Font = New-Object System.Drawing.Font("Segoe UI", [int]$titleNode.FontSize, [System.Drawing.FontStyle]::Bold)
    $title.ForeColor = [System.Drawing.Color]::FromName($titleNode.Color)
    $form.Controls.Add($title)
    
    # Créer le sous-titre
    $subtitle = New-Object System.Windows.Forms.Label
    $subtitleNode = $formNode.Subtitle
    $subtitle.Text = $subtitleNode.Text
    $subtitle.Location = New-Object System.Drawing.Point((Get-ResponsiveValue $subtitleNode.XPercent $form.Width), (Get-ResponsiveValue $subtitleNode.YPercent $form.Height))
    $subtitle.Size = New-Object System.Drawing.Size((Get-ResponsiveValue $subtitleNode.WidthPercent $form.Width), (Get-ResponsiveValue $subtitleNode.HeightPercent $form.Height))
    $subtitle.Font = New-Object System.Drawing.Font("Segoe UI", [int]$subtitleNode.FontSize, [System.Drawing.FontStyle]::Regular)
    $subtitle.ForeColor = [System.Drawing.Color]::FromName($subtitleNode.Color)
    $form.Controls.Add($subtitle)
    
    # Créer les panels avec dimensionnement responsive
    $leftPanel = New-Object System.Windows.Forms.Panel
    $leftNode = $formNode.LeftPanel
    $leftPanel.Location = New-Object System.Drawing.Point((Get-ResponsiveValue $leftNode.XPercent $form.Width), (Get-ResponsiveValue $leftNode.YPercent $form.Height))
    $leftPanel.Size = New-Object System.Drawing.Size((Get-ResponsiveValue $leftNode.WidthPercent $form.Width), (Get-ResponsiveValue $leftNode.HeightPercent $form.Height))
    $leftPanel.BackColor = [System.Drawing.Color]::FromName($leftNode.BackColor)
    $leftPanel.BorderStyle = $leftNode.BorderStyle
    $leftPanel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Bottom
    $form.Controls.Add($leftPanel)
    
    $rightPanel = New-Object System.Windows.Forms.Panel
    $rightNode = $formNode.RightPanel
    $rightPanel.Location = New-Object System.Drawing.Point((Get-ResponsiveValue $rightNode.XPercent $form.Width), (Get-ResponsiveValue $rightNode.YPercent $form.Height))
    $rightPanel.Size = New-Object System.Drawing.Size((Get-ResponsiveValue $rightNode.WidthPercent $form.Width), (Get-ResponsiveValue $rightNode.HeightPercent $form.Height))
    $rightPanel.BackColor = [System.Drawing.Color]::FromName($rightNode.BackColor)
    $rightPanel.BorderStyle = $rightNode.BorderStyle
    $rightPanel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right -bor [System.Windows.Forms.AnchorStyles]::Bottom
    
    $form.Controls.Add($rightPanel)
    
    # Créer les contrôles du panel gauche
    foreach ($child in $leftNode.ChildNodes) {
        $control = $null
        
        switch ($child.Name) {
            { $_ -like "*Label" } {
                $control = New-Object System.Windows.Forms.Label
                $control.Text = $child.Text
                if ($child.FontSize) { $control.Font = New-Object System.Drawing.Font("Segoe UI", [int]$child.FontSize, [System.Drawing.FontStyle]::Bold) }
                if ($child.Color) { $control.ForeColor = [System.Drawing.Color]::FromName($child.Color) }
            }
            { $_ -like "*Box" } {
                $control = New-Object System.Windows.Forms.TextBox
                if ($child.Multiline -eq "true") { $control.Multiline = $true }
                if ($child.ScrollBars) { $control.ScrollBars = $child.ScrollBars }
                if ($child.ReadOnly -eq "true") { $control.ReadOnly = $true }
                if ($child.BackColor) { $control.BackColor = [System.Drawing.Color]::FromName($child.BackColor) }
                $control.Font = New-Object System.Drawing.Font("Segoe UI", 9)
            }
            { $_ -like "*Btn" } {
                $control = New-Object System.Windows.Forms.Button
                $control.Text = $child.Text
                $control.BackColor = [System.Drawing.Color]::FromName($child.BackColor)
                $control.ForeColor = [System.Drawing.Color]::FromName($child.ForeColor)
                $control.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
                $control.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
            }
        }
        
        if ($control) {
            $control.Location = New-Object System.Drawing.Point((Get-ResponsiveValue $child.XPercent $leftPanel.Width), (Get-ResponsiveValue $child.YPercent $leftPanel.Height))
            $control.Size = New-Object System.Drawing.Size((Get-ResponsiveValue $child.WidthPercent $leftPanel.Width), (Get-ResponsiveValue $child.HeightPercent $leftPanel.Height))
            
            # Configuration d'ancrage pour responsive
            if ($child.Name -like "*Box") {
                if ($child.Name -eq "ResultBox") {
                    # Zone résultat s'étend mais laisse place au bouton copier
                    $control.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right -bor [System.Windows.Forms.AnchorStyles]::Bottom
                } else {
                    # Autres zones de texte s'étendent complètement
                    $control.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
                }
            } elseif ($child.Name -eq "CopyResultBtn") {
                # Bouton copier résultat ancré à droite et en bas
                $control.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right
            } elseif ($child.Name -eq "CopyBtn") {
                # Bouton copier s'étend avec la fenêtre
                $control.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
            } elseif ($child.Name -eq "DeanonymizeBtn") {
                # Bouton désanonymiser s'étend avec la fenêtre
                $control.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
            } elseif ($child.Name -eq "ClearBtn") {
                # Bouton effacer ancré à droite
                $control.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
            } elseif ($child.Name -like "*Label*") {
                # Labels s'étendent horizontalement
                $control.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
            } else {
                $control.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
            }
            
            $leftPanel.Controls.Add($control)
            $controls[$child.Name] = $control
        }
    }
    
    # Créer les contrôles du panel droit
    foreach ($child in $rightNode.ChildNodes) {
        $control = $null
        
        switch ($child.Name) {
            { $_ -like "*Label" -or $_ -like "*Title" } {
                $control = New-Object System.Windows.Forms.Label
                $control.Text = $child.Text
                if ($child.FontSize) { $control.Font = New-Object System.Drawing.Font("Segoe UI", [int]$child.FontSize, [System.Drawing.FontStyle]::Bold) }
                if ($child.Color) { $control.ForeColor = [System.Drawing.Color]::FromName($child.Color) }
            }
            { $_ -like "*Box" } {
                $control = New-Object System.Windows.Forms.TextBox
                if ($child.Multiline -eq "true") { $control.Multiline = $true }
                if ($child.ScrollBars) { $control.ScrollBars = $child.ScrollBars }
                if ($child.ReadOnly -eq "true") { $control.ReadOnly = $true }
                if ($child.BackColor) { $control.BackColor = [System.Drawing.Color]::FromName($child.BackColor) }
                $control.Font = New-Object System.Drawing.Font("Segoe UI", 9)
            }
            { $_ -like "*List" } {
                $control = New-Object System.Windows.Forms.ListBox
                $control.BackColor = [System.Drawing.Color]::FromName($child.BackColor)
                if ($child.Enabled -eq "false") { $control.Enabled = $false }
                $control.Font = New-Object System.Drawing.Font("Segoe UI", 9)
            }
            { $_ -like "*Btn" } {
                $control = New-Object System.Windows.Forms.Button
                $control.Text = $child.Text
                $control.BackColor = [System.Drawing.Color]::FromName($child.BackColor)
                $control.ForeColor = [System.Drawing.Color]::FromName($child.ForeColor)
                $control.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
                $control.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
            }
        }
        
        if ($control) {
            $control.Location = New-Object System.Drawing.Point((Get-ResponsiveValue $child.XPercent $rightPanel.Width), (Get-ResponsiveValue $child.YPercent $rightPanel.Height))
            $control.Size = New-Object System.Drawing.Size((Get-ResponsiveValue $child.WidthPercent $rightPanel.Width), (Get-ResponsiveValue $child.HeightPercent $rightPanel.Height))
            
            # Configuration d'ancrage pour responsive
            if ($child.Name -eq "DefaultList") {
                # Liste des patterns par défaut s'étend et grandit verticalement
                $control.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
            } elseif ($child.Name -eq "CustomList") {
                # Liste des patterns personnalisés s'étend et grandit verticalement
                $control.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right -bor [System.Windows.Forms.AnchorStyles]::Bottom
            } elseif ($child.Name -like "*Box") {
                $control.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
            } elseif ($child.Name -eq "RemoveBtn") {
                # Bouton supprimer ancré en bas
                $control.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left
            } elseif ($child.Name -like "*Btn") {
                $control.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
            } elseif ($child.Name -like "*Label*" -or $child.Name -like "*Title*") {
                # Labels s'étendent horizontalement
                $control.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
            } else {
                $control.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
            }
            
            $rightPanel.Controls.Add($control)
            $controls[$child.Name] = $control
        }
    }
    
    return @{ Form = $form; Controls = $controls }
}



# Parser XML et créer l'interface
[xml]$xml = $interfaceXML
$interface = Create-InterfaceFromXML -xmlData $xml
$form = $interface.Form

# Récupérer les contrôles depuis le XML
$originalTextBox = $interface.Controls["InputBox"]
$anonymizeBtn = $interface.Controls["AnonymizeBtn"]
$copyBtn = $interface.Controls["CopyBtn"]
$anonymizedTextBox = $interface.Controls["SecureBox"]
$llmTextBox = $interface.Controls["ResponseBox"]
$deanonymizeBtn = $interface.Controls["DeanonymizeBtn"]
$clearBtn = $interface.Controls["ClearBtn"]
$finalTextBox = $interface.Controls["ResultBox"]
$copyResultBtn = $interface.Controls["CopyResultBtn"]
$defaultListBox = $interface.Controls["DefaultList"]
$nameTextBox = $interface.Controls["NameBox"]
$patternTextBox = $interface.Controls["PatternBox"]
$addPatternBtn = $interface.Controls["AddBtn"]
$helpBtn = $interface.Controls["HelpBtn"]
$customListBox = $interface.Controls["CustomList"]
$removePatternBtn = $interface.Controls["RemoveBtn"]

$defaultListBox.Items.Add("Numeros de Securite Sociale (ex: 1 85 12 75 123 456 78)") | Out-Null
$defaultListBox.Items.Add("INS - Identifiant National de Sante (ex: 1234567890123)") | Out-Null
$defaultListBox.Items.Add("Codes ALD - Affection Longue Duree (ex: ALD30)") | Out-Null
$defaultListBox.Items.Add("FINESS - Identifiants etablissements sante (ex: 750712184)") | Out-Null
$defaultListBox.Items.Add("Dossiers medicaux (ex: DOS/MED/PAT/123456)") | Out-Null
$defaultListBox.Items.Add("Codes pathologies CIM-10 (ex: C50.1)") | Out-Null
$defaultListBox.Items.Add("Numeros Ameli (ex: 1234567890123)") | Out-Null
$defaultListBox.Items.Add("Codes mutuelles (ex: 123AB123456)") | Out-Null
$defaultListBox.Items.Add("Adresses email (ex: nom.prenom@domaine.fr)") | Out-Null
$defaultListBox.Items.Add("Numeros de telephone francais (ex: 06 12 34 56 78)") | Out-Null
$defaultListBox.Items.Add("Noms et prenoms complets (ex: Dupont Jean-Pierre)") | Out-Null
$defaultListBox.Items.Add("Adresses completes geographiques (ex: 123 rue Example 75001 Paris)") | Out-Null
$defaultListBox.Items.Add("Codes postaux francais (ex: 75001)") | Out-Null
$defaultListBox.Items.Add("IBAN - Comptes bancaires internationaux (ex: FR76 1234 5678 9012 3456 7890 123)") | Out-Null
$defaultListBox.Items.Add("SIRET/SIREN - Identifiants entreprises (ex: 123 456 789 00012)") | Out-Null
$defaultListBox.Items.Add("RIB - Releves d'identite bancaire (ex: 12345 12345 12345678901 23)") | Out-Null
$defaultListBox.Items.Add("Numeros de cartes bancaires (ex: 4974 1234 5678 9012)") | Out-Null
$defaultListBox.Items.Add("Numeros TVA intracommunautaire (ex: FR12345678901)") | Out-Null
$defaultListBox.Items.Add("Adresses IP (ex: 192.168.1.1)") | Out-Null
$defaultListBox.Items.Add("UUID - Identifiants uniques (ex: 550e8400-e29b-41d4-a716-446655440000)") | Out-Null
$defaultListBox.Items.Add("Tokens d'identification (ex: a1b2c3d4e5f6g7h8i9j0kl)") | Out-Null
$defaultListBox.Items.Add("Numeros de passeport francais (ex: 12AB34567)") | Out-Null
$defaultListBox.Items.Add("Plaques d'immatriculation vehicules (ex: AB-123-CD)") | Out-Null


# Gestionnaires evenements
$anonymizeBtn.Add_Click({
    if ($originalTextBox.Text.Trim() -eq "") {
        [System.Windows.Forms.MessageBox]::Show("Veuillez d'abord saisir votre texte original dans la zone ETAPE 1.", "Texte manquant", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        return
    }
    
    $anonymized = Anonymize-Text -text $originalTextBox.Text
    $anonymizedTextBox.Text = $anonymized
    
    if ($global:anonymizationMap.Count -gt 0) {
        $stats = "Anonymisation reussie !`n`n$($global:anonymizationMap.Count) elements sensibles ont ete remplaces par des codes.`n`nVous pouvez maintenant copier le texte securise et l'envoyer a votre LLM."
        [System.Windows.Forms.MessageBox]::Show($stats, "Anonymisation terminee", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } else {
        [System.Windows.Forms.MessageBox]::Show("Aucune donnee sensible detectee dans votre texte.", "Information", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
})

$copyBtn.Add_Click({
    if ($anonymizedTextBox.Text.Trim() -ne "") {
        [System.Windows.Forms.Clipboard]::SetText($anonymizedTextBox.Text)
        [System.Windows.Forms.MessageBox]::Show("Texte securise copie dans le presse-papiers !`n`nVous pouvez maintenant le coller dans votre LLM prefere (ChatGPT, Claude, etc.)", "Copie reussie", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } else {
        [System.Windows.Forms.MessageBox]::Show("Aucun texte a copier. Veuillez d'abord anonymiser votre texte.", "Rien a copier", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
    }
})

$deanonymizeBtn.Add_Click({
    if ($llmTextBox.Text.Trim() -eq "") {
        [System.Windows.Forms.MessageBox]::Show("Veuillez d'abord coller la reponse recue de votre LLM dans la zone ETAPE 3.", "Reponse LLM manquante", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        return
    }
    
    if ($global:reverseMap.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Aucune donnee a restaurer. Veuillez d'abord anonymiser un texte avec l'ETAPE 1.", "Pas de donnees a restaurer", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }
    
    $final = Deanonymize-Text -text $llmTextBox.Text
    $finalTextBox.Text = $final
    
    [System.Windows.Forms.MessageBox]::Show("Restauration terminee !`n`nVos donnees reelles ont ete remises en place dans la reponse du LLM.`n`nVous pouvez maintenant copier le resultat final.", "Restauration reussie", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
})

$clearBtn.Add_Click({
    $result = [System.Windows.Forms.MessageBox]::Show("Etes-vous sur de vouloir effacer toutes les donnees ?`n`nCela supprimera :`n- Votre texte original`n- Le texte anonymise`n- La reponse du LLM`n- Le resultat final`n- Toutes les correspondances memorisees", "Confirmer l'effacement", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
    
    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        $originalTextBox.Clear()
        $anonymizedTextBox.Clear()
        $llmTextBox.Clear()
        $finalTextBox.Clear()
        
        # Reinitialise les mappings
        $global:anonymizationMap = @{}
        $global:reverseMap = @{}
        
        [System.Windows.Forms.MessageBox]::Show("Toutes les donnees ont ete effacees. Vous pouvez recommencer une nouvelle session.", "Nettoyage termine", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
})

$copyResultBtn.Add_Click({
    if ($finalTextBox.Text -ne "") {
        [System.Windows.Forms.Clipboard]::SetText($finalTextBox.Text)
        [System.Windows.Forms.MessageBox]::Show("Resultat final copie dans le presse-papiers !`n`nVotre texte avec les vraies donnees restaurees est pret a etre utilise.", "Copie terminee", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } else {
        [System.Windows.Forms.MessageBox]::Show("Aucun resultat a copier.`n`nVeuillez d'abord :`n1. Anonymiser votre texte`n2. Obtenir une reponse du LLM`n3. Restaurer les donnees", "Pas de resultat", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
})

$addPatternBtn.Add_Click({
    $name = $nameTextBox.Text.Trim()
    $pattern = $patternTextBox.Text.Trim()
    
    if ($name -eq "" -or $pattern -eq "") {
        [System.Windows.Forms.MessageBox]::Show("Veuillez remplir les deux champs :`n- Nom du pattern`n- Expression reguliere (regex)", "Champs incomplets", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }
    
    if ($global:userAddedPatterns.ContainsKey($name)) {
        [System.Windows.Forms.MessageBox]::Show("Un pattern avec ce nom existe deja.`n`nVeuillez choisir un nom different.", "Nom deja utilise", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }
    
    try {
        # Test de validation du pattern
        [regex]::Match("test", $pattern) | Out-Null
        
        # Ajout du pattern
        $global:userAddedPatterns[$name] = $pattern
        $customListBox.Items.Add("$name : $pattern")
        
        # Vider les champs
        $nameTextBox.Text = ""
        $patternTextBox.Text = ""
        
        # Vider le cache pour forcer le retraitement
        $global:processingCache.Clear()
        
        [System.Windows.Forms.MessageBox]::Show("Pattern '$name' ajoute avec succes !`n`nRegex compilée pour performance optimale.`n`nIl sera maintenant utilise lors de l'anonymisation.", "Pattern ajoute", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        [System.Windows.Forms.MessageBox]::Show("L'expression reguliere que vous avez saisie n'est pas valide.`n`nErreur: $($_.Exception.Message)`n`nVerifiez la syntaxe de votre regex.", "Expression invalide", [System.Windows.Forms.MessageBox]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

$helpBtn.Add_Click({
    $helpMessage = @"
AIDE POUR LES EXPRESSIONS REGULIERES (REGEX)

Les patterns personnalises utilisent des expressions regulieres (regex) pour detecter vos donnees sensibles.

EXEMPLES DE PATTERNS UTILES :
• Numero de client : CLIENT_[0-9]{6}
• Reference interne : REF-[A-Z]{3}-[0-9]{4}
• Code produit : PROD_[A-Z0-9]{8}
• Identifiant employe : EMP[0-9]{5}

ATTENTION : Utilisez des REGEX, pas du texte exact !

AIDE EN LIGNE :
Pour creer vos propres regex, utilisez l'outil en ligne :
https://regex101.com

Voulez-vous ouvrir Regex101 dans votre navigateur ?
"@
    
    $result = [System.Windows.Forms.MessageBox]::Show($helpMessage, "Aide - Expressions Regulieres", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Information)
    
    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        try {
            Start-Process "https://regex101.com"
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Impossible d'ouvrir le navigateur.`n`nVeuillez aller manuellement sur : https://regex101.com", "Erreur", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        }
    }
})

$removePatternBtn.Add_Click({
    if ($customListBox.SelectedIndex -ge 0) {
        $selectedItem = $customListBox.SelectedItem.ToString()
        $patternName = $selectedItem.Split(" : ")[0]
        
        $result = [System.Windows.Forms.MessageBox]::Show("Etes-vous sur de vouloir supprimer le pattern '$patternName' ?", "Confirmer la suppression", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
        
        if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
            # Suppression du pattern
            $global:userAddedPatterns.Remove($patternName)
            
            # Suppression de la regex compilée
            $compiledKey = "USER_$patternName"
            if ($global:compiledRegex.ContainsKey($compiledKey)) {
                $global:compiledRegex.Remove($compiledKey)
                Write-Host "Pattern compilé '$patternName' supprimé" -ForegroundColor Yellow
            }
            
            # Suppression de la liste
            $customListBox.Items.RemoveAt($customListBox.SelectedIndex)
            
            # Vider le cache pour forcer le retraitement
            $global:processingCache.Clear()
            
            [System.Windows.Forms.MessageBox]::Show("Pattern '$patternName' supprime avec succes.`n`nCache de performance vidé.", "Pattern supprime", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show("Veuillez d'abord selectionner un pattern dans la liste.", "Aucune selection", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
})

# Lancement
Write-Host "SoulBound Prompter - Started" -ForegroundColor Green

$form.ShowDialog() | Out-Null
