# Active Directory ve WMI kullanarak domainde bulunan bilgisayarın anlık performansını listeleyen PowerShell scripti
# Bu script, seçilen bilgisayarın CPU ve RAM kullanımını gösterir.
# Bilgisayar adını veya sıra numarasını girerek bilgi alabilirsiniz.
# Scripti çalıştırmak için AD yetkili kullanıcı hesabıyla oturum açmanız gerekmektedir.

# PowerShell script that lists the current performance of computers in the domain using Active Directory and WMI.
# This script displays the CPU and RAM usage of the selected computer.
# You can get information by entering the computer name or serial number.
# To run the script, you must log in with an AD authorized user account.

# Oktay ALA

function Get-NetworkComputers {
    try {
        $computers = Get-ADComputer -Filter * -Properties Name | Select-Object -ExpandProperty Name
        return $computers
    }
    catch {
        try {
            $network = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPAddress -ne $null }
            $subnet = $network.IPAddress[0] -replace '\.\d+$', '.*'
            $computers = @()
            
            1..254 | ForEach-Object {
                $ip = $network.IPAddress[0] -replace '\.\d+$', ".$_"
                if (Test-Connection -ComputerName $ip -Count 1 -Quiet) {
                    try {
                        $name = [System.Net.Dns]::GetHostEntry($ip).HostName
                        $computers += $name.Split('.')[0]
                    }
                    catch {
                        $computers += $ip
                    }
                }
            }
            return $computers | Sort-Object -Unique
        }
        catch {
            Write-Host "Bilgisayar listesi alinamadi: $_" -ForegroundColor Red
            return @()
        }
    }
}

function Get-PerformanceData {
    param([string]$computerName)
    
    try {
        # Oturum açmış kullanıcı bilgisini al
        $loggedInUser = (Get-WmiObject -ComputerName $computerName -Class Win32_ComputerSystem).UserName
        
        # Eğer kullanıcı adı domain içeriyorsa, sadece kullanıcı adını al
        if ($loggedInUser -match "\\") {
            $loggedInUser = $loggedInUser.Split("\")[1]
        }
        
        # CPU ve RAM bilgileri
        $CPU = (Get-WmiObject -ComputerName $computerName -Class Win32_Processor | 
               Measure-Object -Property LoadPercentage -Average).Average
        
        $OS = Get-WmiObject -ComputerName $computerName -Class Win32_OperatingSystem
        $RAMPercent = [math]::Round(($OS.TotalVisibleMemorySize - $OS.FreePhysicalMemory) / $OS.TotalVisibleMemorySize * 100, 2)
        
        # Sonuçları göster
        Write-Host ""
        Write-Host "=== ANLIK PERFORMANS BILGILERI ===" -ForegroundColor Green
        Write-Host "Kullanici: $loggedInUser"
        Write-Host "CPU Kullanimi: $CPU%"
        Write-Host "RAM Kullanimi: $RAMPercent%"
    }
    catch {
        Write-Host "Hata: $computerName bilgisayarına bağlanılamadı" -ForegroundColor Red
        Write-Host "Hata Detayı: $_" -ForegroundColor Yellow
    }
}

# Ana işlem akışı
$allComputers = Get-NetworkComputers

if ($allComputers.Count -eq 0) {
    Write-Host "Domain uzerinde bilgisayar bulunamadi." -ForegroundColor Red
    exit
}

# Bilgisayar listesini göster
Write-Host ""
Write-Host "Domain uzerinde kayitli bilgisayarlar" -ForegroundColor Cyan
Write-Host ""

for ($i = 0; $i -lt $allComputers.Count; $i++) {
    Write-Host "$($i+1)." -ForegroundColor Yellow -NoNewline
    Write-Host " $($allComputers[$i])" -ForegroundColor White
}

# Kullanıcı seçimi
Write-Host ""
$selection = Read-Host "Sira Numarasi veya Bilgisayar Adi"

if ($selection -match "^\d+$" -and [int]$selection -ge 1 -and [int]$selection -le $allComputers.Count) {
    $computerName = $allComputers[[int]$selection-1]
} else {
    $computerName = $selection
}

# Seçilen bilgisayarın performansını göster
Get-PerformanceData -computerName $computerName