// Firebase Messaging Service Worker
importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-messaging.js");

const firebaseConfig = {
  apiKey: 'AIzaSyDst-RA1ennLcjLf2dHABau2GFLR2W2IM0',
  authDomain: 'janmat-8e831.firebaseapp.com',
  projectId: 'janmat-8e831',
  storageBucket: 'janmat-8e831.firebasestorage.app',
  messagingSenderId: '231534632940',
  appId: '1:231534632940:web:bdb07b3ca9d1ffcd57aac9'
};

firebase.initializeApp(firebaseConfig);

// Initialize Firebase Messaging
const messaging = firebase.messaging();

// Background message handler
messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);

  const notificationTitle = 'Janmat Notification';
  const notificationOptions = {
    body: payload.data?.body || 'You have a new notification',
    icon: '/favicon.png'
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});
