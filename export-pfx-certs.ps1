<#
.SYNOPSIS
    Exporta masivamente los certificados del usuario actual en formato PFX.

.DESCRIPTION
    Recopila todos los certificados del almacen Personal del usuario (CurrentUser\My) 
    y los exporta a un directorio local con su clave privada, protegidos por una contraseña.

.NOTES
    Autor: Axier Baez (@AxierSysOp)
#>
param (
    [Parameter(Mandatory=$false)]
    [string]$RutaDestino = "C:\cert",

    [Parameter(Mandatory=$false)]
    [string]$ClaveExportacion = "1234"
)

# =====================================================================================
# BLOQUE 1: INTERFAZ Y PREPARACION DEL ENTORNO
# =====================================================================================
Clear-Host
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "   EXPORTACION MASIVA DE CERTIFICADOS (PFX)              " -ForegroundColor White
Write-Host "   Desarrollado por: Axier Baez (@AxierSysOp)           " -ForegroundColor Gray
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "1. Preparando entorno y credenciales..." -NoNewline -ForegroundColor Cyan
try {
    # Convertimos la clave en texto plano a un objeto seguro requerido por Windows
    $SecurePass = ConvertTo-SecureString -String $ClaveExportacion -Force -AsPlainText
    
    # Comprobamos si la carpeta existe. Si no, la creamos silenciosamente.
    if (-not (Test-Path $RutaDestino)) {
        New-Item -ItemType Directory -Path $RutaDestino | Out-Null
    }
    Write-Host " [OK] (Destino: $RutaDestino)" -ForegroundColor Green
} catch {
    Write-Host " [Error Critico] $($_.Exception.Message)" -ForegroundColor Red
    return
}
Write-Host ""

# =====================================================================================
# BLOQUE 2: LECTURA DEL ALMACEN DE CERTIFICADOS
# =====================================================================================
Write-Host "2. Obteniendo certificados del almacen personal..." -NoNewline -ForegroundColor Cyan
try {
    $Certificados = Get-ChildItem Cert:\CurrentUser\My -ErrorAction Stop
    
    if (-not $Certificados) {
        Write-Host " [Aviso] No se encontraron certificados en CurrentUser\My." -ForegroundColor Yellow
        return
    }
    Write-Host " [OK] ($($Certificados.Count) encontrados)" -ForegroundColor Green
} catch {
    Write-Host " [Error] No se pudo acceder al almacen de certificados." -ForegroundColor Red
    return
}
Write-Host ""

# =====================================================================================
# BLOQUE 3: BUCLE PRINCIPAL DE EXTRACCION
# =====================================================================================
Write-Host "3. Iniciando proceso de extraccion..." -ForegroundColor Cyan
$ReporteFinal = @()

foreach ($Cert in $Certificados) {
    
    # 1. EL CAMBIO DEL NOMBRE: Extraemos y ponemos el salvavidas por si está en blanco
    $NombreLimpio = ($Cert.Subject -replace 'CN=', '' -replace '[^a-zA-Z0-9]', '_').Split(',')[0]
    if ([string]::IsNullOrWhiteSpace($NombreLimpio)) { $NombreLimpio = "Certificado_Sin_Nombre" }
    if ($NombreLimpio.Length -gt 50) { $NombreLimpio = $NombreLimpio.Substring(0,50) }
    
    $ArchivoDestino = Join-Path $RutaDestino "$NombreLimpio`_$($Cert.Thumbprint).pfx"
    
    $Estado = ""
    $Detalle = ""

    try {
        Export-PfxCertificate -Cert $Cert -FilePath $ArchivoDestino -Password $SecurePass -ErrorAction Stop | Out-Null
        $Estado = "EXITO"
        $Detalle = "Exportado correctamente."
    } catch {
        # 2. EL CAMBIO DEL ERROR: Traducimos el fallo nativo para que la tabla quede limpia
        $Estado = "FALLO"
        if ($_.Exception.Message -match "no exportable") {
            $Detalle = "Clave privada bloqueada por el sistema."
        } else {
            $Detalle = $_.Exception.Message
        }
    }

    $ReporteFinal += [PSCustomObject]@{
        Certificado = $NombreLimpio
        Estado      = $Estado
        Detalle     = $Detalle
    }
}

# =====================================================================================
# BLOQUE 4: PRESENTACION DE DATOS EN PANTALLA
# =====================================================================================
Write-Host ""
Write-Host "4. Resultado de la operacion:" -ForegroundColor Cyan
Write-Host "--------------------------------------------------------------------------------" -ForegroundColor White

if ($ReporteFinal.Count -gt 0) {
    # Formateamos la salida. El wrap nos asegura leer el error completo si lo hay.
    $ReporteFinal | Format-Table Certificado, Estado, Detalle -Wrap
}

Write-Host "--------------------------------------------------------------------------------" -ForegroundColor White