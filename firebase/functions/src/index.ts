import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import Razorpay from 'razorpay';

// Initialize Firebase Admin - let it auto-discover credentials
admin.initializeApp();

// Initialize Razorpay - get configuration from multiple sources
const getRazorpayConfig = () => {
  const keyId = functions.config().razorpay?.key_id || 
                process.env.RAZORPAY_KEY_ID || 
                'rzp_test_RiMWsU7GNxKFqz'; // Fallback to test key
  
  const keySecret = functions.config().razorpay?.key_secret || 
                   process.env.RAZORPAY_KEY_SECRET || 
                   'cThh9upiy1NtnaHdO6cWr99I'; // Fallback to test secret
  
  console.log('🔧 Razorpay configuration loaded:', {
    keyId: keyId?.substring(0, 15) + '...',
    hasKeySecret: !!keySecret,
    hasConfig: !!functions.config().razorpay,
    fromEnv: !!process.env.RAZORPAY_KEY_ID
  });
  
  return { keyId, keySecret };
};

const { keyId: razorpayKeyId, keySecret: razorpayKeySecret } = getRazorpayConfig();

const razorpay = new Razorpay({
  key_id: razorpayKeyId,
  key_secret: razorpayKeySecret,
});

// Note: Using Firebase Admin SDK with FCM V1 API - no server key needed
// The Admin SDK handles authentication automatically via service account

// Test function to check Firebase Admin SDK
export const testFirebaseAdmin = functions.https.onCall(async (data, context) => {
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
  } catch (error: any) {
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
export const sendPushNotification = functions.https.onCall(async (data, context) => {
  try {
    const { token, title, body, notificationData } = data;

    console.log('📨 SendPushNotification called with:', { token: token?.substring(0, 20) + '...', title, body });

    if (!token) {
      throw new functions.https.HttpsError('invalid-argument', 'FCM token is required');
    }

    if (!title || !body) {
      throw new functions.https.HttpsError('invalid-argument', 'Title and body are required');
    }

    // Create notification payload for Admin SDK
    // Send only data payload - let the app handle notification display manually
    // This prevents FCM from auto-showing system notifications
    const payload = {
      data: {
        ...notificationData,
        title: title,
        body: body,
        timestamp: Date.now().toString(),
      },
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
    } catch (adminError: any) {
      console.error('❌ Admin SDK error:', adminError);
      console.error('❌ Error code:', adminError?.code);
      console.error('❌ Error message:', adminError?.message);

      // Check specific error types
      if (adminError?.code === 'messaging/authentication-error') {
        console.error('❌ Authentication error - Firebase project configuration issue');
      } else if (adminError?.code === 'messaging/invalid-argument') {
        console.error('❌ Invalid argument - payload format issue');
      } else if (adminError?.code === 'messaging/invalid-registration-token') {
        console.error('❌ Invalid FCM token provided');
      } else if (adminError?.code === 'messaging/registration-token-not-registered') {
        console.error('❌ FCM token not registered - user may have uninstalled app');
      }

      throw adminError;
    }
  } catch (error) {
    console.error('❌ Error sending push notification:', error);
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    throw new functions.https.HttpsError('internal', `Failed to send push notification: ${errorMessage}`);
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
    // Send only data payload - let the app handle notification display manually
    const payload = {
      data: {
        ...notificationData,
        title: title,
        body: body,
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
    // Send only data payload - let the app handle notification display manually
    const payload = {
      data: {
        ...notificationData,
        title: title,
        body: body,
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

// Scheduled function to check and expire subscriptions daily
export const checkExpiredSubscriptions = functions.pubsub
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
      const userUpdates: { [userId: string]: any } = {};
      const notifications: Array<{token: string, title: string, body: string, data: any}> = [];

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

          if (userData?.fcmToken) {
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
        } catch (error) {
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
        } catch (error) {
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
          } catch (error) {
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

    } catch (error) {
      console.error('❌ Error in subscription expiration check:', error);
      throw error;
    }
  });

// Function to send expiration warnings (3 days, 1 day, 1 hour before expiry)
export const sendExpirationWarnings = functions.pubsub
  .schedule('0 */6 * * *') // Run every 6 hours
  .timeZone('Asia/Kolkata')
  .onRun(async (context) => {
    try {
      console.log('⚠️ Checking for subscriptions expiring soon...');

      const db = admin.firestore();
      const now = admin.firestore.Timestamp.now();

      // Check for subscriptions expiring in 3 days, 1 day, and 1 hour
      const warningThresholds = [
        { hours: 72, label: '3 days' },    // 3 days
        { hours: 24, label: '1 day' },     // 1 day
        { hours: 1, label: '1 hour' },     // 1 hour
      ];

      const notifications: Array<{token: string, title: string, body: string, data: any}> = [];

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
          if (warningSent) continue;

          try {
            const userDoc = await db.collection('users').doc(userId).get();
            const userData = userDoc.data();

            if (userData?.fcmToken) {
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
          } catch (error) {
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
          } catch (error) {
            console.error('❌ Error sending expiration warning:', error);
          }
        }
      }

      console.log('✅ Expiration warnings check completed');
      return {
        success: true,
        warningsSent: notifications.length,
      };

    } catch (error) {
      console.error('❌ Error in expiration warnings check:', error);
      throw error;
    }

  });

// ==================================
// RAZORPAY PAYMENT FUNCTIONS
// ==================================

// Create Razorpay Order
export const createRazorpayOrder = functions.https.onCall(async (data, context) => {
  try {
    console.log('💳 Creating Razorpay order...');

    // Check if user is authenticated
    if (!context.auth?.uid) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const {
      amount,
      currency = 'INR',
      receipt,
      notes,
      payment_capture = 0 // 0 = manual capture, 1 = auto-capture
    } = data;

    // Validate required parameters
    if (!amount || amount <= 0) {
      throw new functions.https.HttpsError('invalid-argument', 'Valid amount is required');
    }

    // Check if Razorpay is configured
    if (!razorpayKeyId || !razorpayKeySecret) {
      throw new functions.https.HttpsError('failed-precondition', 'Razorpay not configured');
    }

    console.log(`💰 Creating order for ₹${amount / 100} (${amount} paisa)`);

    // Create order using Razorpay Orders API
    const orderOptions = {
      amount: amount, // Amount in paisa
      currency: currency,
      receipt: receipt || `receipt_${Date.now()}`,
      notes: {
        userId: context.auth.uid,
        ...notes,
      },
      payment_capture: payment_capture, // 0 for manual, 1 for automatic
    };

    console.log('📋 Order options:', orderOptions);

    const order = await razorpay.orders.create(orderOptions);

    console.log('✅ Order created successfully:', order.id);

    // Store order details in Firestore for tracking
    const db = admin.firestore();
    await db.collection('razorpay_orders').doc(order.id).set({
      orderId: order.id,
      userId: context.auth.uid,
      amount: order.amount,
      currency: order.currency,
      receipt: order.receipt,
      status: order.status,
      notes: order.notes,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      order: {
        id: order.id,
        entity: order.entity,
        amount: order.amount,
        amount_paid: order.amount_paid,
        amount_due: order.amount_due,
        currency: order.currency,
        receipt: order.receipt,
        offer_id: order.offer_id,
        status: order.status,
        attempts: order.attempts,
        notes: order.notes,
        created_at: order.created_at,
      },
    };
  } catch (error: any) {
    console.error('❌ Error creating Razorpay order:', error);
    console.error('❌ Error type:', typeof error);
    console.error('❌ Error keys:', Object.keys(error || {}));
    console.error('❌ Error message:', error?.message);
    console.error('❌ Error code:', error?.code);
    console.error('❌ Error statusCode:', error?.statusCode);
    console.error('❌ Error description:', error?.description);
    console.error('❌ Full error object:', JSON.stringify(error, null, 2));

    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    // Provide more detailed error message
    const errorMessage = error?.message || error?.description || error?.error?.description || 'Unknown error';
    throw new functions.https.HttpsError('internal', `Failed to create order: ${errorMessage}`);
  }
});

// Razorpay Webhook Handler for Auto-capture
export const razorpayWebhook = functions.https.onRequest(async (req, res) => {
  try {
    console.log('🔗 Razorpay webhook received');

    // Only accept POST requests
    if (req.method !== 'POST') {
      console.log('❌ Invalid request method:', req.method);
      res.status(405).send('Method not allowed');
      return;
    }

    // Verify webhook signature
    const secret = functions.config().razorpay?.webhook_secret || process.env.RAZORPAY_WEBHOOK_SECRET;

    if (!secret) {
      console.log('❌ Webhook secret not configured');
      res.status(500).send('Webhook secret not configured');
      return;
    }

    const expectedSignature = req.headers['x-razorpay-signature'] as string;
    const body = JSON.stringify(req.body);

    const crypto = require('crypto');
    const generatedSignature = crypto
      .createHmac('sha256', secret)
      .update(body)
      .digest('hex');

    if (generatedSignature !== expectedSignature) {
      console.log('❌ Invalid webhook signature');
      res.status(400).send('Invalid signature');
      return;
    }

    console.log('✅ Webhook signature verified');

    const event = req.body.event;
    const paymentEntity = req.body.payload?.payment?.entity;

    if (!paymentEntity) {
      console.log('❌ No payment entity in webhook');
      res.status(400).send('Invalid webhook payload');
      return;
    }

    console.log(`🎣 Webhook event: ${event}`);
    console.log(`💳 Payment ID: ${paymentEntity.id}`);

    const db = admin.firestore();

    // Update payment status in Firestore
    const paymentRef = db.collection('razorpay_payments').doc(paymentEntity.id);
    await paymentRef.set({
      paymentId: paymentEntity.id,
      orderId: paymentEntity.order_id,
      amount: paymentEntity.amount,
      currency: paymentEntity.currency,
      status: paymentEntity.status,
      method: paymentEntity.method,
      captured: paymentEntity.captured,
      description: paymentEntity.description,
      email: paymentEntity.email,
      contact: paymentEntity.contact,
      notes: paymentEntity.notes,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      webhookEvent: event,
      webhookReceivedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    // Handle different webhook events
    switch (event) {
      case 'payment.authorized':
        console.log('🔐 Payment authorized - waiting for capture event');
        // In production, Razorpay auto-captures payments, so we wait for payment.captured event
        break;

      case 'payment.captured':
        console.log('✅ Payment captured successfully');

        // Update payment record with capture details
        await paymentRef.update({
          captured: true,
          capturedAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Mark order as paid
        if (paymentEntity.order_id) {
          await db.collection('razorpay_orders').doc(paymentEntity.order_id).update({
            status: 'paid',
            paymentId: paymentEntity.id,
            capturedAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }

        // Process subscription activation
        await processSubscriptionActivation(paymentEntity);
        break;

      case 'payment.failed':
        console.log('❌ Payment failed');
        // Handle failed payment - could notify user
        break;

      default:
        console.log(`⚠️ Unhandled webhook event: ${event}`);
    }

    res.status(200).send('Webhook processed successfully');

  } catch (error: any) {
    console.error('❌ Error processing webhook:', error);
    res.status(500).send(`Internal server error: ${error.message}`);
  }
});

// Verify Razorpay Payment Signature
export const verifyRazorpayPayment = functions.https.onCall(async (data, context) => {
  try {
    console.log('🔍 Verifying Razorpay payment signature...');

    if (!context.auth?.uid) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { paymentId, orderId, signature } = data;

    if (!paymentId || !orderId || !signature) {
      throw new functions.https.HttpsError('invalid-argument', 'paymentId, orderId, and signature are required');
    }

    // Get payment details from Firestore
    const db = admin.firestore();
    const paymentDoc = await db.collection('razorpay_payments').doc(paymentId).get();

    if (!paymentDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Payment record not found');
    }

    const paymentData = paymentDoc.data();
    if (!paymentData) {
      throw new functions.https.HttpsError('not-found', 'Payment data not found');
    }

    // Generate expected signature for verification
    const sign = `${orderId}|${paymentId}`;
    const crypto = require('crypto');
    const expectedSignature = crypto
      .createHmac('sha256', razorpayKeySecret)
      .update(sign)
      .digest('hex');

    const isValid = expectedSignature === signature;

    console.log(`🔐 Signature verification: ${isValid ? 'VALID' : 'INVALID'}`);

    if (isValid) {
      // Update payment verification status
      await paymentDoc.ref.update({
        signatureVerified: true,
        signatureVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    return {
      success: true,
      verified: isValid,
      paymentId,
      orderId,
    };

  } catch (error: any) {
    console.error('❌ Error verifying payment:', error);

    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    throw new functions.https.HttpsError('internal', `Failed to verify payment: ${error.message}`);
  }
});

// Helper function to create Platinum welcome content
async function createPlatinumWelcomeContent(userId: string) {
  try {
    console.log('🎉 Creating Platinum welcome content for user:', userId);

    const db = admin.firestore();

    // Get user data to find candidate information
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      console.log('❌ User document not found for Platinum content creation');
      return;
    }

    const userData = userDoc.data();
    if (!userData) {
      console.log('❌ User data is empty');
      return;
    }

    // Get candidate data
    const candidateQuery = await db.collection('candidates').where('userId', '==', userId).limit(1).get();
    if (candidateQuery.empty) {
      console.log('❌ No candidate found for user:', userId);
      return;
    }

    const candidateDoc = candidateQuery.docs[0];
    const candidateData = candidateDoc.data();

    // Extract location information
    const location = userData.location || {};
    const electionAreas = userData.electionAreas || [];

    if (!location.stateId || !location.districtId || electionAreas.length === 0) {
      console.log('❌ Missing location or election area data for user:', userId);
      return;
    }

    const primaryArea = electionAreas[0];
    const stateId = location.stateId;
    const districtId = location.districtId;
    const bodyId = primaryArea.bodyId;
    const wardId = primaryArea.wardId;

    if (!wardId) {
      console.log('❌ Missing wardId for candidate');
      return;
    }

    // Create Platinum highlight
    const highlightId = `platinum_hl_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const locationKey = `${districtId}_${bodyId}_$wardId`;

    const highlightData = {
      id: highlightId,
      candidateId: candidateDoc.id,
      location: {
        stateId: stateId,
        districtId: districtId,
        bodyId: bodyId,
        wardId: wardId,
      },
      locationKey: locationKey,
      package: 'platinum',
      placement: ['top_banner'],
      priority: 10, // High priority for Platinum
      startDate: new Date(),
      endDate: new Date(Date.now() + (30 * 24 * 60 * 60 * 1000)), // 30 days
      active: true,
      exclusive: true,
      rotation: false,
      views: 0,
      clicks: 0,
      imageUrl: candidateData.photo || null,
      candidateName: candidateData.fullName || 'Candidate',
      party: candidateData.party || '',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      bannerStyle: 'premium',
      callToAction: 'View Profile',
      priorityLevel: 'urgent',
      customMessage: null,
    };

    // Save highlight to hierarchical structure
    await db
      .collection('states')
      .doc(stateId)
      .collection('districts')
      .doc(districtId)
      .collection('bodies')
      .doc(bodyId)
      .collection('wards')
      .doc(wardId)
      .collection('highlights')
      .doc(highlightId)
      .set(highlightData);

    console.log('✅ Platinum highlight created successfully:', highlightId);

    // Create welcome push feed item
    const feedItemData = {
      id: `feed_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      candidateId: candidateDoc.id,
      wardId: wardId,
      title: '🎉 Platinum Plan Activated!',
      message: `${candidateData.fullName || 'The candidate'} is now a Platinum member with maximum visibility!`,
      imageUrl: candidateData.photo || null,
      type: 'announcement',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: new Date(Date.now() + (7 * 24 * 60 * 60 * 1000)), // 7 days
    };

    await db.collection('push_feed').add(feedItemData);
    console.log('✅ Platinum welcome feed item created');

  } catch (error: any) {
    console.error('❌ Error creating Platinum welcome content:', error);
  }
}

// Helper function to create highlight banner for highlight plans
async function createHighlightBanner(userId: string, planId: string, electionType: string, validityDays: number, paymentEntity: any) {
  try {
    console.log('🎯 Creating highlight banner for user:', userId, 'plan:', planId);

    const db = admin.firestore();

    // Get user data to find candidate information
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      console.log('❌ User document not found for highlight banner creation');
      return;
    }

    const userData = userDoc.data();
    if (!userData) {
      console.log('❌ User data is empty');
      return;
    }

    // Get candidate data
    const candidateQuery = await db.collection('candidates').where('userId', '==', userId).limit(1).get();
    if (candidateQuery.empty) {
      console.log('❌ No candidate found for user:', userId);
      return;
    }

    const candidateDoc = candidateQuery.docs[0];
    const candidateData = candidateDoc.data();

    // Extract location information
    const location = userData.location || {};
    const electionAreas = userData.electionAreas || [];

    if (!location.stateId || !location.districtId || electionAreas.length === 0) {
      console.log('❌ Missing location or election area data for user:', userId);
      return;
    }

    const primaryArea = electionAreas[0];
    const stateId = location.stateId;
    const districtId = location.districtId;
    const bodyId = primaryArea.bodyId;
    const wardId = primaryArea.wardId;

    if (!wardId) {
      console.log('❌ Missing wardId for candidate');
      return;
    }

    // Check if candidate already has an existing highlight in their ward
    const existingHighlightsQuery = await db
      .collection('states')
      .doc(stateId)
      .collection('districts')
      .doc(districtId)
      .collection('bodies')
      .doc(bodyId)
      .collection('wards')
      .doc(wardId)
      .collection('highlights')
      .where('candidateId', '==', candidateDoc.id)
      .limit(10)
      .get();

    let highlightId: string;
    let isUpdate = false;

    if (!existingHighlightsQuery.empty) {
      // Update existing highlight
      const existingHighlight = existingHighlightsQuery.docs[0];
      highlightId = existingHighlight.id;
      isUpdate = true;

      console.log('🔄 Found existing highlight, updating:', highlightId);

      // Calculate new end date - extend from current end date if it's in the future, otherwise from now
      const currentData = existingHighlight.data();
      const currentEndDate = currentData.endDate?.toDate() || new Date();
      const now = new Date();
      const baseDate = currentEndDate > now ? currentEndDate : now;
      const newEndDate = new Date(baseDate.getTime() + (validityDays * 24 * 60 * 60 * 1000));

      console.log('📅 Date calculation for highlight extension:');
      console.log('  Current end date:', currentEndDate);
      console.log('  Now:', now);
      console.log('  Base date (max of current end or now):', baseDate);
      console.log('  Validity days:', validityDays);
      console.log('  New end date:', newEndDate);

      // Update existing highlight
      await db
        .collection('states')
        .doc(stateId)
        .collection('districts')
        .doc(districtId)
        .collection('bodies')
        .doc(bodyId)
        .collection('wards')
        .doc(wardId)
        .collection('highlights')
        .doc(highlightId)
        .update({
          endDate: admin.firestore.Timestamp.fromDate(newEndDate),
          expiresAt: admin.firestore.Timestamp.fromDate(newEndDate), // Add expiresAt field for app compatibility
          active: true,
          status: 'active',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          bannerStyle: 'premium',
          callToAction: 'View Profile',
          priorityLevel: 'normal',
          customMessage: null,
        });

      console.log('✅ Existing highlight updated successfully');
    } else {
      // Create new highlight
      highlightId = `highlight_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      const locationKey = `${districtId}_${bodyId}_$wardId`;

      console.log('🆕 Creating new highlight banner');

      const endDate = new Date(Date.now() + (validityDays * 24 * 60 * 60 * 1000));

      const highlightData = {
        id: highlightId,
        candidateId: candidateDoc.id,
        location: {
          stateId: stateId,
          districtId: districtId,
          bodyId: bodyId,
          wardId: wardId,
        },
        locationKey: locationKey,
        package: 'highlight',
        placement: ['top_banner'],
        priority: 5, // Normal priority for highlight plan
        startDate: new Date(),
        endDate: admin.firestore.Timestamp.fromDate(endDate),
        expiresAt: admin.firestore.Timestamp.fromDate(endDate), // Add expiresAt field for app compatibility
        active: true,
        exclusive: false,
        rotation: true,
        views: 0,
        clicks: 0,
        imageUrl: candidateData.photo || null,
        candidateName: candidateData.fullName || 'Candidate',
        party: candidateData.party || '',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        bannerStyle: 'premium',
        callToAction: 'View Profile',
        priorityLevel: 'normal',
        customMessage: null,
      };

      // Save highlight to hierarchical structure
      await db
        .collection('states')
        .doc(stateId)
        .collection('districts')
        .doc(districtId)
        .collection('bodies')
        .doc(bodyId)
        .collection('wards')
        .doc(wardId)
        .collection('highlights')
        .doc(highlightId)
        .set(highlightData);

      console.log('✅ New highlight banner created successfully:', highlightId);
    }

    // Create welcome push feed item only for new highlights
    if (!isUpdate) {
      const feedItemData = {
        id: `feed_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
        candidateId: candidateDoc.id,
        wardId: wardId,
        title: '🎉 Highlight Plan Activated!',
        message: `${candidateData.fullName || 'The candidate'} is now visible in highlight banners!`,
        imageUrl: candidateData.photo || null,
        type: 'announcement',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: new Date(Date.now() + (7 * 24 * 60 * 60 * 1000)), // 7 days
      };

      await db.collection('push_feed').add(feedItemData);
      console.log('✅ Highlight welcome feed item created');
    }

  } catch (error: any) {
    console.error('❌ Error creating highlight banner:', error);
  }
}

// Helper function to process subscription activation
async function processSubscriptionActivation(paymentEntity: any) {
  try {
    console.log('🎯 Processing subscription activation for payment:', paymentEntity.id);

    const db = admin.firestore();
    const notes = paymentEntity.notes || {};

    // Extract plan details from payment notes
    const planId = notes.planId || notes.plan_id;
    const userId = notes.userId || notes.user_id;
    const electionType = notes.electionType || notes.election_type;
    const validityDays = parseInt(notes.validityDays || notes.validity_days || '30');

    if (!planId || !userId) {
      console.log('⚠️ Missing planId or userId in payment notes, skipping subscription activation');
      return;
    }

    console.log(`📋 Activating subscription: plan=${planId}, user=${userId}, election=${electionType}, days=${validityDays}`);

    // Calculate subscription end date
    const startDate = new Date();
    const endDate = new Date(startDate.getTime() + (validityDays * 24 * 60 * 60 * 1000));

    // Create subscription record
    const subscriptionData = {
      subscriptionId: `sub_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      userId: userId,
      planId: planId,
      planType: planId.includes('highlight') ? 'highlight' :
                planId.includes('carousel') ? 'carousel' : 'candidate',
      electionType: electionType,
      validityDays: validityDays,
      amountPaid: paymentEntity.amount / 100, // Convert paisa to rupees
      purchasedAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: admin.firestore.Timestamp.fromDate(endDate),
      isActive: true,
      paymentId: paymentEntity.id,
      orderId: paymentEntity.order_id,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await db.collection('subscriptions').add(subscriptionData);
    console.log('✅ Subscription record created');

    // Update user premium status
    let userUpdate: any = {};

    if (planId.includes('highlight')) {
      userUpdate = {
        highlightPlanId: planId,
        highlightPlanExpiresAt: admin.firestore.Timestamp.fromDate(endDate),
      };
    } else if (planId.includes('carousel')) {
      userUpdate = {
        carouselPlanId: planId,
        carouselPlanExpiresAt: admin.firestore.Timestamp.fromDate(endDate),
      };
    } else {
      // Candidate plan (Gold/Platinum)
      userUpdate = {
        premium: true,
        subscriptionPlanId: planId,
        subscriptionExpiresAt: admin.firestore.Timestamp.fromDate(endDate),
      };
    }

    userUpdate.updatedAt = admin.firestore.FieldValue.serverTimestamp();

    await db.collection('users').doc(userId).update(userUpdate);
    console.log('✅ User premium status updated');

    // Trigger additional setup logic (highlights, etc.) based on plan type
    if (planId === 'platinum_plan') {
      console.log('💎 Platinum plan purchased - triggering welcome content creation');
      await createPlatinumWelcomeContent(userId);
    } else if (planId.includes('highlight')) {
      console.log('🎯 Highlight plan purchased - triggering banner creation');
      await createHighlightBanner(userId, planId, electionType, validityDays, paymentEntity);
    }

    console.log('🎉 Subscription activation completed successfully');

  } catch (error: any) {
    console.error('❌ Error processing subscription activation:', error);
    // Don't throw error here as webhook should still succeed
  }
}
