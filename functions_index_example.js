// functions/src/index.js - Add these lines to your existing file

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Import our cleanup functions
const { cleanupDeletedStorage, cleanupDeletedStorageManual } = require('./cleanup_deleted_storage');

// Export the scheduled function (runs automatically every 24 hours)
exports.cleanupDeletedStorage = cleanupDeletedStorage;

// Export the manual function (for testing/debugging)
exports.cleanupDeletedStorageManual = cleanupDeletedStorageManual;

// Add at the end of your existing functions if you have others...
