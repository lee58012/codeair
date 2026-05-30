// CodeAir 웹 FCM 백그라운드 메시지 서비스 워커
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyCtwcDYJhFpt3ruvch_IYwUSzv3-prOxgk',
  appId: '1:1063160680312:web:b538eafeb5bfa5efd9c28d',
  messagingSenderId: '1063160680312',
  projectId: 'codeair-598fd',
  authDomain: 'codeair-598fd.firebaseapp.com',
  storageBucket: 'codeair-598fd.firebasestorage.app',
});

const messaging = firebase.messaging();

// 백그라운드 메시지 → 시스템 알림 표시
messaging.onBackgroundMessage((payload) => {
  const title = (payload.notification && payload.notification.title) || 'CodeAir 경보';
  const options = {
    body: (payload.notification && payload.notification.body) || '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
  };
  self.registration.showNotification(title, options);
});
