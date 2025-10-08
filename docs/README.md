# 🔧 JanMat Developer Documentation

## Overview

This documentation provides comprehensive guides for developing, testing, and maintaining the JanMat application. It covers all major features and systems in the app.

## 📚 Documentation Structure

### Core Systems
- **[Authentication](auth/)** - Complete login-to-home-screen flow
  - [Flow Guide](auth/README.md) - Step-by-step authentication process
  - [Logging Guide](auth/LOGGING_GUIDE.md) - Using AppLogger for debugging
  - [Technical Summary](auth/SUMMARY.md) - Architecture and implementation
  - [Troubleshooting](auth/TROUBLESHOOTING.md) - Common issues and solutions
  - [Testing Guide](auth/TESTING_GUIDE.md) - Comprehensive testing scenarios

- **[Chat System](chat/)** - Real-time messaging and rooms
  - [Implementation Guide](chat/README.md) - Chat architecture and features
  - [Logging Guide](chat/LOGGING_GUIDE.md) - Chat debugging with AppLogger
  - [Technical Summary](chat/SUMMARY.md) - Chat system architecture
  - [Caching Strategy](chat/CACHING_STRATEGY.md) - Message and user caching
  - [Loading Techniques](chat/LOADING_TECHNIQUES.md) - Performance optimization
  - [Improvement Areas](chat/IMPROVEMENT_AREAS.md) - Future enhancements

### Quick Start Guides

#### For New Developers
1. **Setup Development Environment**
   ```bash
   flutter pub get
   flutter run --debug
   ```

2. **Enable Comprehensive Logging**
   ```dart
   // In main.dart
   AppLogger.configure(
     auth: true,
     network: true,
     cache: true,
     database: true,
     performance: true,
   );
   ```

3. **Test Authentication Flow**
   - Follow [Authentication Testing Guide](auth/TESTING_GUIDE.md)
   - Use test phone numbers in Firebase Console
   - Check console logs for debugging

#### For Debugging Issues
1. **Authentication Problems** → [Auth Troubleshooting](auth/TROUBLESHOOTING.md)
2. **Chat Issues** → [Chat Logging Guide](chat/LOGGING_GUIDE.md)
3. **Performance Issues** → Check performance logs in console

## 🏗️ Architecture Overview

### Core Components
- **Authentication System**: Phone OTP + Google Sign-In
- **Chat System**: Real-time messaging with Firebase
- **User Management**: Profile completion and caching
- **Data Storage**: Firestore + local SQLite caching

### Key Technologies
- **Flutter**: Cross-platform UI framework
- **Firebase**: Auth, Firestore, Storage, FCM
- **GetX**: State management and routing
- **AppLogger**: Centralized logging system

## 🔧 Development Tools

### Logging System
```dart
import 'utils/app_logger.dart';

// Enable specific log categories
AppLogger.configure(
  auth: true,        // Authentication operations
  network: true,     // Firebase/API calls
  cache: true,       // User data caching
  database: true,    // Firestore operations
  performance: true, // Timing metrics
  chat: false,       // Chat operations (can be verbose)
  ui: false,         // UI operations
);

// Usage examples
AppLogger.auth('User authentication successful');
AppLogger.network('Fetching user data from Firestore');
AppLogger.performance('Profile save took 800ms');
```

### Testing Commands
```bash
# Run all tests
flutter test

# Run integration tests
flutter drive --target=integration_test/app_test.dart

# Run with test logging
flutter run --debug --dart-define=TEST_MODE=true
```

### Firebase Configuration
```javascript
// Add test phone numbers for development
// Firebase Console > Authentication > Phone > Test numbers
// +91 9999999999 → 123456
// +91 8888888888 → 123456
```

## 🚨 Common Development Issues

### Authentication Issues
| Issue | Solution |
|-------|----------|
| No OTP received | Check [Auth Troubleshooting](auth/TROUBLESHOOTING.md) Issue 1 |
| Google sign-in fails | Check [Auth Troubleshooting](auth/TROUBLESHOOTING.md) Issue 3 |
| Profile not saving | Check [Auth Troubleshooting](auth/TROUBLESHOOTING.md) Issue 5 |

### Chat Issues
| Issue | Solution |
|-------|----------|
| Messages not loading | Check [Chat Logging Guide](chat/LOGGING_GUIDE.md) |
| Room creation fails | Verify Firebase permissions |
| Real-time updates slow | Check network connectivity |

### Performance Issues
| Issue | Solution |
|-------|----------|
| App startup slow | Check [Auth Summary](auth/SUMMARY.md) Performance section |
| Memory usage high | Monitor controller disposal |
| Network calls slow | Check Firebase configuration |

## 📋 Development Workflow

### 1. Feature Development
1. Create feature branch
2. Enable relevant logging
3. Implement with tests
4. Test on multiple devices
5. Create/update documentation

### 2. Debugging Process
1. Enable comprehensive logging
2. Reproduce the issue
3. Check console logs
4. Use debugging tools
5. Fix and test

### 3. Testing Process
1. Unit tests for logic
2. Widget tests for UI
3. Integration tests for flows
4. Manual testing checklist
5. Performance testing

## 📊 Code Quality Standards

### Logging Standards
- Use appropriate log categories
- Include context in log messages
- Don't log sensitive information
- Use consistent message formats

### Error Handling
- Catch and log all errors
- Provide user-friendly error messages
- Include error recovery mechanisms
- Don't expose internal errors to users

### Performance Standards
- Authentication: < 10 seconds
- Message loading: < 2 seconds
- UI responsiveness: < 100ms
- Memory usage: < 200MB

## 🔄 Version Control

### Branching Strategy
- `main`: Production code
- `develop`: Development integration
- `feature/*`: New features
- `bugfix/*`: Bug fixes
- `hotfix/*`: Critical fixes

### Commit Standards
```
feat: add Google Sign-In authentication
fix: resolve OTP timeout issue
docs: update authentication testing guide
test: add phone number validation tests
```

## 🚀 Deployment Checklist

### Pre-Release
- [ ] All tests passing
- [ ] Documentation updated
- [ ] Firebase configuration verified
- [ ] Performance benchmarks met
- [ ] Security review completed

### Release Process
1. Merge to main branch
2. Run full test suite
3. Build release APK
4. Upload to Play Store
5. Monitor crash reports

## 📞 Support & Resources

### Getting Help
- **Authentication Issues**: Check [Auth Troubleshooting](auth/TROUBLESHOOTING.md)
- **Chat Issues**: Check [Chat Logging Guide](chat/LOGGING_GUIDE.md)
- **Code Examples**: See individual guide code samples
- **Firebase Docs**: [Firebase Documentation](https://firebase.google.com/docs)

### Contributing
1. Follow existing code patterns
2. Add comprehensive tests
3. Update documentation
4. Follow logging standards
5. Test on multiple devices

---

## 🎯 Quick Reference

### Enable All Logging
```dart
AppLogger.configure(
  auth: true, network: true, cache: true,
  database: true, performance: true, chat: true
);
```

### Test Authentication
```bash
# Use test phone numbers
+91 9999999999 → OTP: 123456
+91 8888888888 → OTP: 123456
```

### Check User State
```dart
final user = FirebaseAuth.instance.currentUser;
final userDoc = await FirebaseFirestore.instance
    .collection('users')
    .doc(user?.uid)
    .get();
debugPrint('User: ${user?.phoneNumber}, Profile: ${userDoc.exists}');
```

This developer documentation provides everything needed to effectively work on the JanMat application. Start with the authentication and chat guides for the most critical systems.