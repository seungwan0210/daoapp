const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// === 헬퍼: KST 기준 월별 컬렉션 이름 ===
function getMonthlyRankingCollection(date = new Date()) {
  const kst = new Date(date.getTime() + 9 * 60 * 60 * 1000);
  const year = kst.getUTCFullYear();
  const month = String(kst.getUTCMonth() + 1).padStart(2, '0');
  return `checkout_practice_rankings_${year}_${month}`;
}

// === 헬퍼: 체크아웃 연습 점수 계산 ===
// data 에서:
// - elapsedSeconds: 숫자 (필수)
// - optimizationRate: 0~1 (선택, 없으면 0)
// - routeMatchRate: 0~1 (선택, 없으면 0)
function calculateCheckoutScore(data) {
  const elapsedSeconds =
    typeof data.elapsedSeconds === 'number' ? data.elapsedSeconds : 0;

  const optimizationRate =
    typeof data.optimizationRate === 'number' ? data.optimizationRate : 0;

  const routeMatchRate =
    typeof data.routeMatchRate === 'number' ? data.routeMatchRate : 0;

  // 시간 점수 (0~1, 높을수록 좋음)
  // 0초일 때 1.0, 600초(10분) 이상이면 0
  const MAX_TIME_SECONDS = 600;
  const timeScore = Math.max(
    0,
    1 - elapsedSeconds / MAX_TIME_SECONDS
  );

  // 최종 점수: 시간 40% + 최적다트율 30% + 정석루트율 30%
  const finalScoreRatio =
    timeScore * 0.4 +
    optimizationRate * 0.3 +
    routeMatchRate * 0.3;

  // Firestore에는 0~10000 정수로 저장
  const score = Math.round(finalScoreRatio * 10000);

  return {
    score,
    timeScore,
    optimizationRate,
    routeMatchRate,
  };
}

// === 1. 프로필 인증 완료 시 Custom Claims 설정 ===
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
  .onRun(async () => {
    try {
      const cutoff = admin.firestore.Timestamp.fromDate(
        new Date(Date.now() - 60 * 1000)
      );

      const snapshot = await admin.firestore()
        .collection('online_users')
        .where('lastSeen', '<', cutoff)
        .get();

      if (snapshot.empty) return null;

      const batch = admin.firestore().batch();
      snapshot.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();

      console.log(`Cleaned ${snapshot.size} inactive users.`);
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

      const collectionName = getMonthlyRankingCollection();
      const rankingRef = admin.firestore().collection(collectionName).doc(uid);
      const rankingSnap = await rankingRef.get();

      // 새 기록의 점수 계산
      const {
        score,
        timeScore,
        optimizationRate,
        routeMatchRate,
      } = calculateCheckoutScore(data);

      const successRate =
        typeof data.successRate === 'number' ? data.successRate : 0;
      const avgDarts =
        typeof data.avgDarts === 'number' ? data.avgDarts : 0;

      let shouldUpdate = false;
      const newBest = {
        uid,
        koreanName,
        // 랭킹 기준 필드
        score,             // 최종 점수 (0~10000)
        elapsedSeconds: data.elapsedSeconds || 0,
        successRate,
        avgDarts,
        // 참고용 세부 지표
        timeScore,
        optimizationRate,
        routeMatchRate,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      if (!rankingSnap.exists) {
        shouldUpdate = true;
      } else {
        const old = rankingSnap.data();
        const oldScore =
          typeof old.score === 'number' ? old.score : 0;
        const oldElapsed =
          typeof old.elapsedSeconds === 'number' ? old.elapsedSeconds : Number.MAX_SAFE_INTEGER;

        // 1) 점수가 더 크면 갱신
        // 2) 점수가 같으면 시간이 더 빠르면 갱신
        if (
          score > oldScore ||
          (score === oldScore && newBest.elapsedSeconds < oldElapsed)
        ) {
          shouldUpdate = true;
        }
      }

      if (shouldUpdate) {
        await rankingRef.set(newBest, { merge: true });
        console.log(`[월별랭킹 갱신] ${collectionName} - ${koreanName} (score: ${score})`);
      }

      return null;
    } catch (error) {
      console.error('월별 랭킹 업데이트 실패:', error);
      return null;
    }
  });

// === 4. 매월 1일 00:05 → 전월 랭킹 1~12위 월간 배지 자동 부여 ===
const BADGE_MAP = [
  null,
  'pro',       // 1위
  'emerald',   // 2위
  'diamond',   // 3위
  'platinum1', // 4위
  'platinum2', // 5위
  'gold1',     // 6위
  'gold2',     // 7위
  'silver1',   // 8위
  'silver2',   // 9위
  'bronze1',   // 10위
  'bronze2',   // 11위
  'bronze3',   // 12위
];

exports.grantMonthlyBadges = functions.pubsub
  .schedule('5 0 1 * *')
  .timeZone('Asia/Seoul')
  .onRun(async () => {
    const now = new Date();
    const lastMonthDate = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    const collectionName = getMonthlyRankingCollection(lastMonthDate);

    try {
      const snapshot = await admin.firestore()
        .collection(collectionName)
        // 점수 높은 순으로 상위 12명
        .orderBy('score', 'desc')
        .limit(12)
        .get();

      if (snapshot.empty) {
        console.log(`${collectionName} 데이터 없음`);
        return null;
      }

      const batch = admin.firestore().batch();
      const year = lastMonthDate.getFullYear();
      const month = String(lastMonthDate.getMonth() + 1).padStart(2, '0');
      const currentBadgePrefix = `monthly_${year}_${month}`;

      // === 기존 monthly 배지 모두 지우기 ===
      const usersSnapshot = await admin.firestore().collection('users').get();

      usersSnapshot.docs.forEach((userDoc) => {
        const userRef = userDoc.ref;
        const data = userDoc.data();
        const badges = data.badges || {};

        Object.keys(badges).forEach((key) => {
          if (key.startsWith('monthly_')) {
            const prefix = key.split('_').slice(0, 3).join('_');
            if (prefix !== currentBadgePrefix) {
              batch.set(
                userRef,
                { [`badges.${key}`]: admin.firestore.FieldValue.delete() },
                { merge: true }
              );
            }
          }
        });

        batch.set(
          userRef,
          { lastMonthlyBadge: admin.firestore.FieldValue.delete() },
          { merge: true }
        );
      });

      // === 이번 달 상위 12명에게 배지 부여 ===
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
            { merge: true }
          );
        }
      });

      await batch.commit();
      console.log(`월간 배지 부여 완료: ${year}-${month}`);
      return null;
    } catch (error) {
      console.error('월간 배지 부여 실패:', error);
      return null;
    }
  });
