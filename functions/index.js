// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// 기존 함수 (이름 통일: setHasProfile)
exports.setHasProfile = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', '로그인이 필요합니다.');
  }

  const uid = context.auth.uid;

  try {
    await admin.auth().setCustomUserClaims(uid, {
      hasProfile: true,
    });

    return { success: true, message: '프로필 인증 완료' };
  } catch (error) {
    console.error('Error setting custom claim:', error);
    throw new functions.https.HttpsError('internal', '설정 실패');
  }
});

// 신규: online_users 정리
exports.cleanupOnlineUsers = functions.pubsub.schedule('every 5 minutes').onRun(async (context) => {
  try {
    const cutoff = admin.firestore.Timestamp.fromDate(new Date(Date.now() - 60 * 1000));
    const snapshot = await admin.firestore()
      .collection('online_users')
      .where('lastSeen', '<', cutoff)
      .get();

    if (snapshot.empty) {
      console.log('No stale online users to clean up.');
      return null;
    }

    const batch = admin.firestore().batch();
    snapshot.docs.forEach(doc => batch.delete(doc.ref));
    await batch.commit();
    console.log(`Cleaned up ${snapshot.size} stale online users.`);
    return null;
  } catch (error) {
    console.error('Cleanup error:', error);
    return null;
  }
});