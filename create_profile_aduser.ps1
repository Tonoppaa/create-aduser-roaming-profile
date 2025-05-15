# Profiilin luominen toimialueen käyttäjälle

# Käyttäjien luku tiedostosta

$tiedostoPolku = "C:\Käyttäjätiedostot\kayttajaprofiilit.txt"

# Määritetään polku profiilikansiolle

$profiiliPolkuKansio = "C:\Profiilit_Huipputiimi"
$profiiliKansio = "Profiilit_Huipputiimi"
$tarkistaKansio = Get-Item -Filter $profiiliKansio -Path $profiiliPolkuKansio -ErrorAction SilentlyContinue

Write-Host ""
Write-Output "Tarkistetaan, onko kansio jo luotu..."
if($tarkistaKansio -eq $null) {
    New-Item -Path $profiiliPolkuKansio -ItemType Directory
    Write-Host ""
    Write-Output "Uusi kansio luotu nimeltä $profiiliKansio"
    Write-Host ""
} else {
    Write-Output "Kansio nimeltä $profiiliKansio on jo luotu."
    Write-Host ""
}

# Luodaan tarvittaessa organisaatioyksikkö / ryhmä

$haeProfiiliOU = Get-ADOrganizationalUnit -Filter "Name -eq 'Käyttäjäprofiilit'"

Write-Output "Tarkistetaan, onko AD OU kansio jo luotu..."
Write-Host ""
if($haeProfiiliOU -eq $null) {
    Write-Output "Toimialueella ei ollut organisaatioyksikköä nimeltä Käyttäjäprofiilit. Luodaan uusi..."
	New-ADOrganizationalUnit -Name "Käyttäjäprofiilit" -Path "DC=testimetsa24,DC=edu"
	Write-Output "Uusi käyttäjäprofiili organisaatioyksikkö on luotu!"
    Write-Host ""
} else {
	Write-Output "Organisaatioyksikkö nimeltä Käyttäjäprofiilit on jo luotu!"
    Write-Host ""
}

# Käyttäjäprofiilit ADGroup luominen / tarkistus

$haeProfiiliRyhmä = Get-ADGroup -Filter "Name -eq 'Käyttäjäprofiilit'" -ErrorAction SilentlyContinue

Write-Output "Tarkistetaan, onko ADGroup Käyttäjäprofiilit jo luotu..."
Write-Host ""
if($haeProfiiliRyhmä -eq $null) {
    Write-Host "Käyttäjäprofiilit ADGroup puuttuu. Luodaan uusi..."
	New-ADGroup -Name "Käyttäjäprofiilit" -GroupScope Global -Path "OU=Käyttäjäprofiilit,DC=testimetsa24,DC=edu"
	Write-Output "Uusi ryhmä Käyttäjäprofiilit on luotu!"
    Write-Host ""
} else {
	Write-Output "ADGroup nimeltä Käyttäjäprofiilit on jo luotu!"
    Write-Host ""
}

# Uuden toimialueen käyttäjän luominen

# Tarkistetaan, onko tiedosto olemassa
if (Test-Path -Path $tiedostoPolku) {
    # Luetaan tekstitiedosto rivi kerrallaan ja käsitellään käyttäjät "kayttajat.txt"-tiedostosta
    Get-Content $tiedostoPolku | ForEach-Object {
	$kayttaja = $_ -split ","
	# Write-Output "kayttaja $kayttaja kasitelty"
	$etuNimi = $kayttaja[0]
        # Write-Output "etunimi $etuNimi kasitelty"
        $sukuNimi = $kayttaja[1]
        # Write-Output "sukunimi $sukuNimi kasitelty"
        $samAccountName = $kayttaja[2]
        # Write-Output "samaccountname $samAccountName kasitelty"
        $userPrincipalName = $kayttaja[3]
        # Write-Output "userprincipalname $userPrincipalName kasitelty"
        $testiSalasana = $kayttaja[4]
        # Write-Output "salasana on $testiSalasana"
        $salaSana = ConvertTo-SecureString $kayttaja[4] -AsPlainText -Force
	
	# Organisaatioyksikkö
	$OU = "OU=Käyttäjäprofiilit,DC=testimetsa24,DC=edu"

    # Organisaatioyksikön käyttäjä
	$ADUser = Get-ADUser -Filter "SamAccountName -eq '$($samAccountName)'" -SearchBase $OU

	# Luodaan tarkistus SamAccountName:n mukaan; verrataan onko kayttajaprofiilit.txt-käyttäjä jo organisaatioyksikössä
	if($ADUser -eq $null)
	    {
		# Luo uusi käyttäjä Käyttäjäprofiilit-organisaatioyksikköön, jos kyseistä käyttäjää ei ole
        New-ADUser -Name "$etuNimi $sukuNimi" -GivenName $etuNimi -Surname $sukuNimi -SamAccountName $samAccountName `
        -UserPrincipalName $userPrincipalName -AccountPassword $salaSana -Path $OU -Enabled $true
		Write-Output "Uusi AD-käyttäjä luotu!"
        Write-Host ""
	    }
	}

    # Käyttäjän lisääminen ADGroupiin eli Käyttäjäprofiilit ADGroup:n

    # Haetaan ensin kaikki ADGroupin jäsenet
    $haeADUserGroup = Get-ADGroupMember -Identity "Käyttäjäprofiilit" -ErrorAction SilentlyContinue

    # Tarkistus, onko käyttäjä jo ryhmässä
    Write-Output "Tarkistetaan, onko käyttäjä jo ryhmässä..."
    Write-Host ""

    $tarkistaKäyttäjäADGroup = $haeADUserGroup | Where-Object {$_.SamAccountName -eq $samAccountName}
    if($tarkistaKäyttäjäADGroup -eq $null) {
        Add-ADGroupMember -Identity "Käyttäjäprofiilit" -Member $samAccountName
        Write-Output "Käyttäjä $samAccountName on lisätty Käyttäjäprofiilit-ryhmään!"
        Write-Host ""
    } else {
        Write-Output "Käyttäjä $samAccountName on jo Käyttäjäprofiilit-ryhmässä!"
        Write-Host ""
    }
}

# Kansion jakaminen

$jaonTarkistus = Get-SmbShare -Name $profiiliKansio -ErrorAction SilentlyContinue

Write-Output "Tarkistetaan, onko kansion jako jo luotu..."
Write-Host ""
if($jaonTarkistus -eq $null) {
    Write-Host "Kansio $profiilikansio ei ole vielä jaettu. Jaetaan..."
	New-SmbShare -Name $profiiliKansio -Path $profiiliPolkuKansio -FullAccess "testimetsa24.edu\Käyttäjäprofiilit"
	Write-Output "Uusi jako luotu kansioon $profiiliKansio!"
    Write-Host ""
} else {
	Write-Output "Kansio $profiilikansio on jo jaettu!"
    Write-Host ""
}

# Profiilipolun luominen

# Tarkistus, onko profiilipolku jo olemassa
Write-Output "Tarkistetaan, onko käyttäjän profiilipolku jo luotu..."
Write-Host ""
if($ADUser.ProfilePath -eq $null) {
    Write-Host "Profiilipolku ei ole vielä luotu. Luodaan uusi..."
	Set-ADUser -Identity $samAccountName -ProfilePath "\\PalvelinKomento\Profiilit_Huipputiimi\%USERNAME%"
	Write-Output "Profiilipolku luotu käyttäjälle $samAccountName"
    Write-Host ""
} else {
	Write-Output "Profiilipolku on jo olemassa käyttäjälle $samAccountName"
    Write-Host ""
}
Write-Output "Valmis."