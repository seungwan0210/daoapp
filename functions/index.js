// functions/index.js

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

admin.initializeApp();

// ====================== 이메일 발송 설정 ======================
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: functions.config().email.user,
    pass: functions.config().email.pass,
  },
});

// ====================== 한국시간 헬퍼 ======================
function getKoreaNowTimestamp() {
  return admin.firestore.Timestamp.fromMillis(Date.now() + 9 * 60 * 60 * 1000);
}

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

// ====================== 기존 함수들 ======================
exports.setHasProfile = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', '로그인 필요');
  }
  await admin.auth().setCustomUserClaims(context.auth.uid, { hasProfile: true });
  return { success: true };
});

exports.cleanupOnlineUsers = functions.pubsub
  .schedule('every 5 minutes')
  .onRun(async () => {
    const cutoff = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 60 * 1000),
    );

    const snapshot = await admin
      .firestore()
      .collection('online_users')
      .where('lastSeen', '<', cutoff)
      .get();

    if (snapshot.empty) return null;

    const batch = admin.firestore().batch();
    snapshot.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
    return null;
  });

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

      const newRecord = {
        uid,
        koreanName,
        score,
        elapsedSeconds: data.elapsedSeconds || 999999,
        successRate: data.successRate || 0,
        avgDarts: data.avgDarts || 99.9,
        optimizationRate: data.optimizationRate || 0,
        routeMatchRate: data.routeMatchRate || 0,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        sessionId: snap.id,
      };

      const rankingSnap = await rankingRef.get();
      if (!rankingSnap.exists || (rankingSnap.data()?.score || 0) < score) {
        await rankingRef.set(newRecord);
        console.log(
          `[랭킹 ${rankingSnap.exists ? '갱신' : '등록'}] ${koreanName} → ${score}점`,
        );
      }
    } catch (e) {
      console.error('랭킹 업데이트 실패:', e);
    }
    return null;
  });

// 🔻🔻🔻 여기 있던 grantMonthlyBadges + BADGE_MAP 은 제거됨 🔻🔻🔻
// exports.grantMonthlyBadges ... (삭제)

// ====================== Arena: 참가자 수 카운트 ======================
exports.onTournamentEntryCreated = functions.firestore
  .document('tournaments/{tournamentId}/entries/{entryId}')
  .onCreate(async (snap, context) => {
    const { tournamentId } = context.params;
    await admin
      .firestore()
      .collection('tournaments')
      .doc(tournamentId)
      .update({
        entryCount: admin.firestore.FieldValue.increment(1),
      })
      .catch((e) => console.error('[Arena] entryCount 증가 실패:', e));
  });

exports.onTournamentEntryDeleted = functions.firestore
  .document('tournaments/{tournamentId}/entries/{entryId}')
  .onDelete(async (snap, context) => {
    const { tournamentId } = context.params;
    await admin
      .firestore()
      .collection('tournaments')
      .doc(tournamentId)
      .update({
        entryCount: admin.firestore.FieldValue.increment(-1),
      })
      .catch((e) => console.error('[Arena] entryCount 감소 실패:', e));
  });

// ====================== 참가자 명단 CSV 생성 ======================
function buildEntriesCsv(entriesSnap) {
  let csv = '\uFEFFnameKo,nameEn,phone,email,rating,homeShop,createdAt\n';
  entriesSnap.forEach((doc) => {
    const e = doc.data();
    const createdAt = e.createdAt ? e.createdAt.toDate().toISOString() : '';
    const line = `"${e.nameKo || ''}","${e.nameEn || ''}","${e.phone || ''}","${
      e.email || ''
    }","${e.rating || ''}","${e.homeShop || ''}","${createdAt}"\n`;
    csv += line;
  });
  return csv;
}

async function sendSummaryForTournament(db, tournamentId, tournamentData) {
  const entriesSnap = await db
    .collection('tournaments')
    .doc(tournamentId)
    .collection('entries')
    .orderBy('createdAt', 'asc')
    .get();

  let organizerEmails = Array.isArray(tournamentData.organizerEmails)
    ? tournamentData.organizerEmails.filter(
        (e) => typeof e === 'string' && e.includes('@'),
      )
    : [];

  if (organizerEmails.length === 0) {
    console.log(`[Arena] ${tournamentId} 유효한 주최자 이메일 없음 → 스킵`);
    return;
  }

  const rawTitle = (tournamentData.title || '토너먼트').substring(0, 80);
  const safeTitle = rawTitle.replace(/[^a-zA-Z0-9가-힣\s]/g, '_');
  const csv = buildEntriesCsv(entriesSnap);

  try {
    await transporter.sendMail({
      from: `"DAO Arena" <${functions.config().email.user}>`,
      to: organizerEmails.join(','),
      subject: `[DAO Arena] ${rawTitle} 참가자 명단`,
      text: `"${rawTitle}" 대회의 참가자 명단입니다.\n\n참가자 수: ${
        entriesSnap.size
      }명\n첨부된 CSV 파일을 확인해주세요!`,
      attachments: [
        {
          filename: `${safeTitle}_참가자명단.csv`,
          content: Buffer.from(csv, 'utf-8'),
        },
      ],
    });
    console.log(
      `[Arena] ${tournamentId} 메일 발송 성공 → ${organizerEmails.join(', ')}`,
    );
  } catch (error) {
    console.error(`[Arena] ${tournamentId} 메일 발송 실패:`, error.message);
  }
}

// 자동 발송 - 한국시간 기준 매시간 실행
exports.sendTournamentEntrySummary = functions.pubsub
  .schedule('every 60 minutes')
  .timeZone('Asia/Seoul')
  .onRun(async () => {
    const db = admin.firestore();
    const now = getKoreaNowTimestamp();

    const snap = await db
      .collection('tournaments')
      .where('entryEndDate', '<=', now)
      .where('entrySummarySent', '==', false)
      .get();

    if (snap.empty) {
      console.log('[Arena] 처리할 마감 대회 없음');
      return null;
    }

    const tasks = snap.docs.map(async (doc) => {
      const tournamentId = doc.id;
      try {
        await sendSummaryForTournament(db, tournamentId, doc.data());
      } catch (e) {
        console.error('개별 메일 처리 실패:', e);
      } finally {
        await db
          .collection('tournaments')
          .doc(tournamentId)
          .update({ entrySummarySent: true })
          .catch(() => {});
      }
    });

    await Promise.all(tasks);
    console.log(`[Arena] 마감 대회 ${snap.size}개 처리 완료`);
    return null;
  });

// 관리자 전용 테스트 함수
exports.testSendEntrySummary = functions.https.onCall(async (data, context) => {
  if (!context.auth || context.auth.uid !== 'NanHPgCdsbMCFkHEs7MtxS51OSX2') {
    throw new functions.https.HttpsError(
      'permission-denied',
      '관리자 전용 기능입니다',
    );
  }

  const tournamentId = data.tournamentId;
  if (!tournamentId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'tournamentId가 필요합니다',
    );
  }

  const db = admin.firestore();
  const doc = await db.collection('tournaments').doc(tournamentId).get();
  if (!doc.exists) {
    throw new functions.https.HttpsError('not-found', '대회를 찾을 수 없습니다');
  }

  await sendSummaryForTournament(db, tournamentId, doc.data());
  await doc.ref.update({ entrySummarySent: true });

  return { success: true, message: '테스트 메일이 발송되었습니다!' };
});
