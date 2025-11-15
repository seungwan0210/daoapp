const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// 1. 프로필 인증 완료 시 커스텀 클레임 설정
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

// 2. 온라인 유저 정리 (5분마다)
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

// 3. 체크아웃 연습 기록 → 실시간 랭킹 자동 업데이트
exports.updateCheckoutRanking = functions.firestore
  .document('users/{userId}/checkout_practice/{recordId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const uid = context.params.userId;

    try {
      const userDoc = await admin.firestore().collection('users').doc(uid).get();
      if (!userDoc.exists) {
        console.log(`User ${uid} not found, skipping ranking update.`);
        return null;
      }

      const koreanName = userDoc.data()?.koreanName || '이름 없음';

      const rankingRef = admin.firestore().collection('checkout_practice_rankings').doc(uid);
      const rankingSnap = await rankingRef.get();

      let shouldUpdate = false;
      let newBest = {
        uid,
        koreanName,
        elapsedSeconds: data.elapsedSeconds,
        successRate: data.successRate,
        avgDarts: data.avgDarts,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      if (!rankingSnap.exists) {
        shouldUpdate = true;
      } else {
        const old = rankingSnap.data();
        if (
          data.elapsedSeconds < old.elapsedSeconds ||
          (data.elapsedSeconds === old.elapsedSeconds && data.successRate > old.successRate)
        ) {
          shouldUpdate = true;
        }
      }

      if (shouldUpdate) {
        await rankingRef.set(newBest, { merge: true });
        console.log(`Updated ranking for ${koreanName} (${uid})`);
      } else {
        console.log(`No improvement for ${koreanName}, skipping update.`);
      }

      return null;
    } catch (error) {
      console.error('Error updating checkout ranking:', error);
      return null;
    }
  });