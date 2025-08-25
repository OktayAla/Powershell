Import-Module ActiveDirectory

$pcs = Get-ADComputer -Filter * | Select-Object -ExpandProperty Name
Write-Host "Domain'deki bilgisayarlar:" -ForegroundColor Cyan
$pcs

$targetPC = Read-Host "Bilgisayar Adı:"

Invoke-Command -ComputerName $targetPC -ScriptBlock { Start-MpScan -ScanType QuickScan }