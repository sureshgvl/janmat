# Firebase Cloud Functions Setup - Deferred Delete System

This guide explains how to set up the **deferred storage cleanup** Firebase Cloud Function that completes the deferred delete architecture.

## 📋 Prerequisites

- Firebase CLI installed: `npm install -g firebase-tools`
- Firebase project initialized with Functions
- Admin SDK permissions for Storage and Firestore

## 📁 Function Structure

Your Firebase Functions directory should look like:

```
functions/
├── src/
│   └── cleanup_deleted_storage.js  # Our function code
├── package.json
└── index.js                       # Main entry point
```

## 🚀 Deployment Steps

### Step 1: Add Function to Your Project

1. Copy `cleanup_deleted_storage.js` to your `functions/src/` directory
2. In `functions/src/index.js`, add:

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Import our cleanup function
const { cleanupDeletedStorage, cleanupDeletedStorageManual } = require('./cleanup_deleted_storage');

admin.initializeApp();

// Export the functions
exports.cleanupDeletedStorage = cleanupDeletedStorage;
exports.cleanupDeletedStorageManual = cleanupDeletedStorageManual;
```

### Step 2: Update package.json

Ensure your `functions/package.json` includes:

```json
{
  "name": "functions",
  "description": "Cloud Functions for Firebase",
  "scripts": {
    "serve": "firebase emulators:start --only functions",
    "shell": "firebase functions:shell",
    "start": "npm run shell",
    "deploy": "firebase deploy --only functions",
    "logs": "firebase functions:log"
  },
  "engines": {
    "node": "18"
  },
  "main": "src/index.js",
  "dependencies": {
    "firebase-admin": "^12.0.0",
    "firebase-functions": "^5.0.0"
  },
  "devDependencies": {
    "firebase-functions-test": "^3.1.0"
  },
  "private": true
}
```

### Step 3: Install Dependencies

```bash
cd functions/
npm install
```

### Step 4: Deploy Function

```bash
# Deploy only functions
firebase deploy --only functions

# Or deploy both functions explicitly
firebase deploy --only functions:cleanupDeletedStorage,functions:cleanupDeletedStorageManual
```

## 🧪 Testing the Function

### Manual Testing (HTTP Trigger)

After deployment, test manually:

```bash
curl -X POST https://<region>-<project-id>.cloudfunctions.net/cleanupDeletedStorageManual

# Or via browser: https://<region>-<project-id>.cloudfunctions.net/cleanupDeletedStorageManual
```

Expected response:
```json
{
  "status": "success",
  "message": "Manual cleanup completed",
  "result": {
    "success": true,
    "candidatesProcessed": 2,
    "totalFilesDeleted": 5,
    "errors": 0,
    "duration": "45s",
    "timestamp": "2025-10-30T02:30:00.000Z"
  }
}
```

### Monitoring Function Logs

View execution logs:

```bash
# View recent function logs
firebase functions:log

# View specific function logs
firebase functions:log --only cleanupDeletedStorage

# Tail logs in real-time
firebase functions:log --only cleanupDeletedStorage --open
```

## 🗂️ How the Function Works

### 1. Discovery Phase
- Uses `collectionGroup('candidates')` to find ALL candidates with `deleteStorage != []`
- Searches across entire hierarchical structure
- Works regardless of state/district/body/ward location

### 2. Processing Phase
- Extract location info from document path for logging
- Delete each storage file using absolute bucket paths
- Continue processing even if individual file deletes fail
- Clear `deleteStorage` array after completion

### 3. Reporting Phase
- Return detailed success/failure metrics
- Log comprehensive information for monitoring

## 📊 Monitoring & Alerting

### Setting Up Alerts

In Firebase Console:
1. Go to Functions → Your Function
2. Set up failure alerts
3. Configure log-based metrics

### Custom Error Alerts

```javascript
const { IncomingWebhook } = require('@slack/webhooks');

// In cleanup function
async function sendErrorAlert(title, error) {
  const webhook = new IncomingWebhook('YOUR_SLACK_WEBHOOK_URL');
  await webhook.send({
    text: `🚨 Firebase Function Error: ${title}`,
    blocks: [/* your alert format */]
  });
}
```

## 🔧 Troubleshooting

### Common Issues

#### Function Timeout
- **Symptoms**: Function ends after 540 seconds
- **Cause**: Too many files to delete at once
- **Solution**: Add batching logic:

```javascript
// Process files in batches of 100
const BATCH_SIZE = 100;
for (let i = 0; i < deleteStorage.length; i += BATCH_SIZE) {
  const batch = deleteStorage.slice(i, i + BATCH_SIZE);
  await Promise.all(batch.map(path => deleteFile(path)));
}
```

#### Billing Concerns
- **Minimum Cost**: Function runs daily regardless of work
- **Solution**: Check if work exists before full execution:

```javascript
const count = (await candidatesSnapshot.docs[0].ref.parent.listDocuments()).length;
if (count === 0) return { skipped: true };
```

### Function Deployment Issues

#### Cold Start Times
- **Issue**: First execution slow due to initialization
- **Solution**: Schedule at low-traffic times (2 AM)

#### Race Conditions
- **Issue**: Multiple function instances
- **Solution**: Add mutual exclusion via Firestore document

## 📈 Performance Tuning

### Memory Allocation
```javascript
.runWith({
  memory: '256MB', // Reduce if few files
  timeoutSeconds: 540
})
```

### Batching Operations
```javascript
// Batch Firestore updates
const batch = admin.firestore().batch();
batch.update(doc.ref, { deleteStorage: [] });
// Commit in batches of 500
```

### Storage Optimization
```javascript
// Use Storage client with optimized settings
const bucket = admin.storage().bucket();
bucket.deleteFiles({ prefix: 'cleanup/' }, callback);
```

## 🎯 Production Checklist

### Pre-Deployment
- [ ] Test function with sample data in emulator
- [ ] Verify Firebase Storage permissions
- [ ] Confirm Firestore security rules allow access
- [ ] Set up monitoring and alerts

### Post-Deployment
- [ ] Monitor first few runs manually
- [ ] Verify `deleteStorage` arrays are clearing
- [ ] Confirm storage files are actually deleted
- [ ] Check Firebase billing for unexpected costs

### Maintenance
- [ ] Monitor function execution time trending
- [ ] Clean up old log entries periodically
- [ ] Update function code for new requirements

## 📞 Support

If you encounter issues:

1. Check Firebase Console → Functions → Logs
2. Test with manual HTTP trigger
3. Verify `deleteStorage` data exists in Firestore
4. Confirm Firebase Storage bucket permissions

---

**🎉 With this setup, your deferred delete architecture is complete!**

- **Flutter App**: Instant UI responses with background uploads
- **Firebase Firestore**: `deleteStorage` arrays for cleanup queues
- **Cloud Functions**: Automatic nightly cleanup of storage files

Your media management now has **Facebook/Instagram-level UX** with robust backend cleanup! 🚀
