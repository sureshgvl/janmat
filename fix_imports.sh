#!/bin/bash

# Bash script to bulk update import paths after user feature reorganization
# Run this from the root project directory: ./fix_imports.sh

echo "🔧 Fixing import paths for user feature reorganization..."

# Find all Dart files and update imports
find . -name "*.dart" -type f -not -name "fix_imports.sh" | while read -r file; do
    echo "📝 Processing: $file"

    # Update user_model.dart imports
    sed -i 's|../../../../models/user_model.dart|../../../../features/user/models/user_model.dart|g' "$file"
    sed -i 's|../../../models/user_model.dart|../../../features/user/models/user_model.dart|g' "$file"
    sed -i 's|../../models/user_model.dart|../../features/user/models/user_model.dart|g' "$file"

    # Update user_controller.dart imports
    sed -i 's|../../../../controllers/user_controller.dart|../../../../features/user/controllers/user_controller.dart|g' "$file"
    sed -i 's|../../../controllers/user_controller.dart|../../../features/user/controllers/user_controller.dart|g' "$file"
    sed -i 's|../../controllers/user_controller.dart|../../features/user/controllers/user_controller.dart|g' "$file"

    # Update user_data_controller.dart imports
    sed -i 's|../../../../controllers/user_data_controller.dart|../../../../features/user/controllers/user_data_controller.dart|g' "$file"
    sed -i 's|../../../controllers/user_data_controller.dart|../../../features/user/controllers/user_data_controller.dart|g' "$file"

    # Update user_cache_service.dart imports
    sed -i 's|../../../../services/user_cache_service.dart|../../../../features/user/services/user_cache_service.dart|g' "$file"
    sed -i 's|../../../services/user_cache_service.dart|../../../features/user/services/user_cache_service.dart|g' "$file"

    # Update user_data_service.dart imports
    sed -i 's|../../../../services/user_data_service.dart|../../../../features/user/services/user_data_service.dart|g' "$file"
    sed -i 's|../../../services/user_data_service.dart|../../../features/user/services/user_data_service.dart|g' "$file"
    sed -i 's|../../services/user_data_service.dart|../../features/user/services/user_data_service.dart|g' "$file"

done

# Fix app_logger imports in user services
echo "📝 Fixing app_logger imports in user services..."
find ./lib/features/user/services -name "*.dart" -type f | while read -r file; do
    sed -i 's|../utils/app_logger|../../../utils/app_logger|g' "$file"
done

echo "✅ Import path updates completed!"
echo "🎯 Now run: flutter build apk --debug"
echo "🎯 Then run: flutter run --debug"
