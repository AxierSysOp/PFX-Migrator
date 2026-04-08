<#
.SYNOPSIS
    Importa masivamente certificados PFX al almacen del usuario actual.

.DESCRIPTION
    Busca archivos .pfx en un directorio local y los importa al almacen 
    Personal (CurrentUser\My). Fuerzan la marca "-Exportable" para asegurar
    que la clave privada se pueda volver a extraer en el futuro.

.NOTES
    Autor: Axier Baez (@AxierSysOp)
#>
param (
    [Parameter(Mandatory=$false)]
    [string]$RutaOrigen = "C:\cert",

    [Parameter(Mandatory=$false)]
    [string]$ClaveImportacion = "1234"
)

# =====================================================================================
# BLOQUE 1: INTERFAZ Y PREPARACION DEL ENTORNO
# =====================================================================================
Clear-Host
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "   IMPORTACION MASIVA DE CERTIFICADOS (PFX)              " -ForegroundColor White
Write-Host "   Desarrollado por: Axier Baez (@AxierSysOp)           " -ForegroundColor Gray
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "1. Preparando entorno y credenciales..." -NoNewline -ForegroundColor Cyan
try {
    $SecurePass = ConvertTo-SecureString -String $ClaveImportacion -Force -AsPlainText
    
    if (-not (Test-Path $RutaOrigen)) {
        Write-Host " [Error] La ruta de origen ($RutaOrigen) no existe." -ForegroundColor Red
        return
    }
    Write-Host " [OK] (Origen: $RutaOrigen)" -ForegroundColor Green
} catch {
    Write-Host " [Error Critico] $($_.Exception.Message)" -ForegroundColor Red
    return
}
Write-Host ""

# =====================================================================================
# BLOQUE 2: LECTURA DEL DIRECTORIO ORIGEN
# =====================================================================================
Write-Host "2. Buscando archivos PFX locales..." -NoNewline -ForegroundColor Cyan
try {
    $Archivos = Get-ChildItem -Path $RutaOrigen -Filter *.pfx -ErrorAction Stop
    
    if (-not $Archivos) {
        Write-Host " [Aviso] No se encontraron archivos .pfx en la ruta especificada." -ForegroundColor Yellow
        return
    }
    Write-Host " [OK] ($($Archivos.Count) encontrados en total)" -ForegroundColor Green
} catch {
    Write-Host " [Error] No se pudo leer el directorio de origen." -ForegroundColor Red
    return
}
Write-Host ""

# =====================================================================================
# BLOQUE 3: BUCLE PRINCIPAL DE IMPORTACION
# =====================================================================================
Write-Host "3. Iniciando proceso de importacion (Modo: Exportable)..." -ForegroundColor Cyan
$ReporteFinal = @()

foreach ($Archivo in $Archivos) {
    
    $Estado = ""
    $Detalle = ""

    try {
        # El parametro -Exportable es la directiva critica para futuras extracciones
        Import-PfxCertificate -FilePath $Archivo.FullName -CertStoreLocation Cert:\CurrentUser\My -Password $SecurePass -Exportable -ErrorAction Stop | Out-Null
        
        $Estado = "EXITO"
        $Detalle = "Importado con clave privada marcada como exportable."
    } catch {
        $Estado = "FALLO"
        if ($_.Exception.Message -match "contraseña") {
            $Detalle = "La contraseña del archivo PFX no es correcta."
        } else {
            $Detalle = $_.Exception.Message
        }
    }

    $ReporteFinal += [PSCustomObject]@{
        Archivo = $Archivo.Name
        Estado  = $Estado
        Detalle = $Detalle
    }
}

# =====================================================================================
# BLOQUE 4: PRESENTACION DE DATOS EN PANTALLA
# =====================================================================================
Write-Host ""
Write-Host "4. Resultado de la operacion:" -ForegroundColor Cyan
Write-Host "--------------------------------------------------------------------------------" -ForegroundColor White

if ($ReporteFinal.Count -gt 0) {
    # Utilizamos -Wrap para asegurar la lectura completa de errores si la clave falla
    $ReporteFinal | Format-Table Archivo, Estado, Detalle -Wrap
}

Write-Host "--------------------------------------------------------------------------------" -ForegroundColor White
Write-Host ""