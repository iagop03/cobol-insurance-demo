# AntCrew COBOL Demo — script para grabar con OBS/asciinema
# Ejecutar desde: C:\Users\iagop\pyhton\cobol-insurance-demo
# Duracion estimada: ~2 minutos

$COBOL_DIR = "$PSScriptRoot\.."
$INDEX_DB  = "$PSScriptRoot\demo.db"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  AntCrew — COBOL Incident Demo" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Start-Sleep -Milliseconds 800

# --- Paso 1: mostrar el corpus ---
Write-Host "# El corpus: sistema de seguros real en COBOL/DB2" -ForegroundColor Yellow
Write-Host ""
Start-Sleep -Milliseconds 400
Write-Host "$ ls cobol-insurance-demo/" -ForegroundColor Green
Get-ChildItem $COBOL_DIR -Directory | ForEach-Object { Write-Host "  $($_.Name)/" }
Write-Host ""
Start-Sleep -Seconds 1

# --- Paso 2: indexar ---
Write-Host "# Paso 1 — Indexar el corpus (SQLite, una sola vez)" -ForegroundColor Yellow
Write-Host ""
Start-Sleep -Milliseconds 400
Write-Host "$ antcrew build-index --cobol-dir . --out demo/demo.db" -ForegroundColor Green
Write-Host ""
antcrew build-index --cobol-dir $COBOL_DIR --out $INDEX_DB
Write-Host ""
Start-Sleep -Seconds 1

# --- Paso 3: mostrar el requerimiento ---
Write-Host "# Paso 2 — El requerimiento: recargo por mora > 12 meses" -ForegroundColor Yellow
Write-Host ""
Start-Sleep -Milliseconds 400
Write-Host "$ cat REQUIREMENTS.md | head -20" -ForegroundColor Green
Get-Content "$COBOL_DIR\REQUIREMENTS.md" | Select-Object -First 20
Write-Host ""
Start-Sleep -Seconds 2

# --- Paso 4: analizar el incidente ---
Write-Host "# Paso 3 — AntCrew analiza el impacto sobre el corpus" -ForegroundColor Yellow
Write-Host ""
Start-Sleep -Milliseconds 400
Write-Host "$ antcrew cobol-incident `"$(Get-Content $COBOL_DIR\REQUIREMENTS.md -Raw | Select-String 'REQ-REHAB' | Select-Object -First 1)`" --cobol-dir . --index demo/demo.db" -ForegroundColor Green
Write-Host ""
$incident = Get-Content "$COBOL_DIR\REQUIREMENTS.md" -Raw
antcrew cobol-incident $incident --cobol-dir $COBOL_DIR --index $INDEX_DB
Write-Host ""
Start-Sleep -Seconds 2

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  antcrew.org — free tier disponible" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
