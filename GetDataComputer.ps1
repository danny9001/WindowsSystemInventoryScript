# ================================================================================
# 📋 Inventario y Mantenimiento de Equipos Windows
# Autor: Daniel Landivar
# Licencia: CC BY-NC (Reconocimiento – No Comercial)
# Descripción: Este script realiza un inventario técnico del equipo, detecta
# procesador, RAM, discos, red, sistema operativo y dominio.
# ================================================================================

# ===========================
# 📥 Entrada del usuario
# ===========================
$propietario = Read-Host "Ingrese el nombre del propietario del equipo"
if (-not $propietario) {
    Write-Host "❌ No se ingresó un nombre. Finalizando script." -ForegroundColor Red
    exit
}

# ===========================
# 📤 Función para extraer valores desde dsregcmd /status
# ===========================
function Get-DSRegValue {
    param (
        [string]$label,
        [string[]]$content
    )
    $match = $content | Where-Object { $_ -match "$label\s*:\s*(.+)" }
    return $match ? ($match -replace ".*:\s*", "").Trim() : "No encontrado"
}

# ===========================
# 🧾 Inicializar archivos
# ===========================
$hostname = $env:COMPUTERNAME
$outputFileTxt = "${hostname}_ResumenEquipo.txt"
$outputFileCsv = "${hostname}_ResumenEquipo.csv"
"" | Out-File $outputFileTxt

# ===========================
# 🔍 Identificación del sistema
# ===========================
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1 Name
$cpuName = $cpu.Name
$cpuGen = ""

if ($cpuName -match "Intel\(R\).*?i\d-(\d{4,5})") {
    $model = $matches[1]
    $cpuGen = if ($model.Length -eq 4) { $model.Substring(0,1) } else { $model.Substring(0,2) }
    $cpuGen = "Generación: $cpuGen"
}

# ===========================
# 🧠 Memoria RAM
# ===========================
$ramModules = Get-CimInstance Win32_PhysicalMemory
$ramTotalGB = [math]::Round(($ramModules | Measure-Object -Property Capacity -Sum).Sum / 1GB, 2)
$ramSlotsUsed = $ramModules.Count

# ===========================
# 🗃️ Discos físicos (si soportado)
# ===========================
try {
    $disks = @(Get-PhysicalDisk | Select-Object MediaType, Size)
} catch {
    $disks = @()
}

# ===========================
# 💽 Uso del disco C (sistema)
# ===========================
$driveC = Get-PSDrive -Name C
$usedSpaceGB = [math]::Round(($driveC.Used / 1GB), 2)
$freeSpaceGB = [math]::Round(($driveC.Free / 1GB), 2)
$totalSpaceGB = [math]::Round(($driveC.Used + $driveC.Free) / 1GB, 2)

# ===========================
# 🪟 Sistema operativo
# ===========================
$os = Get-CimInstance Win32_OperatingSystem
$osName = $os.Caption
$osArch = $env:PROCESSOR_ARCHITECTURE
$osVersion = $os.Version
$osBuild = $os.BuildNumber
$update = (Get-HotFix | Sort-Object -Property InstalledOn -Descending | Select-Object -First 1).HotFixID
$sysInfo = Get-CimInstance Win32_ComputerSystem
$modelo = $sysInfo.Model
$fabricante = $sysInfo.Manufacturer

# ===========================
# 🌐 Red: IP y MAC
# ===========================
try {
    $ipAddress = (Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object { $_.IPAddress -notlike "169.*" -and $_.IPAddress -ne "127.0.0.1" } |
        Select-Object -First 1 IPAddress).IPAddress
} catch {
    $ipAddress = "No detectada"
}

try {
    $macAddress = (Get-NetAdapter |
        Where-Object { $_.Status -eq "Up" -and $_.MacAddress } |
        Select-Object -First 1 MacAddress).MacAddress
} catch {
    $macAddress = "No detectada"
}

# ===========================
# 🔐 Dominio y Azure AD
# ===========================
$domain = (Get-CimInstance Win32_ComputerSystem).Domain
$domainStatus = switch ($domain) {
    { $_ -eq $hostname } { "No unido a dominio ni Azure AD" }
    { $_ -like "*.onmicrosoft.com" -or $_ -like "*.azuread" } { "Unido a Azure AD ($domain)" }
    default { "Unido a dominio ($domain)" }
}

# ===========================
# ☁️ Estado de Enrolamiento (dsregcmd)
# ===========================
try {
    $dsreg = dsregcmd /status
    $aadJoin = if ((Get-DSRegValue "AzureAdJoined" $dsreg) -eq "YES") { "Sí" } else { "No" }
    $domainJoin = if ((Get-DSRegValue "DomainJoined" $dsreg) -eq "YES") { "Sí" } else { "No" }
    $ssoState = if ((Get-DSRegValue "SSO State" $dsreg) -eq "YES") { "Sí" } else { "No" }
} catch {
    $aadJoin = "Desconocido"
    $domainJoin = "Desconocido"
    $ssoState = "Desconocido"
}

# ===========================
# 🖨️ Función para salida doble (pantalla + archivo)
# ===========================
function Write-Both {
    param (
        [string]$text,
        [ConsoleColor]$color = "White"
    )
    Write-Host $text -ForegroundColor $color
    $text | Out-File -FilePath $outputFileTxt -Append
}

# ===========================
# 📋 Impresión del resumen
# ===========================
Write-Both "`n🖥️  Resumen del sistema" Cyan
Write-Both "👤 Propietario: $propietario" Yellow
Write-Both "🔹 Hostname: $hostname" Yellow
Write-Both "🏢 Fabricante: $fabricante" Yellow
Write-Both "🔧 Modelo: $modelo" Yellow
Write-Both "🖥️  SO: $osName ($osArch)" Yellow
Write-Both "🔸 Versión: $osVersion - Build: $osBuild - Último KB: $update" Gray
Write-Both "🌐 IP: $ipAddress" Yellow
Write-Both "🌐 MAC: $macAddress" Yellow

Write-Both "`n🧠 Procesador" Cyan
Write-Both "🔹 CPU: $cpuName" Yellow
if ($cpuGen) { Write-Both "   🔸 $cpuGen" Gray }

Write-Both "`n💾 Memoria RAM" Cyan
Write-Both "🔹 Total: $ramTotalGB GB" Yellow
Write-Both "🔹 Slots usados: $ramSlotsUsed" Yellow
$slotIndex = 1
foreach ($module in $ramModules) {
    $slotSizeGB = [math]::Round($module.Capacity / 1GB, 2)
    Write-Both "   📌 Slot ${slotIndex}: ${slotSizeGB} GB" Green
    $slotIndex++
}

Write-Both "`n🗃️  Discos físicos" Cyan
foreach ($disk in $disks) {
    $sizeGB = [math]::Round($disk.Size / 1GB, 2)
    Write-Both "🔹 Tipo: $($disk.MediaType), Capacidad: $sizeGB GB" Yellow
}

Write-Both "`n💽 Disco C:" Cyan
Write-Both "🔹 Total: $totalSpaceGB GB" Yellow
Write-Both "🔹 Usado: $usedSpaceGB GB" Yellow
Write-Both "🔹 Libre: $freeSpaceGB GB" Yellow

Write-Both "`n🔐 Estado de dominio" Cyan
Write-Both "$domainStatus" Yellow

Write-Both "`n☁️ Enrolamiento (dsregcmd)" Cyan
Write-Both "🔹 Azure AD Join: $aadJoin" Yellow
Write-Both "🔹 Domain Join: $domainJoin" Yellow
Write-Both "🔹 SSO State: $ssoState" Yellow

Write-Both "`n📄 Resumen guardado en: $outputFileTxt" Cyan

# ===========================
# 📤 Exportar resumen a CSV
# ===========================
if (Test-Path $outputFileCsv) {
    Remove-Item $outputFileCsv -Force
}

$diskSummary = ($disks | ForEach-Object { "$($_.MediaType) $([math]::Round($_.Size / 1GB, 2)) GB" }) -join "; "

$csvLine = [PSCustomObject]@{
    Propietario      = $propietario
    Hostname         = $hostname
    Fabricante       = $fabricante
    Modelo           = $modelo
    SO               = $osName
    Version          = $osVersion
    Build            = $osBuild
    Update           = $update
    Arquitectura     = $osArch
    IP               = $ipAddress
    MAC              = $macAddress
    Procesador       = $cpuName
    Generación       = $cpuGen
    "RAM Total (GB)" = $ramTotalGB
    "Slots RAM"      = $ramSlotsUsed
    Discos           = $diskSummary
    "Disco C Total"  = "$totalSpaceGB GB"
    "Disco C Usado"  = "$usedSpaceGB GB"
    "Disco C Libre"  = "$freeSpaceGB GB"
    Dominio          = $domainStatus
    AzureAD          = $aadJoin
    DomainJoin       = $domainJoin
    SSO              = $ssoState
}

$csvLine | Export-Csv -Path $outputFileCsv -Encoding UTF8 -NoTypeInformation
