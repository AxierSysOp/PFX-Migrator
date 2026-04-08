# PFX-Migrator

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

Este repositorio contiene un conjunto de herramientas en PowerShell diseñadas para la extracción, respaldo y migración masiva de certificados digitales (formato PFX) en entornos Windows.

El objetivo de estos scripts es automatizar tanto el backup como la restauración del almacén personal del usuario (`CurrentUser\My`). Por un lado, extrae todos los certificados válidos ignorando el ruido de las claves bloqueadas por el sistema; por otro lado, inyecta los respaldos garantizando de forma nativa que mantengan la marca de "exportable" para el futuro.

## Contenido del Repositorio

### 1. Exportación Masiva (`export-pfx-certs.ps1`)
Recorre el almacén criptográfico del equipo origen e intenta exportar todos los certificados encontrados junto con su clave privada. 

* **Características principales:**
  * **Procesamiento absoluto:** Lee el 100% del almacén y genera un reporte en formato tabla indicando el estado exacto (ÉXITO/FALLO) de cada certificado.
  * **Prevención de colisiones:** Protege contra certificados con el atributo "Subject" vacío (sin nombre) asignándoles un nombre genérico y concatenando su huella digital (*Thumbprint*) para garantizar archivos únicos.
  * **Auditoría limpia:** Captura silenciosamente los errores nativos de Windows cuando una clave no es exportable (ej. certificados de software de terceros protegidos por diseño) y los traduce a un mensaje claro, manteniendo la consola legible.

* **Ejemplos de uso:**
  ```powershell
  # Uso básico (exporta a C:\cert con contraseña por defecto '1234')
  .\export-pfx-certs.ps1

  # Uso avanzado con rutas y contraseñas personalizadas
  .\export-pfx-certs.ps1 -RutaDestino "D:\Backups\Certs_User" -ClaveExportacion "PasswordSeguro2026!"
  ```

### 2. Importación Masiva (`import-pfx-certs.ps1`)
Lee un directorio local en busca de archivos `.pfx` y los inyecta en el almacén personal del equipo destino.

* **Características principales:**
  * **Directiva de Resiliencia:** Utiliza el modificador nativo `-Exportable` durante la inyección. Esto garantiza que la clave privada no quede secuestrada por el sistema operativo destino y pueda volver a exportarse en el futuro sin necesidad de herramientas externas.
  * **Control de errores:** Validación previa de la existencia del directorio origen y captura limpia de errores por contraseñas incorrectas.

* **Ejemplos de uso:**
  ```powershell
  # Uso básico (importa desde C:\cert con contraseña por defecto '1234')
  .\import-pfx-certs.ps1

  # Uso avanzado con rutas y contraseñas personalizadas
  .\import-pfx-certs.ps1 -RutaOrigen "D:\Backups\Certs_User" -ClaveImportacion "PasswordSeguro2026!"
  ```

## Requisitos Previos y Notas
* **Permisos:** La cuenta que ejecuta los scripts debe ser la propietaria del almacén de certificados local (`CurrentUser`).
* **Execution Policy:** Es necesario que PowerShell permita la ejecución de scripts locales. Si recibe un error de ejecución, aplique esta política en su terminal:
  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
  ```

## Autor
* **Axier Baez** - (https://github.com/AxierSysOp)

## Licencia
Este proyecto está bajo la Licencia MIT - mira el archivo [LICENSE](LICENSE) para detalles.