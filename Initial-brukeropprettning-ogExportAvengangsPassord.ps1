
# Script to create AD users and export credentials (UPN is generated dynamically)

$csvPath = "C:\Passord\OEK-INITIALE-BRUKERE.csv"
$exportPath = "C:\Passord\OEK-UserCredentials.csv"

$users = Import-Csv -Path $csvPath
$exportList = @()

foreach ($user in $users) {
    # Generer sikkert passord
    $pass = "Oek!" + ([System.Guid]::NewGuid().ToString("N").Substring(0,8))
    $securePass = ConvertTo-SecureString $pass -AsPlainText -Force

    # Generer UPN basert på brukernavn
    $upn = "$($user.Username)@oekommune.site"

    # Velg riktig OU
    switch ($user.OU) {
        "Employees" { $ouPath = "OU=Ansatte,OU=Users,OU=OeKommune,DC=OEKOMMUNE,DC=ad" }
        "IT"        { $ouPath = "OU=ITavd,OU=Users,OU=OeKommune,DC=OEKOMMUNE,DC=ad" }
        "External"  { $ouPath = "OU=Eksterne,OU=Users,OU=OeKommune,DC=OEKOMMUNE,DC=ad" }
        default     { $ouPath = "OU=Misc,OU=Users,OU=OeKommune,DC=OEKOMMUNE,DC=ad" }
    }

    try {
        # Opprett bruker
        New-ADUser `
            -Name $user.DisplayName `
            -GivenName $user.FirstName `
            -Surname $user.LastName `
            -SamAccountName $user.Username `    
            -UserPrincipalName $upn `
            -EmailAddress $upn `
            -AccountPassword $securePass `
            -Path $ouPath `
            -Department $user.Department `
            -Company $user.Company `
            -Enabled $true `
            -ChangePasswordAtLogon $true

        # Legg til bruker i grupper
        $groups = $user.Groups -split ";"
        foreach ($group in $groups) {
            Add-ADGroupMember -Identity $group -Members $user.Username
        }

        # Legg til i eksport
        $exportList += [PSCustomObject]@{
            Username = $user.Username
            Phone    = $user.Phone
            UPN      = $upn
            Password = $pass
        }
    }
    catch {
        Write-Host "Feil ved opprettelse av $($user.Username): $_" -ForegroundColor Red
    }
}

# Eksporter brukerinformasjon
$exportList | Export-Csv -Path $exportPath -NoTypeInformation -Encoding UTF8
