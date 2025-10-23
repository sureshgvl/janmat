# PowerShell script to bulk update import paths after user feature reorganization
# Run this from the root project directory: ./fix_imports.ps1

Write-Host "🔧 Fixing import paths for user feature reorganization..." -ForegroundColor Green

# Fix user_model.dart imports
Write-Host "📝 Updating user_model.dart imports..." -ForegroundColor Yellow
Get-ChildItem -Recurse -Include "*.dart" -Exclude fix_imports.ps1 | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content -match "models/user_model") {
        $newContent = $content -replace "../../../../../models/user_model.dart", "../../../../../features/user/models/user_model.dart"
        $newContent = $newContent -replace "../../../../../../models/user_model.dart", "../../../../../../features/user/models/user_model.dart"
        $newContent = $newContent -replace "../../../../../models/user_model.dart", "../../../../../features/user/models/user_model.dart"
        $newContent = $newContent -replace "../../../../models/user_model.dart", "../../../../features/user/models/user_model.dart"
        $newContent = $newContent -replace "../../../models/user_model.dart", "../../../features/user/models/user_model.dart"
        $newContent = $newContent -replace "../../models/user_model.dart", "../../features/user/models/user_model.dart"
        $newContent = $newContent -replace "../models/user_model.dart", "../features/user/models/user_model.dart"

        Set-Content $_.FullName $newContent -NoNewline
        Write-Host "  ✓ Updated: $($_.Name)" -ForegroundColor Green
    }
}

# Fix user_controller.dart imports
Write-Host "📝 Updating user_controller.dart imports..." -ForegroundColor Yellow
Get-ChildItem -Recurse -Include "*.dart" -Exclude fix_imports.ps1 | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content -match "controllers/user_controller") {
        $newContent = $content -replace "../../../../../controllers/user_controller.dart", "../../../../../features/user/controllers/user_controller.dart"
        $newContent = $newContent -replace "../../../../../../controllers/user_controller.dart", "../../../../../../features/user/controllers/user_controller.dart"
        $newContent = $newContent -replace "../../../../../controllers/user_controller.dart", "../../../../../features/user/controllers/user_controller.dart"
        $newContent = $newContent -replace "../../../../controllers/user_controller.dart", "../../../../features/user/controllers/user_controller.dart"
        $newContent = $newContent -replace "../../../controllers/user_controller.dart", "../../../features/user/controllers/user_controller.dart"
        $newContent = $newContent -replace "../../controllers/user_controller.dart", "../../features/user/controllers/user_controller.dart"
        $newContent = $newContent -replace "../controllers/user_controller.dart", "../features/user/controllers/user_controller.dart"

        Set-Content $_.FullName $newContent -NoNewline
        Write-Host "  ✓ Updated: $($_.Name)" -ForegroundColor Green
    }
}

# Fix user_data_controller.dart imports if they exist
Write-Host "📝 Updating user_data_controller.dart imports..." -ForegroundColor Yellow
Get-ChildItem -Recurse -Include "*.dart" -Exclude fix_imports.ps1 | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content -match "controllers/user_data_controller") {
        $newContent = $content -replace "../../../../../controllers/user_data_controller.dart", "../../../../../features/user/controllers/user_data_controller.dart"
        $newContent = $newContent -replace "../../../../../../controllers/user_data_controller.dart", "../../../../../../features/user/controllers/user_data_controller.dart"
        $newContent = $newContent -replace "../../../../../controllers/user_data_controller.dart", "../../../../../features/user/controllers/user_data_controller.dart"
        $newContent = $newContent -replace "../../../../controllers/user_data_controller.dart", "../../../../features/user/controllers/user_data_controller.dart"
        $newContent = $newContent -replace "../../../controllers/user_data_controller.dart", "../../../features/user/controllers/user_data_controller.dart"
        $newContent = $newContent -replace "../../controllers/user_data_controller.dart", "../../features/user/controllers/user_data_controller.dart"

        Set-Content $_.FullName $newContent -NoNewline
        Write-Host "  ✓ Updated: $($_.Name)" -ForegroundColor Green
    }
}

# Fix user_cache_service.dart imports
Write-Host "📝 Updating user_cache_service.dart imports..." -ForegroundColor Yellow
Get-ChildItem -Recurse -Include "*.dart" -Exclude fix_imports.ps1 | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content -match "services/user_cache_service") {
        $newContent = $content -replace "../../../../../services/user_cache_service.dart", "../../../../../features/user/services/user_cache_service.dart"
        $newContent = $newContent -replace "../../../../../../services/user_cache_service.dart", "../../../../../../features/user/services/user_cache_service.dart"
        $newContent = $newContent -replace "../../../../../services/user_cache_service.dart", "../../../../../features/user/services/user_cache_service.dart"
        $newContent = $newContent -replace "../../../../services/user_cache_service.dart", "../../../../features/user/services/user_cache_service.dart"
        $newContent = $newContent -replace "../../../services/user_cache_service.dart", "../../../features/user/services/user_cache_service.dart"
        $newContent = $newContent -replace "../../services/user_cache_service.dart", "../../features/user/services/user_cache_service.dart"

        Set-Content $_.FullName $newContent -NoNewline
        Write-Host "  ✓ Updated: $($_.Name)" -ForegroundColor Green
    }
}

# Fix user_data_service.dart imports if they exist
Write-Host "📝 Updating user_data_service.dart imports..." -ForegroundColor Yellow
Get-ChildItem -Recurse -Include "*.dart" -Exclude fix_imports.ps1 | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content -match "services/user_data_service") {
        $newContent = $content -replace "../../../../../services/user_data_service.dart", "../../../../../features/user/services/user_data_service.dart"
        $newContent = $newContent -replace "../../../../../../services/user_data_service.dart", "../../../../../../features/user/services/user_data_service.dart"
        $newContent = $newContent -replace "../../../../../services/user_data_service.dart", "../../../../../features/user/services/user_data_service.dart"
        $newContent = $newContent -replace "../../../../services/user_data_service.dart", "../../../../features/user/services/user_data_service.dart"
        $newContent = $newContent -replace "../../../services/user_data_service.dart", "../../../features/user/services/user_data_service.dart"
        $newContent = $newContent -replace "../../services/user_data_service.dart", "../../features/user/services/user_data_service.dart"
        $newContent = $newContent -replace "../services/user_data_service.dart", "../features/user/services/user_data_service.dart"

        Set-Content $_.FullName $newContent -NoNewline
        Write-Host "  ✓ Updated: $($_.Name)" -ForegroundColor Green
    }
}

# Fix app_logger.dart imports for user services
Write-Host "📝 Updating app_logger.dart imports..." -ForegroundColor Yellow
Get-ChildItem -Recurse -Include "*.dart" -Exclude fix_imports.ps1 | ForEach-Object {
    if ($_.FullName -match "features\\user\\services\\") {
        $content = Get-Content $_.FullName -Raw
        if ($content -match "\.\./utils/app_logger") {
            $newContent = $content -replace "\.\./utils/app_logger", "../../../utils/app_logger"
            Set-Content $_.FullName $newContent -NoNewline
            Write-Host "  ✓ Updated logger import in: $($_.Name)" -ForegroundColor Green
        }
    }
}

Write-Host "`n✅ Import path updates completed!" -ForegroundColor Green
Write-Host "🎯 Now run: flutter build apk --debug" -ForegroundColor Cyan
Write-Host "🎯 Then run: flutter run --debug" -ForegroundColor Cyan</content>
