/**
 * Firebase Cloud Function - Cleanup Deleted Storage Files
 *
 * This function runs nightly to clean up Firebase Storage files
 * that were queued in candidates' deleteStorage arrays.
 *
 * Run: firebase deploy --only functions:cleanupDeletedStorage
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Scheduled function that runs every 24 hours to clean up deleted storage files.
 * Uses collectionGroup query to find all candidates with pending deletions across
 * the entire hierarchical structure (states/districts/bodies/wards/candidates).
 */
exports.cleanupDeletedStorage = functions
  .runWith({
    timeoutSeconds: 540, // 9 minutes max execution time
    memory: '1GB',       // Sufficient for file operations
  })
  .pubsub
  .schedule('every 24 hours')  // Runs nightly at 2 AM IST (Firebase timezone)
  .timeZone('Asia/Kolkata')
  .onRun(async (context) => {
    const startTime = Date.now();
    console.log('🧹 [Cleanup] Starting nightly storage cleanup...');

    try {
      // Step 1: Find all candidates with pending storage deletions
      const candidatesSnapshot = await admin.firestore()
        .collectionGroup('candidates')
        .where('deleteStorage', '!=', [])
        .get();

      const candidateCount = candidatesSnapshot.size;
      console.log(`🧹 [Cleanup] Found ${candidateCount} candidates with ${candidatesSnapshot.size} documents to process`);

      if (candidateCount === 0) {
        console.log('🧹 [Cleanup] No candidates with pending deletions. Exiting.');
        return { success: true, candidatesProcessed: 0, filesDeleted: 0 };
      }

      let totalFilesDeleted = 0;
      let candidatesProcessed = 0;
      let errors = [];

      // Step 2: Process each candidate's pending deletions
      for (const docSnapshot of candidatesSnapshot.docs) {
        try {
          const candidateId = docSnapshot.id;
          const candidateData = docSnapshot.data();
          const deleteStorage = candidateData.deleteStorage || [];

          // Extract hierarchical location for logging
          const pathSegments = docSnapshot.ref.path.split('/');
          const stateId = pathSegments[1];
          const districtId = pathSegments[3];
          const bodyId = pathSegments[5];
          const wardId = pathSegments[7];

          console.log(`🗑️ [Cleanup] Processing ${candidateId} (${stateId}/${districtId}/${bodyId}/${wardId}) - ${deleteStorage.length} files`);

          let candidateFilesDeleted = 0;

          // Delete each file in deleteStorage array
          for (const storagePath of deleteStorage) {
            try {
              // storagePath format: 'media/images/photo.jpg' or 'media/videos/video.mp4'
              await admin.storage().bucket().file(storagePath).delete();
              candidateFilesDeleted++;
              totalFilesDeleted++;

              console.log(`✅ [Cleanup] Deleted: ${storagePath}`);
            } catch (fileError) {
              // Log error but continue processing other files
              console.error(`❌ [Cleanup] Failed to delete ${storagePath} for ${candidateId}:`, fileError);
              errors.push({
                candidateId,
                storagePath,
                error: fileError.message,
                location: `${stateId}/${districtId}/${bodyId}/${wardId}`
              });
            }
          }

          // Clear the deleteStorage array for this candidate
          await docSnapshot.ref.update({
            deleteStorage: [],  // Clear array
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });

          candidatesProcessed++;
          console.log(`🔄 [Cleanup] Cleared deleteStorage for ${candidateId} (${candidateFilesDeleted} files deleted)`);

        } catch (candidateError) {
          console.error(`💥 [Cleanup] Error processing candidate ${docSnapshot.id}:`, candidateError);
          errors.push({
            candidateId: docSnapshot.id,
            error: candidateError.message,
            location: docSnapshot.ref.path
          });
        }
      }

      // Step 3: Report results
      const endTime = Date.now();
      const duration = endTime - startTime;

      const result = {
        success: errors.length === 0,
        candidatesProcessed,
        totalFilesDeleted,
        errors: errors.length,
        duration: `${Math.round(duration / 1000)}s`,
        timestamp: new Date().toISOString()
      };

      if (errors.length > 0) {
        console.warn(`⚠️ [Cleanup] Completed with ${errors.length} errors:`, errors);
      } else {
        console.log(`✨ [Cleanup] Completed successfully!`);
      }

      console.log(`📊 [Cleanup] Summary: ${candidatesProcessed} candidates, ${totalFilesDeleted} files deleted, ${errors.length} errors in ${result.duration}`);

      return result;

    } catch (error) {
      console.error('💥 [Cleanup] Critical error:', error);

      // Send error notification if you have alerting setup
      // await sendErrorAlert('cleanupDeletedStorage failed', error);

      throw error;
    }
  });

// Optional: HTTP-triggered version for manual runs (useful for testing)
exports.cleanupDeletedStorageManual = functions
  .https.onRequest(async (req, res) => {
    try {
      console.log('🧹 [Manual Cleanup] Triggered manually via HTTP');

      // Run the same logic as the scheduled function
      const result = await exports.cleanupDeletedStorage.onRun(null);

      res.status(200).json({
        status: 'success',
        message: 'Manual cleanup completed',
        result
      });
    } catch (error) {
      console.error('💥 [Manual Cleanup] Error:', error);
      res.status(500).json({
        status: 'error',
        message: error.message
      });
    }
  });
