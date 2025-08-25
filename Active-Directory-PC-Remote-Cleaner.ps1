$computers = @(
    "pcadi"
)

$credential = Get-Credential

foreach ($computer in $computers) {
    try {        
        if (Test-Connection -ComputerName $computer -Count 1 -Quiet) {
            $scriptBlock = {
                Get-ChildItem -Path "$env:USERPROFILE\AppData\Local\Temp\*" -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                
                Get-ChildItem -Path "$env:WINDIR\Temp\*" -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                
                Get-ChildItem -Path "$env:USERPROFILE\Recent\*" -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                
                if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
                    Get-ChildItem -Path "$env:WINDIR\Prefetch\*" -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                } else {
                    Write-Host "Prefetch temizleme için yönetici hakları gerekli" -ForegroundColor Yellow
                }
                
                Start-Sleep -Seconds 3
            }
            
            Invoke-Command -ComputerName $computer -Credential $credential -ScriptBlock $scriptBlock -ErrorAction Stop
            
            Write-Host "$computer temizleme işlemi tamamlandı" -ForegroundColor Green
        } else {
            Write-Host "$computer erişilemiyor - atlanıyor" -ForegroundColor Red
        }
        
    } catch {
        Write-Host "$computer için hata oluştu: $($_.Exception.Message)" -ForegroundColor Red
    }
}