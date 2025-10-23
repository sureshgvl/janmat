@echo off
echo 🔧 Final Import Path Fix for User Feature Reorganization
echo.

echo 📝 Fixing user_model.dart imports...
for /r %%f in (*.dart) do (
    powershell -Command "(Get-Content '%%f') -replace '../../../models/user_model.dart', '../../../features/user/models/user_model.dart' | Set-Content '%%f'"
    powershell -Command "(Get-Content '%%f') -replace '../../../../models/user_model.dart', '../../../../features/user/models/user_model.dart' | Set-Content '%%f'"
    powershell -Command "(Get-Content '%%f') -replace '../../models/user_model.dart', '../../features/user/models/user_model.dart' | Set-Content '%%f'"
)

echo 📝 Fixing user_controller.dart imports...
for /r %%f in (*.dart) do (
    powershell -Command "(Get-Content '%%f') -replace '../../../controllers/user_controller.dart', '../../../features/user/controllers/user_controller.dart' | Set-Content '%%f'"
    powershell -Command "(Get-Content '%%f') -replace '../../../../controllers/user_controller.dart', '../../../../features/user/controllers/user_controller.dart' | Set-Content '%%f'"
)

echo 📝 Fixing user_cache_service.dart imports...
for /r %%f in (*.dart) do (
    powershell -Command "(Get-Content '%%f') -replace '../../../services/user_cache_service.dart', '../../../features/user/services/user_cache_service.dart' | Set-Content '%%f'"
    powershell -Command "(Get-Content '%%f') -replace '../../../../services/user_cache_service.dart', '../../../../features/user/services/user_cache_service.dart' | Set-Content '%%f'"
)

echo 📝 Fixing user_data_service.dart imports...
for /r %%f in (*.dart) do (
    powershell -Command "(Get-Content '%%f') -replace '../../../services/user_data_service.dart', '../../../features/user/services/user_data_service.dart' | Set-Content '%%f'"
    powershell -Command "(Get-Content '%%f') -replace '../../../../services/user_data_service.dart', '../../../../features/user/services/user_data_service.dart' | Set-Content '%%f'"
    powershell -Command "(Get-Content '%%f') -replace '../../services/user_data_service.dart', '../../features/user/services/user_data_service.dart' | Set-Content '%%f'"
)

echo 📝 Fixing user_data_controller.dart imports...
for /r %%f in (*.dart) do (
    powershell -Command "(Get-Content '%%f') -replace '../../../controllers/user_data_controller.dart', '../../../features/user/controllers/user_data_controller.dart' | Set-Content '%%f'"
    powershell -Command "(Get-Content '%%f') -replace '../../../../controllers/user_data_controller.dart', '../../../../features/user/controllers/user_data_controller.dart' | Set-Content '%%f'"
)

echo 📝 Fixing app_logger.dart imports in user services...
powershell -Command "Get-ChildItem -Recurse -Path 'lib/features/user/services' -Include '*.dart' | ForEach-Object { (Get-Content $_.FullName) -replace \"../utils/app_logger.dart\", \"../../../utils/app_logger.dart\" | Set-Content $_.FullName }"

echo.
echo ✅ Import path fixes completed!
echo 🎯 Now run: flutter clean && flutter pub get && flutter build apk --debug
echo.
