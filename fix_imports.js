// Node.js script to bulk update import paths after user feature reorganization
const fs = require('fs');
const path = require('path');

console.log('🔧 Fixing import paths for user feature reorganization...');

// Find all Dart files recursively
function findDartFiles(dir, files = []) {
  const items = fs.readdirSync(dir);
  for (const item of items) {
    const fullPath = path.join(dir, item);
    const stat = fs.statSync(fullPath);
    if (stat.isDirectory()) {
      findDartFiles(fullPath, files);
    } else if (item.endsWith('.dart')) {
      files.push(fullPath);
    }
  }
  return files;
}

// Update imports in a file
function updateImports(filePath) {
  console.log(`📝 Processing: ${filePath}`);
  let content = fs.readFileSync(filePath, 'utf8');
  let updated = false;

  // Fix user_model.dart imports - handle various depths
  const userModelPatterns = [
    '../../../models/user_model.dart',
    '../../../../models/user_model.dart',
    '../../models/user_model.dart',
    '../models/user_model.dart',
    '../../../features/user/models/user_model.dart'
  ];

  const correctUserModel = '../../../features/user/models/user_model.dart';
  for (const pattern of userModelPatterns.filter(p => p !== correctUserModel)) {
    if (content.includes(`'${pattern}'`)) {
      content = content.replace(new RegExp(`'${pattern.replace(/\./g, '\\.')}'`, 'g'), `'${correctUserModel}'`);
      updated = true;
      console.log(`  ✓ Fixed user_model.dart import`);
    }
  }

  // Fix user_controller.dart imports
  const userControllerPatterns = [
    '../../../controllers/user_controller.dart',
    '../../../../controllers/user_controller.dart',
    '../../controllers/user_controller.dart',
    '../controllers/user_controller.dart'
  ];

  const correctUserController = '../../../features/user/controllers/user_controller.dart';
  for (const pattern of userControllerPatterns) {
    if (content.includes(`'${pattern}'`)) {
      content = content.replace(new RegExp(`'${pattern.replace(/\./g, '\\.')}'`, 'g'), `'${correctUserController}'`);
      updated = true;
      console.log(`  ✓ Fixed user_controller.dart import`);
    }
  }

  // Fix user_data_controller.dart imports
  const userDataControllerPatterns = [
    '../../../controllers/user_data_controller.dart',
    '../../../../controllers/user_data_controller.dart'
  ];

  const correctUserDataController = '../../../features/user/controllers/user_data_controller.dart';
  for (const pattern of userDataControllerPatterns) {
    if (content.includes(`'${pattern}'`)) {
      content = content.replace(new RegExp(`'${pattern.replace(/\./g, '\\.')}'`, 'g'), `'${correctUserDataController}'`);
      updated = true;
      console.log(`  ✓ Fixed user_data_controller.dart import`);
    }
  }

  // Fix user_cache_service.dart imports
  const userCacheServicePatterns = [
    '../../../services/user_cache_service.dart',
    '../../../../services/user_cache_service.dart'
  ];

  const correctUserCacheService = '../../../features/user/services/user_cache_service.dart';
  for (const pattern of userCacheServicePatterns) {
    if (content.includes(`'${pattern}'`)) {
      content = content.replace(new RegExp(`'${pattern.replace(/\./g, '\\.')}'`, 'g'), `'${correctUserCacheService}'`);
      updated = true;
      console.log(`  ✓ Fixed user_cache_service.dart import`);
    }
  }

  // Fix user_data_service.dart imports
  const userDataServicePatterns = [
    '../../../services/user_data_service.dart',
    '../../../../services/user_data_service.dart',
    '../../services/user_data_service.dart'
  ];

  const correctUserDataService = '../../../features/user/services/user_data_service.dart';
  for (const pattern of userDataServicePatterns) {
    if (content.includes(`'${pattern}'`)) {
      content = content.replace(new RegExp(`'${pattern.replace(/\./g, '\\.')}'`, 'g'), `'${correctUserDataService}'`);
      updated = true;
      console.log(`  ✓ Fixed user_data_service.dart import`);
    }

    // Also fix import package:janmat/services/user_data_service.dart style
    if (content.includes('package:janmat/services/user_data_service.dart')) {
      content = content.replace(/package:janmat\/services\/user_data_service.dart/g, 'package:janmat/features/user/services/user_data_service.dart');
      updated = true;
      console.log(`  ✓ Fixed package user_data_service.dart import`);
    }
  }

  // Fix app_logger.dart imports in user services
  if (filePath.includes('lib/features/user/services/')) {
    if (content.includes("'../utils/app_logger.dart'")) {
      content = content.replace(/'\.\.\/utils\/app_logger\.dart'/g, "'../../../utils/app_logger.dart'");
      updated = true;
      console.log(`  ✓ Fixed app_logger.dart import in user service`);
    }
  }

  // Write back the file if updated
  if (updated) {
    fs.writeFileSync(filePath, content, 'utf8');
  }
}

// Main execution
try {
  const dartFiles = findDartFiles('./lib');
  console.log(`Found ${dartFiles.length} Dart files to process`);

  for (const file of dartFiles) {
    try {
      updateImports(file);
    } catch (error) {
      console.error(`Error processing ${file}:`, error.message);
    }
  }

  console.log('\n✅ Import path updates completed!');
  console.log('🎯 Now run: flutter clean && flutter pub get && flutter build apk --debug');

} catch (error) {
  console.error('❌ Error:', error.message);
  process.exit(1);
}
