# AntCrew COBOL Demo — script para grabar con OBS/QuickTime
# Ejecutar desde: C:\Users\iagop\pyhton\cobol-insurance-demo
# Duracion estimada: ~2 minutos

$COBOL_DIR = (Resolve-Path "$PSScriptRoot\..").Path

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  AntCrew — COBOL Incident Demo" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Start-Sleep -Milliseconds 800

# --- Paso 1: mostrar el corpus ---
Write-Host "# El corpus: sistema de seguros en COBOL/DB2 (~35 programas)" -ForegroundColor Yellow
Write-Host ""
Start-Sleep -Milliseconds 400
Write-Host "PS> ls $COBOL_DIR" -ForegroundColor Green
Get-ChildItem $COBOL_DIR -Directory | ForEach-Object { Write-Host "  $($_.Name)/" }
Write-Host ""
Start-Sleep -Seconds 1

# --- Paso 2: mostrar el incidente ---
Write-Host "# El requerimiento: recargo por mora incorrecto en rehabilitaciones" -ForegroundColor Yellow
Write-Host ""
Start-Sleep -Milliseconds 400
Write-Host "PS> cat REQUIREMENTS.md | Select-Object -First 25" -ForegroundColor Green
Get-Content "$COBOL_DIR\REQUIREMENTS.md" | Select-Object -First 25
Write-Host ""
Start-Sleep -Seconds 2

# --- Paso 3: lanzar el analisis ---
Write-Host "# AntCrew analiza el corpus y localiza el origen del problema" -ForegroundColor Yellow
Write-Host ""
Start-Sleep -Milliseconds 400
Write-Host "PS> antcrew cobol-incident `"$(Get-Content $COBOL_DIR\REQUIREMENTS.md -Raw | Select-String 'recargo' | Select-Object -First 1)`" --cobol-dir . --auto-approve" -ForegroundColor Green
Write-Host ""

$incident = "Clientes con mas de 12 meses de impago estan siendo rehabilitados con recargo incorrecto — el sistema calcula el recargo sobre el resto de dividir los meses entre 12 en lugar de sobre el total de meses vencidos"
antcrew cobol-incident $incident --cobol-dir $COBOL_DIR --auto-approve

Write-Host ""
Start-Sleep -Seconds 1
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  antcrew.org — free tier disponible" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
