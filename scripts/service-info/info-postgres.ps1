# info-postgres.ps1 - Display PostgreSQL connection information
Write-Host "  [DB] PostgreSQL:" -ForegroundColor White
Write-Host "     Host: localhost" -ForegroundColor Gray
Write-Host "     Port: 5432" -ForegroundColor Gray
Write-Host "     User: postgres" -ForegroundColor Gray
Write-Host "     Password: postgres" -ForegroundColor Gray
Write-Host "     Connection: postgresql://postgres:postgres@localhost:5432/postgres" -ForegroundColor Gray
Write-Host "     Create DB: .\scripts\add-database.ps1 DBNAME USERNAME PASSWORD" -ForegroundColor Gray
Write-Host ""