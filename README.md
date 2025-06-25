# 🖥️ Windows System Inventory Script

**Author**: Daniel Landivar  
**License**: [CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/) (Attribution-NonCommercial)  
**Language**: PowerShell  
**Compatibility**: Windows 10 / 11  

---

## 🌐 EN

### 📋 Description

This PowerShell script performs a **full hardware and system inventory** of a Windows machine and saves the results in both `.txt` and `.csv` formats. It includes:

- CPU name and generation (Intel)
- Total RAM and per-slot distribution
- Disk information and used/available space on `C:`
- Network details (IP and MAC)
- OS version, build, edition, and latest KB update
- Domain and Azure AD join status

### 📦 Output

- `COMPUTERNAME_ResumenEquipo.txt`  
- `COMPUTERNAME_ResumenEquipo.csv`

### ▶️ How to Run

1. Open **PowerShell as Administrator**
2. Run:
   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process
   .\GetDataComputer.ps1


# 🖥️ Script de Inventario del Sistema Windows

**Autor**: Daniel Landivar  
**Licencia**: [CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/) (Reconocimiento – No Comercial)  
**Lenguaje**: PowerShell  
**Compatibilidad**: Windows 10 / 11  

---

## 🌐 ES

## 📋 Descripción

Este script en PowerShell realiza un **inventario completo del sistema y hardware** de una computadora con Windows, guardando los resultados en archivos `.txt` y `.csv`. El inventario incluye:

- Nombre y generación del procesador (Intel)  
- RAM total y distribución por slot  
- Información de discos y espacio usado/libre en la unidad `C:`  
- Dirección IP y MAC  
- Versión de Windows, compilación, edición y último parche instalado  
- Estado de unión a dominio o Azure AD  

## 📦 Archivos generados

- `COMPUTERNAME_ResumenEquipo.txt`  
- `COMPUTERNAME_ResumenEquipo.csv`  

## ▶️ Cómo ejecutar

1. Abrir **PowerShell como Administrador**  
2. Ejecutar el siguiente comando para permitir la ejecución temporal del script:  
   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process
   .\GetDataComputer.ps1
