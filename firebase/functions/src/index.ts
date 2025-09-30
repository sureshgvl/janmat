import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Initialize Firebase Admin
admin.initializeApp();

// Send push notification
export const sendPushNotification = functions.https.onCall(async (data, context) => {
  try {
    const { token, title, body, notificationData } = data;

    if (!token) {
      throw new functions.https.HttpsError('invalid-argument', 'FCM token is required');
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
      data: {
        ...notificationData,
        timestamp: Date.now().toString(),
      },
    };

    // Send notification
    const response = await admin.messaging().sendToDevice(token, payload);

    console.log('✅ Push notification sent successfully:', response);

    return {
      success: true,
      messageId: response,
    };
  } catch (error) {
    console.error('❌ Error sending push notification:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send push notification');
  }
});

// Send push notification to multiple tokens
export const sendPushNotificationToMultiple = functions.https.onCall(async (data, context) => {
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
      data: {
        ...notificationData,
        timestamp: Date.now().toString(),
      },
    };

    // Send notification to multiple tokens
    const response = await admin.messaging().sendToDevice(tokens, payload);

    console.log('✅ Push notifications sent successfully to', tokens.length, 'tokens');

    return {
      success: true,
      messageId: response,
      tokensCount: tokens.length,
    };
  } catch (error) {
    console.error('❌ Error sending push notifications to multiple tokens:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send push notifications');
  }
});

// Subscribe user to topic
export const subscribeToTopic = functions.https.onCall(async (data, context) => {
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
  } catch (error) {
    console.error('❌ Error subscribing to topic:', error);
    throw new functions.https.HttpsError('internal', 'Failed to subscribe to topic');
  }
});

// Unsubscribe user from topic
export const unsubscribeFromTopic = functions.https.onCall(async (data, context) => {
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
  } catch (error) {
    console.error('❌ Error unsubscribing from topic:', error);
    throw new functions.https.HttpsError('internal', 'Failed to unsubscribe from topic');
  }
});

// Send notification to topic
export const sendNotificationToTopic = functions.https.onCall(async (data, context) => {
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
      data: {
        ...notificationData,
        timestamp: Date.now().toString(),
      },
    };

    // Send notification to topic
    const response = await admin.messaging().sendToTopic(topic, payload);

    console.log('✅ Topic notification sent successfully to topic:', topic);

    return {
      success: true,
      messageId: response.messageId,
    };
  } catch (error) {
    console.error('❌ Error sending topic notification:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send topic notification');
  }
});

// Update user FCM token when it changes
export const updateUserFCMToken = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    try {
      const newData = change.after.data();
      const oldData = change.before.data();

      const newToken = newData?.fcmToken;
      const oldToken = oldData?.fcmToken;

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
    } catch (error) {
      console.error('❌ Error updating user FCM token:', error);
      return null;
    }
  });