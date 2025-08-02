# Active Directory ve WMI kullanarak domain bilgisayar bilgilerini listeleyen PowerShell scripti
# Bu script, domain bilgisayarlarını alır ve seçilen bilgisayarın temel bilgilerini gösterir.
# Bilgisayar adını veya sıra numarasını girerek bilgi alabilirsiniz.
# Scripti çalıştırmak için AD yetkili kullanıcı hesabıyla oturum açmanız gerekmektedir.

# PowerShell script that lists domain computer information using Active Directory and WMI
# This script retrieves domain computers and displays basic information about the selected computer.
# You can get information by entering the computer name or serial number.
# To run the script, you need to be logged in with an AD authorized user account.

# Oktay ALA

cls

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

$allComputers = Get-NetworkComputers

if ($allComputers.Count -eq 0) {
    Write-Host "Domain uzerinde bilgisayar bulunamadi." -ForegroundColor Red
    exit
}

Write-Host ""
Write-Host "Domain uzerinde kayitli bilgisayarlar" -ForegroundColor Cyan
Write-Host ""

for ($i = 0; $i -lt $allComputers.Count; $i++) {
    Write-Host "$($i+1)." -ForegroundColor Yellow -NoNewline
    Write-Host " $($allComputers[$i])" -ForegroundColor White
}

Write-Host ""
$selection = Read-Host "Sira Numarasi veya Bilgisayar Adi"

if ($selection -match "^\d+$" -and [int]$selection -ge 1 -and [int]$selection -le $allComputers.Count) {
    $computerName = $allComputers[[int]$selection-1]
} else {
    $computerName = $selection
}

function Get-ComputerInfo {
    param (
        [string]$computerName
    )

    try {
        if (-not (Test-Connection -ComputerName $computerName -Count 1 -Quiet)) {
            throw "Bilgisayara ping atilamadi."
        }

        $system = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $computerName -ErrorAction Stop
        $os = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $computerName
        $processor = Get-WmiObject -Class Win32_Processor -ComputerName $computerName | Select-Object -First 1
        $disks = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3" -ComputerName $computerName
        $totalDiskSize = [math]::Round(($disks | Measure-Object -Property Size -Sum).Sum / 1GB, 2)
        $bios = Get-WmiObject -Class Win32_BIOS -ComputerName $computerName
        $baseboard = Get-WmiObject -Class Win32_BaseBoard -ComputerName $computerName
        $memory = Get-WmiObject -Class Win32_PhysicalMemory -ComputerName $computerName
        $memorySize = [math]::Round(($memory | Measure-Object -Property Capacity -Sum).Sum / 1GB, 2)
        $networkConfigs = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -ComputerName $computerName -Filter "IPEnabled=True"
        $printers = Get-WmiObject -Class Win32_Printer -ComputerName $computerName -ErrorAction SilentlyContinue
        $manufacturer = $system.Manufacturer.Trim()
        $model = $system.Model.Trim()
        $serialNumber = $bios.SerialNumber.Trim()
        $loggedInUser = $system.UserName.Trim()

        if ($model -match "^Default string|^System Product Name") { $model = "Bilinmiyor" }
        if ($serialNumber -match "^$|^None|^Default string|^System Serial Number") { $serialNumber = "Bilinmiyor" }

        Write-Host ""
        Write-Host "======================== TEMEL BILGILER ========================" -ForegroundColor Cyan
        Write-Host "Kullanici           : $loggedInUser"
        Write-Host "PC Adi              : $computerName"
        Write-Host "Marka               : $manufacturer"
        Write-Host "Model               : $model"
        Write-Host "SN                  : $serialNumber"
        Write-Host "OS                  : $($os.Caption)"
        Write-Host "CPU                 : $($processor.Name)"
        Write-Host "RAM                 : $memorySize GB"
        Write-Host "Disk                : $totalDiskSize GB"
        Write-Host ""

        Write-Host "========================== NETWORK =============================" -ForegroundColor Cyan
        if ($networkConfigs) {
            foreach ($net in $networkConfigs) {
                $ipv4Addresses = $net.IPAddress | Where-Object { $_ -match '^\d+\.\d+\.\d+\.\d+$' }

                if ($ipv4Addresses) {
                    Write-Host "IP                  : $($ipv4Addresses -join ', ')"
                } else {
                    Write-Host "IP                  : Bilinmiyor"
                }

                Write-Host "MAC                 : $($net.MACAddress)"
                Write-Host ""
            }
        } else {
            Write-Host "Network bilgileri alinamadi." -ForegroundColor Red
        }

        if ($printers) {
            Write-Host "========================== YAZICILAR ===========================" -ForegroundColor Cyan
            $realPrinters = $printers | Where-Object {
                $_.Name -notlike "*OneNote*" -and
                $_.Name -notlike "*Microsoft*" -and
                $_.Name -notlike "*Fax*" -and
                $_.Name -notlike "*PDF24*" -and
                $_.Name -notlike "*Adobe*" -and
                $_.Name -notlike "*AnyDesk*"
            }

            if ($realPrinters) {
                foreach ($printer in $realPrinters) {
                    Write-Host "Yazici Adi          : $($printer.Name)"
                    $ipAddress = $printer.PortName -replace "IP_", "" -replace "_.*", ""
                    Write-Host "Yazici IP           : $ipAddress"
                    Write-Host ""
                }
            } else {
                Write-Host "Bilgisayarda yazici bulunamadi."
            }
        }
        else {
            Write-Host "Bilgisayarda yazici bulunamadi."
        }
    }
    catch {
        Write-Host ""
        Write-Host "HATA: $computerName bilgisayarina baglanilamadi veya bilgiler alinamadi." -ForegroundColor Red
        Write-Host "$_" -ForegroundColor Yellow
        Write-Host ""
    }
}

Get-ComputerInfo -computerName $computerName