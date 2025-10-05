"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendExpirationWarnings = exports.checkExpiredSubscriptions = exports.updateUserFCMToken = exports.sendNotificationToTopic = exports.unsubscribeFromTopic = exports.subscribeToTopic = exports.sendPushNotificationToMultiple = exports.sendPushNotification = exports.testFirebaseAdmin = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
// Initialize Firebase Admin - let it auto-discover credentials
admin.initializeApp();
// Note: Using Firebase Admin SDK with FCM V1 API - no server key needed
// The Admin SDK handles authentication automatically via service account
// Test function to check Firebase Admin SDK
exports.testFirebaseAdmin = functions.https.onCall(async (data, context) => {
    try {
        console.log('🧪 Testing Firebase Admin SDK...');
        // Test basic Admin SDK functionality
        const testMessage = {
            notification: {
                title: 'Test Notification',
                body: 'This is a test from Firebase Functions',
            },
            data: {
                test: 'true',
                timestamp: Date.now().toString(),
            },
            token: 'test-token', // This will fail but we'll see the error
        };
        console.log('📤 Attempting to send test message...');
        const result = await admin.messaging().send(testMessage);
        return {
            success: true,
            message: 'Firebase Admin SDK is working',
            result: result,
        };
    }
    catch (error) {
        console.error('❌ Firebase Admin SDK test failed:', error);
        return {
            success: false,
            error: error.message,
            code: error.code,
            details: JSON.stringify(error, null, 2),
        };
    }
});
// Send push notification
exports.sendPushNotification = functions.https.onCall(async (data, context) => {
    try {
        const { token, title, body, notificationData } = data;
        console.log('📨 SendPushNotification called with:', { token: (token === null || token === void 0 ? void 0 : token.substring(0, 20)) + '...', title, body });
        if (!token) {
            throw new functions.https.HttpsError('invalid-argument', 'FCM token is required');
        }
        if (!title || !body) {
            throw new functions.https.HttpsError('invalid-argument', 'Title and body are required');
        }
        // Create notification payload for Admin SDK
        const payload = {
            notification: {
                title: title,
                body: body,
                clickAction: 'FLUTTER_NOTIFICATION_CLICK',
            },
            data: Object.assign(Object.assign({}, notificationData), { timestamp: Date.now().toString() }),
            token: token, // Use token instead of to
        };
        console.log('🔧 Using payload for Admin SDK:', JSON.stringify(payload, null, 2));
        // Send via Firebase Admin SDK (FCM V1 API)
        console.log('🚀 Sending via Firebase Admin SDK (FCM V1 API)...');
        console.log('📦 Payload:', JSON.stringify(payload, null, 2));
        try {
            const response = await admin.messaging().send(payload);
            console.log('✅ Push notification sent successfully via Admin SDK:', response);
            return {
                success: true,
                messageId: response,
                method: 'admin_sdk',
            };
        }
        catch (adminError) {
            console.error('❌ Admin SDK error:', adminError);
            console.error('❌ Error code:', adminError === null || adminError === void 0 ? void 0 : adminError.code);
            console.error('❌ Error message:', adminError === null || adminError === void 0 ? void 0 : adminError.message);
            // Check specific error types
            if ((adminError === null || adminError === void 0 ? void 0 : adminError.code) === 'messaging/authentication-error') {
                console.error('❌ Authentication error - Firebase project configuration issue');
            }
            else if ((adminError === null || adminError === void 0 ? void 0 : adminError.code) === 'messaging/invalid-argument') {
                console.error('❌ Invalid argument - payload format issue');
            }
            else if ((adminError === null || adminError === void 0 ? void 0 : adminError.code) === 'messaging/invalid-registration-token') {
                console.error('❌ Invalid FCM token provided');
            }
            else if ((adminError === null || adminError === void 0 ? void 0 : adminError.code) === 'messaging/registration-token-not-registered') {
                console.error('❌ FCM token not registered - user may have uninstalled app');
            }
            throw adminError;
        }
    }
    catch (error) {
        console.error('❌ Error sending push notification:', error);
        const errorMessage = error instanceof Error ? error.message : 'Unknown error';
        throw new functions.https.HttpsError('internal', `Failed to send push notification: ${errorMessage}`);
    }
});
// Send push notification to multiple tokens
exports.sendPushNotificationToMultiple = functions.https.onCall(async (data, context) => {
    try {
        const { tokens, title, body, notificationData } = data;
        if (!tokens || !Array.isArray(tokens) || tokens.length === 0) {
            throw new functions.https.HttpsError('invalid-argument', 'Tokens array is required');
        }
        if (!title || !body) {
            throw new functions.https.HttpsError('invalid-argument', 'Title and body are required');
        }
        // Create notification payload
        const payload = {
            notification: {
                title: title,
                body: body,
                clickAction: 'FLUTTER_NOTIFICATION_CLICK',
            },
            data: Object.assign(Object.assign({}, notificationData), { timestamp: Date.now().toString() }),
        };
        // Send notification to multiple tokens
        const response = await admin.messaging().sendToDevice(tokens, payload);
        console.log('✅ Push notifications sent successfully to', tokens.length, 'tokens');
        return {
            success: true,
            messageId: response,
            tokensCount: tokens.length,
        };
    }
    catch (error) {
        console.error('❌ Error sending push notifications to multiple tokens:', error);
        throw new functions.https.HttpsError('internal', 'Failed to send push notifications');
    }
});
// Subscribe user to topic
exports.subscribeToTopic = functions.https.onCall(async (data, context) => {
    try {
        const { tokens, topic } = data;
        if (!tokens || !Array.isArray(tokens) || tokens.length === 0) {
            throw new functions.https.HttpsError('invalid-argument', 'Tokens array is required');
        }
        if (!topic) {
            throw new functions.https.HttpsError('invalid-argument', 'Topic is required');
        }
        // Subscribe tokens to topic
        await admin.messaging().subscribeToTopic(tokens, topic);
        console.log('✅ Subscribed', tokens.length, 'tokens to topic:', topic);
        return {
            success: true,
            tokensCount: tokens.length,
        };
    }
    catch (error) {
        console.error('❌ Error subscribing to topic:', error);
        throw new functions.https.HttpsError('internal', 'Failed to subscribe to topic');
    }
});
// Unsubscribe user from topic
exports.unsubscribeFromTopic = functions.https.onCall(async (data, context) => {
    try {
        const { tokens, topic } = data;
        if (!tokens || !Array.isArray(tokens) || tokens.length === 0) {
            throw new functions.https.HttpsError('invalid-argument', 'Tokens array is required');
        }
        if (!topic) {
            throw new functions.https.HttpsError('invalid-argument', 'Topic is required');
        }
        // Unsubscribe tokens from topic
        await admin.messaging().unsubscribeFromTopic(tokens, topic);
        console.log('✅ Unsubscribed', tokens.length, 'tokens from topic:', topic);
        return {
            success: true,
            tokensCount: tokens.length,
        };
    }
    catch (error) {
        console.error('❌ Error unsubscribing from topic:', error);
        throw new functions.https.HttpsError('internal', 'Failed to unsubscribe from topic');
    }
});
// Send notification to topic
exports.sendNotificationToTopic = functions.https.onCall(async (data, context) => {
    try {
        const { topic, title, body, notificationData } = data;
        if (!topic) {
            throw new functions.https.HttpsError('invalid-argument', 'Topic is required');
        }
        if (!title || !body) {
            throw new functions.https.HttpsError('invalid-argument', 'Title and body are required');
        }
        // Create notification payload
        const payload = {
            notification: {
                title: title,
                body: body,
                clickAction: 'FLUTTER_NOTIFICATION_CLICK',
            },
            data: Object.assign(Object.assign({}, notificationData), { timestamp: Date.now().toString() }),
        };
        // Send notification to topic
        const response = await admin.messaging().sendToTopic(topic, payload);
        console.log('✅ Topic notification sent successfully to topic:', topic);
        return {
            success: true,
            messageId: response.messageId,
        };
    }
    catch (error) {
        console.error('❌ Error sending topic notification:', error);
        throw new functions.https.HttpsError('internal', 'Failed to send topic notification');
    }
});
// Update user FCM token when it changes
exports.updateUserFCMToken = functions.firestore
    .document('users/{userId}')
    .onUpdate(async (change, context) => {
    try {
        const newData = change.after.data();
        const oldData = change.before.data();
        const newToken = newData === null || newData === void 0 ? void 0 : newData.fcmToken;
        const oldToken = oldData === null || oldData === void 0 ? void 0 : oldData.fcmToken;
        // If token changed, update all subscriptions
        if (newToken && newToken !== oldToken) {
            console.log('🔄 FCM token updated for user:', context.params.userId);
            // You could update topic subscriptions here if needed
            // For now, we'll just log the change
            return {
                success: true,
                message: 'Token updated successfully',
            };
        }
        return null;
    }
    catch (error) {
        console.error('❌ Error updating user FCM token:', error);
        return null;
    }
});
// Scheduled function to check and expire subscriptions daily
exports.checkExpiredSubscriptions = functions.pubsub
    .schedule('0 0 * * *') // Run daily at midnight UTC
    .timeZone('Asia/Kolkata') // IST timezone
    .onRun(async (context) => {
    try {
        console.log('⏰ Starting daily subscription expiration check...');
        const now = admin.firestore.Timestamp.now();
        const db = admin.firestore();
        // Find all active subscriptions that have expired
        const expiredSubscriptionsQuery = db
            .collection('subscriptions')
            .where('isActive', '==', true)
            .where('expiresAt', '<', now);
        const expiredSubscriptionsSnapshot = await expiredSubscriptionsQuery.get();
        console.log(`📊 Found ${expiredSubscriptionsSnapshot.docs.length} expired subscriptions`);
        if (expiredSubscriptionsSnapshot.empty) {
            console.log('✅ No expired subscriptions to process');
            return null;
        }
        // Process each expired subscription
        const batch = db.batch();
        const userUpdates = {};
        const notifications = [];
        for (const doc of expiredSubscriptionsSnapshot.docs) {
            const subscriptionData = doc.data();
            const userId = subscriptionData.userId;
            const planId = subscriptionData.planId;
            console.log(`⏰ Processing expired subscription: ${doc.id} for user: ${userId}, plan: ${planId}`);
            // Mark subscription as expired
            batch.update(doc.ref, {
                isActive: false,
                expiredAt: now,
                updatedAt: now,
            });
            // Prepare user downgrade (only if this was their active plan)
            if (!userUpdates[userId]) {
                userUpdates[userId] = {
                    premium: false,
                    subscriptionPlanId: null,
                    subscriptionExpiresAt: null,
                    updatedAt: now,
                };
            }
            // Prepare expiration notification
            try {
                const userDoc = await db.collection('users').doc(userId).get();
                const userData = userDoc.data();
                if (userData === null || userData === void 0 ? void 0 : userData.fcmToken) {
                    const planName = planId === 'gold_plan' ? 'Gold' :
                        planId === 'platinum_plan' ? 'Platinum' :
                            planId === 'basic_plan' ? 'Basic' : 'Premium';
                    notifications.push({
                        token: userData.fcmToken,
                        title: `${planName} Plan Expired`,
                        body: `Your ${planName} plan has expired. Upgrade to continue enjoying premium features.`,
                        data: {
                            type: 'subscription_expired',
                            planId: planId,
                            userId: userId,
                        }
                    });
                }
            }
            catch (error) {
                console.error(`❌ Error preparing notification for user ${userId}:`, error);
            }
        }
        // Execute batch updates for subscriptions
        await batch.commit();
        console.log('✅ Marked subscriptions as expired');
        // Update users (downgrade to free plan)
        const userUpdatePromises = Object.entries(userUpdates).map(async ([userId, updateData]) => {
            try {
                await db.collection('users').doc(userId).update(updateData);
                console.log(`✅ Downgraded user ${userId} to free plan`);
            }
            catch (error) {
                console.error(`❌ Error updating user ${userId}:`, error);
            }
        });
        await Promise.all(userUpdatePromises);
        // Send expiration notifications
        if (notifications.length > 0) {
            console.log(`📨 Sending ${notifications.length} expiration notifications...`);
            for (const notification of notifications) {
                try {
                    await admin.messaging().send({
                        notification: {
                            title: notification.title,
                            body: notification.body,
                        },
                        data: notification.data,
                        token: notification.token,
                    });
                    console.log(`✅ Sent expiration notification to user`);
                }
                catch (error) {
                    console.error('❌ Error sending expiration notification:', error);
                }
            }
        }
        console.log('🎉 Subscription expiration check completed successfully');
        return {
            success: true,
            processedSubscriptions: expiredSubscriptionsSnapshot.docs.length,
            notificationsSent: notifications.length,
        };
    }
    catch (error) {
        console.error('❌ Error in subscription expiration check:', error);
        throw error;
    }
});
// Function to send expiration warnings (3 days, 1 day, 1 hour before expiry)
exports.sendExpirationWarnings = functions.pubsub
    .schedule('0 */6 * * *') // Run every 6 hours
    .timeZone('Asia/Kolkata')
    .onRun(async (context) => {
    try {
        console.log('⚠️ Checking for subscriptions expiring soon...');
        const db = admin.firestore();
        const now = admin.firestore.Timestamp.now();
        // Check for subscriptions expiring in 3 days, 1 day, and 1 hour
        const warningThresholds = [
            { hours: 72, label: '3 days' },
            { hours: 24, label: '1 day' },
            { hours: 1, label: '1 hour' }, // 1 hour
        ];
        const notifications = [];
        for (const threshold of warningThresholds) {
            const futureTime = new Date(now.toDate().getTime() + (threshold.hours * 60 * 60 * 1000));
            const futureTimestamp = admin.firestore.Timestamp.fromDate(futureTime);
            const expiringSoonQuery = db
                .collection('subscriptions')
                .where('isActive', '==', true)
                .where('expiresAt', '>=', now)
                .where('expiresAt', '<=', futureTimestamp);
            const expiringSoonSnapshot = await expiringSoonQuery.get();
            console.log(`📊 Found ${expiringSoonSnapshot.docs.length} subscriptions expiring in ${threshold.label}`);
            for (const doc of expiringSoonSnapshot.docs) {
                const subscriptionData = doc.data();
                const userId = subscriptionData.userId;
                const planId = subscriptionData.planId;
                // Check if we already sent a warning for this subscription and threshold
                const warningSent = subscriptionData[`warningSent_${threshold.hours}h`];
                if (warningSent)
                    continue;
                try {
                    const userDoc = await db.collection('users').doc(userId).get();
                    const userData = userDoc.data();
                    if (userData === null || userData === void 0 ? void 0 : userData.fcmToken) {
                        const planName = planId === 'gold_plan' ? 'Gold' :
                            planId === 'platinum_plan' ? 'Platinum' :
                                planId === 'basic_plan' ? 'Basic' : 'Premium';
                        notifications.push({
                            token: userData.fcmToken,
                            title: `${planName} Plan Expires Soon`,
                            body: `Your ${planName} plan expires in ${threshold.label}. Renew now to avoid service interruption.`,
                            data: {
                                type: 'subscription_warning',
                                planId: planId,
                                userId: userId,
                                expiresIn: threshold.label,
                            }
                        });
                        // Mark warning as sent
                        await doc.ref.update({
                            [`warningSent_${threshold.hours}h`]: true,
                            updatedAt: now,
                        });
                    }
                }
                catch (error) {
                    console.error(`❌ Error processing warning for subscription ${doc.id}:`, error);
                }
            }
        }
        // Send warning notifications
        if (notifications.length > 0) {
            console.log(`📨 Sending ${notifications.length} expiration warnings...`);
            for (const notification of notifications) {
                try {
                    await admin.messaging().send({
                        notification: {
                            title: notification.title,
                            body: notification.body,
                        },
                        data: notification.data,
                        token: notification.token,
                    });
                    console.log(`✅ Sent expiration warning`);
                }
                catch (error) {
                    console.error('❌ Error sending expiration warning:', error);
                }
            }
        }
        console.log('✅ Expiration warnings check completed');
        return {
            success: true,
            warningsSent: notifications.length,
        };
    }
    catch (error) {
        console.error('❌ Error in expiration warnings check:', error);
        throw error;
    }
});
//# sourceMappingURL=index.js.map