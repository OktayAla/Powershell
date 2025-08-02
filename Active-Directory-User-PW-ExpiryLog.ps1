# Active Directory ve WMI kullanarak domain kullanıcılarının şifre süresini kontrol eden PowerShell scripti
# Bu script, domain kullanıcılarının şifre süresini kontrol eder ve belirli bir süre içinde şifresi bitecek kullanıcıları listeler.
# Kullanıcıların şifre süresi 10 günden az kalanları gösterir.
# Kullanıcı listesi masaüstünde "PasswordExpiryLog.txt" dosyasına kaydedilir.
# Scripti çalıştırmak için AD yetkili kullanıcı hesabıyla oturum açmanız gerekmektedir.

# PowerShell script that checks the password expiry of domain users
# This script checks the password expiry of domain users and lists those whose passwords will expire within a certain period.
# It shows users whose password expiry is less than 10 days.
# The user list is saved to "PasswordExpiryLog.txt" on the desktop.
# To run the script, you need to be logged in with an AD authorized user account.

# Oktay ALA

$WarningDays = 10
Import-Module ActiveDirectory

$LogFilePath = [System.IO.Path]::Combine([Environment]::GetFolderPath("Desktop"), "PasswordExpiryLog.txt")

if (Test-Path $LogFilePath) 
{
    Remove-Item $LogFilePath -Force
}

$Users = Get-ADUser -Filter {Enabled -eq $true -and PasswordNeverExpires -eq $false} `
         -Properties DisplayName, SamAccountName, msDS-UserPasswordExpiryTimeComputed

$FilteredUsers = foreach ($User in $Users) 
{
    $ExpiryDate = [datetime]::FromFileTime($User."msDS-UserPasswordExpiryTimeComputed")
    $DaysLeft = ($ExpiryDate - (Get-Date)).Days

    if ($DaysLeft -le $WarningDays -and $DaysLeft -gt 0) 
    {
        [PSCustomObject]@{
            SamAccountName = $User.SamAccountName
            ExpiryDate     = $ExpiryDate
            DaysLeft       = $DaysLeft
        }
    }
}

$SortedUsers = $FilteredUsers | Sort-Object DaysLeft
"TARIH: $(Get-Date -Format "dd/MM/yyyy HH:mm")" | Out-File -FilePath $LogFilePath -Encoding UTF8
""                                              | Out-File -FilePath $LogFilePath -Append -Encoding UTF8
$LogMessage = "`n----------------------------------------------------`n"
foreach ($User in $SortedUsers) 
{
    $FormattedDate = $User.ExpiryDate.ToString("dd/MM/yyyy HH:mm")
    $LogMessage = @"
Kullanici Adi    :   $($User.SamAccountName)
Bitis Tarihi     :   $FormattedDate ($($User.DaysLeft) gun kaldi)
----------------------------------------------------
"@
    Add-Content -Path $LogFilePath -Value $LogMessage
}