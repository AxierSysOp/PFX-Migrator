# PFX-Migrator

![PowerShell](https://img.shields.io/badge/PowerShell-5391FE?style=for-the-badge&logo=powershell&logoColor=white)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)

Este repositorio contiene un conjunto de herramientas en PowerShell diseñadas para la extracción, respaldo y migración masiva de certificados digitales (formato PFX) en entornos Windows.

El objetivo de estos scripts es automatizar el proceso de backup del almacén personal del usuario (`CurrentUser\My`), procesando absolutamente todos los certificados instalados, filtrando el ruido visual de claves bloqueadas por el sistema (como certificados de software de terceros) y garantizando que las nuevas importaciones se marquen siempre como exportables.

## Contenido del Repositorio

### 1. Exportación Masiva (`export-pfx-certs.ps1`)
Recorre el almacén criptográfico del usuario e intenta exportar todos los certificados encontrados junto con su clave privada. 

* **Características principales:**
  * **Procesamiento absoluto:** Lee el 100% del almacén y genera un reporte en formato tabla indicando el estado exacto (ÉXITO/FALLO) de cada certificado.
  * **Prevención de colisiones:** Protege contra certificados con el atributo "Subject" vacío (sin nombre) asignándoles un nombre genérico y concatenando su huella digital (*Thumbprint*) para garantizar archivos únicos.
  * **Auditoría limpia:** Captura silenciosamente los errores nativos de Windows cuando una clave no es exportable (ej. certificados de Adobe o protegidos por diseño) y los traduce a un mensaje claro, manteniendo la consola legible.

* **Ejemplos de uso:**
  ```powershell
  # Uso básico (exporta a C:\cert con contraseña por defecto '1234')
  .\export-pfx-certs.ps1

  # Uso avanzado con rutas y contraseñas personalizadas
  .\export-pfx-certs.ps1 -RutaDestino "D:\Backups\Certs_User" -ClaveExportacion "PasswordSeguro2026!"