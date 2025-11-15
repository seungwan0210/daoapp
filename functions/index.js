const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// === 헬퍼: KST 기준 월별 컬렉션 이름 ===
function getMonthlyRankingCollection(date = new Date()) {
  const kst = new Date(date.getTime() + 9 * 60 * 60 * 1000); // UTC → KST
  const year = kst.getUTCFullYear();
  const month = String(kst.getUTCMonth() + 1).padStart(2, '0');
  return `checkout_practice_rankings_${year}_${month}`;
}

// === 1. 프로필 인증 완료 시 커스텀 클레임 설정 ===
exports.setHasProfile = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', '로그인이 필요합니다.');
  }

  const uid = context.auth.uid;

  try {
    await admin.auth().setCustomUserClaims(uid, { hasProfile: true });
    return { success: true, message: '프로필 인증 완료' };
  } catch (error) {
    console.error('Error setting custom claim:', error);
    throw new functions.https.HttpsError('internal', '설정 실패');
  }
});

// === 2. 온라인 유저 정리 (5분마다) ===
exports.cleanupOnlineUsers = functions.pubsub
  .schedule('every 5 minutes')
  .onRun(async (context) => {
    try {
      const cutoff = admin.firestore.Timestamp.fromDate(
        new Date(Date.now() - 60 * 1000) // 1분 이상 지난 유저 정리
      );

      const snapshot = await admin.firestore()
        .collection('online_users')
        .where('lastSeen', '<', cutoff)
        .get();

      if (snapshot.empty) {
        console.log('No stale online users to clean up.');
        return null;
      }

      const batch = admin.firestore().batch();
      snapshot.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
      console.log(`Cleaned up ${snapshot.size} stale online users.`);
      return null;
    } catch (error) {
      console.error('Cleanup error:', error);
      return null;
    }
  });

// === 3. 체크아웃 연습 기록 → 월별 실시간 랭킹 업데이트 ===
exports.updateMonthlyCheckoutRanking = functions.firestore
  .document('users/{userId}/checkout_practice/{recordId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const uid = context.params.userId;

    try {
      const userDoc = await admin.firestore().collection('users').doc(uid).get();
      if (!userDoc.exists) return null;

      const userData = userDoc.data() || {};
      const koreanName = userData.koreanName || '이름 없음';

      const collectionName = getMonthlyRankingCollection(); // 현재 월 컬렉션
      const rankingRef = admin.firestore().collection(collectionName).doc(uid);
      const rankingSnap = await rankingRef.get();

      let shouldUpdate = false;
      const newBest = {
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
        console.log(`[월별] ${collectionName} - ${koreanName} 랭킹 갱신`);
      }

      return null;
    } catch (error) {
      console.error('월별 랭킹 업데이트 실패:', error);
      return null;
    }
  });

// === 4. 매월 1일 00:05 KST → 전월 1~12위 배지 자동 부여 (월별 갱신형) ===
const BADGE_MAP = [
  null,            // 0번 인덱스 사용 안 함
  'pro',           // 1위
  'emerald',       // 2위
  'diamond',       // 3위
  'platinum1',     // 4위
  'platinum2',     // 5위
  'gold1',         // 6위
  'gold2',         // 7위
  'silver1',       // 8위
  'silver2',       // 9위
  'bronze1',       // 10위
  'bronze2',       // 11위
  'bronze3',       // 12위
];

exports.grantMonthlyBadges = functions.pubsub
  .schedule('5 0 1 * *') // 매월 1일 00:05
  .timeZone('Asia/Seoul')
  .onRun(async (context) => {
    const now = new Date();
    const lastMonthDate = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    const collectionName = getMonthlyRankingCollection(lastMonthDate);

    try {
      const snapshot = await admin.firestore()
        .collection(collectionName)
        .orderBy('elapsedSeconds')
        .limit(12)
        .get();

      if (snapshot.empty) {
        console.log(`[${collectionName}] 랭킹 데이터 없음 → 배지 부여 없음`);
        return null;
      }

      const batch = admin.firestore().batch();
      const year = lastMonthDate.getFullYear();
      const month = String(lastMonthDate.getMonth() + 1).padStart(2, '0');
      const currentBadgePrefix = `monthly_${year}_${month}`;

      // === 1. 모든 유저의 이전 배지 삭제 ===
      const usersSnapshot = await admin.firestore().collection('users').get();
      usersSnapshot.docs.forEach((userDoc) => {
        const userRef = userDoc.ref;
        const data = userDoc.data();
        const badges = data.badges || {};

        // 이전 달 배지 삭제
        Object.keys(badges).forEach(key => {
          if (key.startsWith('monthly_') && !key.startsWith(currentBadgePrefix)) {
            batch.set(userRef, { [`badges.${key}`]: admin.firestore.FieldValue.delete() }, { merge: true });
          }
        });

        // lastMonthlyBadge도 이번 달이 아니면 삭제
        if (data.lastMonthlyBadge && !data.lastMonthlyBadge.includes(`${year}년 ${month}월`)) {
          batch.set(userRef, { lastMonthlyBadge: admin.firestore.FieldValue.delete() }, { merge: true });
        }
      });

      // === 2. 이번 달 1~12위 배지 부여 ===
      snapshot.docs.forEach((doc, index) => {
        const rank = index + 1;
        const uid = doc.id;
        const badgeKey = BADGE_MAP[rank];

        if (badgeKey) {
          const userRef = admin.firestore().collection('users').doc(uid);
          batch.set(
            userRef,
            {
              [`badges.${currentBadgePrefix}_${badgeKey}`]: true,
              lastMonthlyBadge: `${year}년 ${month}월 ${rank}위`,
            },
            { merge: true },
          );
        }
      });

      await batch.commit();
      console.log(`[${collectionName}] 1~12위 배지 ${snapshot.size}개 부여 완료 (이전 배지 삭제)`);
      return null;
    } catch (error) {
      console.error('월간 배지 부여 실패:', error);
      return null;
    }
  });