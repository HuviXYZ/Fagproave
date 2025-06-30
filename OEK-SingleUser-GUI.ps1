
Add-Type -AssemblyName System.Windows.Forms

# Mapping of OUs
$ouMap = @{
    "Ansatte"  = "OU=Ansatte,OU=Users,OU=OeKommune,DC=OEKOMMUNE,DC=ad"
    "ITavd"    = "OU=ITavd,OU=Users,OU=OeKommune,DC=OEKOMMUNE,DC=ad"
    "Eksterne" = "OU=Eksterne,OU=Users,OU=OeKommune,DC=OEKOMMUNE,DC=ad"
}

# List of available license groups
$licenseGroups = @(
    "Microsoft 365 Business Premium",
    "Microsoft 365 F1",
    "Microsoft 365 F3",
    "Microsoft 365 E3"
)

# Function to create a new user
function New-OEKADUser {
    param (
        [string]$Name,
        [string]$Username,
        [string]$OU,
        [string[]]$Groups
    )

    $password = "Oek!" + ([System.Guid]::NewGuid().ToString("N").Substring(0,8))
    $securePass = ConvertTo-SecureString $password -AsPlainText -Force
    $upn = "$Username@oekommune.site"

    New-ADUser -Name $Name `
        -SamAccountName $Username `
        -UserPrincipalName $upn `
        -Path $OU `
        -AccountPassword $securePass `
        -Enabled $true `
        -ChangePasswordAtLogon $true `
        -Company "Øst kommune" `
        -DisplayName $Name `
        -GivenName ($Name -split " ")[0] `
        -Surname ($Name -split " ")[-1]

    foreach ($grp in $Groups) {
        Add-ADGroupMember -Identity $grp -Members $Username
    }

    [System.Windows.Forms.MessageBox]::Show("✅ Bruker '$Name' ble opprettet med brukernavn '$Username' og passord '$password'", "Brukeropprettelse")
}

# GUI Setup
$form = New-Object System.Windows.Forms.Form
$form.Text = "Opprett ny AD-bruker"
$form.Size = New-Object System.Drawing.Size(420, 400)

$labelName = New-Object System.Windows.Forms.Label
$labelName.Text = "Fullt navn:"
$labelName.Location = New-Object System.Drawing.Point(10, 20)
$form.Controls.Add($labelName)

$textBoxName = New-Object System.Windows.Forms.TextBox
$textBoxName.Location = New-Object System.Drawing.Point(140, 20)
$textBoxName.Size = New-Object System.Drawing.Size(250, 20)
$form.Controls.Add($textBoxName)

$labelUsername = New-Object System.Windows.Forms.Label
$labelUsername.Text = "Brukernavn:"
$labelUsername.Location = New-Object System.Drawing.Point(10, 60)
$form.Controls.Add($labelUsername)

$textBoxUsername = New-Object System.Windows.Forms.TextBox
$textBoxUsername.Location = New-Object System.Drawing.Point(140, 60)
$textBoxUsername.Size = New-Object System.Drawing.Size(250, 20)
$form.Controls.Add($textBoxUsername)

$labelOU = New-Object System.Windows.Forms.Label
$labelOU.Text = "Velg OU:"
$labelOU.Location = New-Object System.Drawing.Point(10, 100)
$form.Controls.Add($labelOU)

$comboBoxOU = New-Object System.Windows.Forms.ComboBox
$comboBoxOU.Items.AddRange(@("Ansatte", "ITavd", "Eksterne"))
$comboBoxOU.Location = New-Object System.Drawing.Point(140, 100)
$comboBoxOU.Size = New-Object System.Drawing.Size(250, 20)
$form.Controls.Add($comboBoxOU)

$labelLicenses = New-Object System.Windows.Forms.Label
$labelLicenses.Text = "Lisensgrupper:"
$labelLicenses.Location = New-Object System.Drawing.Point(10, 140)
$form.Controls.Add($labelLicenses)

$checkedListBox = New-Object System.Windows.Forms.CheckedListBox
$checkedListBox.Location = New-Object System.Drawing.Point(140, 140)
$checkedListBox.Size = New-Object System.Drawing.Size(250, 80)
$licenseGroups | ForEach-Object { $checkedListBox.Items.Add($_) }
$form.Controls.Add($checkedListBox)

$buttonCreate = New-Object System.Windows.Forms.Button
$buttonCreate.Text = "Opprett bruker"
$buttonCreate.Location = New-Object System.Drawing.Point(140, 240)
$buttonCreate.Add_Click({
    $name = $textBoxName.Text
    $username = $textBoxUsername.Text
    $ou = $ouMap[$comboBoxOU.SelectedItem]
    $selectedGroups = @()
    foreach ($i in 0..($checkedListBox.Items.Count - 1)) {
        if ($checkedListBox.GetItemChecked($i)) {
            $selectedGroups += $checkedListBox.Items[$i]
        }
    }
    if ($comboBoxOU.SelectedItem -eq "ITavd") {
        $selectedGroups += "IT", "Employees", "OEK-VPN-TILGANG"
    } elseif ($comboBoxOU.SelectedItem -eq "Ansatte") {
        $selectedGroups += "Employees", "OEK-VPN-TILGANG"
    } elseif ($comboBoxOU.SelectedItem -eq "Eksterne") {
        $selectedGroups += "External"
    }
    New-OEKADUser -Name $name -Username $username -OU $ou -Groups $selectedGroups
})
$form.Controls.Add($buttonCreate)

# Show form
$form.Topmost = $true
$form.Add_Shown({$form.Activate()})
$form.ShowDialog()
