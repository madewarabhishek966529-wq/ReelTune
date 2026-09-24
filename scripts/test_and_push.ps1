param (
    [string]$Message = "feat: updates verified by automated test loop"
)

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "🎬 ReelTune Automated Test & Git Push Automation" -ForegroundColor Cyan
Write-Host "===================================================="

Write-Host "`n[1/3] Running dart analyze..." -ForegroundColor Yellow
dart analyze
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Static analysis failed. Aborting commit and push." -ForegroundColor Red
    exit 1
}
Write-Host "✅ Static analysis passed." -ForegroundColor Green

Write-Host "`n[2/3] Running flutter test..." -ForegroundColor Yellow
flutter test
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Test suite failed. Aborting commit and push." -ForegroundColor Red
    exit 1
}
Write-Host "✅ All test suites passed." -ForegroundColor Green

Write-Host "`n[3/3] Staging, committing, and pushing to GitHub..." -ForegroundColor Yellow
git add -A
git commit -m "$Message"
git push origin main
if ($LASTEXITCODE -eq 0) {
    Write-Host "`n🎉 Successfully committed and pushed to GitHub main branch!" -ForegroundColor Green
} else {
    Write-Host "`n⚠️ Git push encountered an issue. Check network/credentials." -ForegroundColor Yellow
}
