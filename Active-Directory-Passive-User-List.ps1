$inactiveDays = 90
$lastLogonDate = (Get-Date).AddDays(-$inactiveDays)

Search-ADAccount -AccountInactive -UsersOnly -DateTime $lastLogonDate | 
    Where-Object { $_.Enabled -eq $true } | 
    Select-Object Name, SamAccountName, LastLogonDate