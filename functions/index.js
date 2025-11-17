const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// ====================== 헬퍼 함수 ======================
function getMonthlyRankingCollection(date = new Date()) {
  const kst = new Date(date.getTime() + 9 * 60 * 60 * 1000);
  const year = kst.getUTCFullYear();
  const month = String(kst.getUTCMonth() + 1).padStart(2, '0');
  return `checkout_practice_rankings_${year}_${month}`;
}

function calculateCheckoutScore(data) {
  const elapsedSeconds = typeof data.elapsedSeconds === 'number' ? data.elapsedSeconds : 0;
  const optimizationRate = typeof data.optimizationRate === 'number' ? data.optimizationRate : 0;
  const routeMatchRate = typeof data.routeMatchRate === 'number' ? data.routeMatchRate : 0;

  const MAX_TIME_SECONDS = 600;
  const timeScore = Math.max(0, 1 - elapsedSeconds / MAX_TIME_SECONDS);
  const finalScoreRatio = timeScore * 0.4 + optimizationRate * 0.3 + routeMatchRate * 0.3;
  const score = Math.round(finalScoreRatio * 10000);

  return { score, timeScore, optimizationRate, routeMatchRate };
}

const BADGE_MAP = [
  null, 'pro', 'emerald', 'diamond',
  'platinum1', 'platinum2', 'gold1', 'gold2',
  'silver1', 'silver2', 'bronze1', 'bronze2', 'bronze3'
];

// ====================== 1. 프로필 인증 Custom Claims ======================
exports.setHasProfile = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', '로그인 필요');
  await admin.auth().setCustomUserClaims(context.auth.uid, { hasProfile: true });
  return { success: true };
});

// ====================== 2. 온라인 유저 정리 (5분마다) ======================
exports.cleanupOnlineUsers = functions.pubsub
  .schedule('every 5 minutes')
  .onRun(async () => {
    const cutoff = admin.firestore.Timestamp.fromDate(new Date(Date.now() - 60 * 1000));
    const snapshot = await admin.firestore()
      .collection('online_users')
      .where('lastSeen', '<', cutoff)
      .get();

    if (snapshot.empty) return null;
    const batch = admin.firestore().batch();
    snapshot.docs.forEach(doc => batch.delete(doc.ref));
    await batch.commit();
    return null;
  });

// ====================== 3. 체크아웃 연습 기록 → 실시간 월별 랭킹 업데이트 ======================
exports.updateMonthlyCheckoutRanking = functions.firestore
  .document('users/{userId}/checkout_practice/{recordId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const uid = context.params.userId;

    try {
      const userDoc = await admin.firestore().collection('users').doc(uid).get();
      if (!userDoc.exists) return null;
      const koreanName = userDoc.data()?.koreanName || '이름 없음';

      const collectionName = getMonthlyRankingCollection();
      const rankingRef = admin.firestore().collection(collectionName).doc(uid);

      const { score } = calculateCheckoutScore(data);
      const newBest = {
        uid,
        koreanName,
        score,
        elapsedSeconds: data.elapsedSeconds || 0,
        successRate: data.successRate || 0,
        avgDarts: data.avgDarts || 0,
        optimizationRate: data.optimizationRate || 0,
        routeMatchRate: data.routeMatchRate || 0,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      const snapRanking = await rankingRef.get();
      if (!snapRanking.exists || snapRanking.data().score < score) {
        await rankingRef.set(newBest, { merge: true });
        console.log(`[랭킹 갱신] ${koreanName} → ${score}점`);
      }
    } catch (e) {
      console.error('랭킹 업데이트 실패:', e);
    }
    return null;
  });

// ====================== 4. 매월 1일 00:05 → 월간 배지 완전 리셋 + 새 1~12위 부여 (비용 폭탄 0원) ======================
exports.grantMonthlyBadges = functions.pubsub
  .schedule('5 0 1 * *')
  .timeZone('Asia/Seoul')
  .onRun(async () => {
    try {
      const now = new Date();
      const lastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
      const collectionName = getMonthlyRankingCollection(lastMonth);

      const top12 = await admin.firestore()
        .collection(collectionName)
        .orderBy('score', 'desc')
        .orderBy('elapsedSeconds', 'asc')
        .limit(12)
        .get();

      if (top12.empty) {
        console.log(`[${collectionName}] 랭킹 없음`);
        return null;
      }

      const year = lastMonth.getFullYear();
      const month = String(lastMonth.getMonth() + 1).padStart(2, '0');
      const currentPrefix = `monthly_${year}_${month}`;

      const batch = admin.firestore().batch();

      // 이번 달 상위 12명에게만 새 배지 부여
      top12.docs.forEach((doc, i) => {
        const rank = i + 1;
        const badgeKey = BADGE_MAP[rank];
        if (badgeKey) {
          const userRef = admin.firestore().collection('users').doc(doc.id);
          batch.set(userRef, {
            [`badges.${currentPrefix}_${badgeKey}`]: true,
            lastMonthlyBadge: `${year}년 ${month}월 ${rank}위`,
          }, { merge: true });
        }
      });

      await batch.commit();
      console.log(`월간 배지 리셋 & 부여 완료: ${year}-${month} (${top12.size}명)`);
      return null;
    } catch (e) {
      console.error('월간 배지 작업 실패:', e);
      throw e;
    }
  });