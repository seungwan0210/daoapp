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

function getKstDate(date = new Date()) {
  return new Date(date.getTime() + 9 * 60 * 60 * 1000);
}

function getYearMonthKey(date = new Date()) {
  const kst = getKstDate(date);
  const year = kst.getUTCFullYear();
  const month = String(kst.getUTCMonth() + 1).padStart(2, '0'); // ✅ 0~11
  return `${year}_${month}`;
}

// ====================== Functions Error Logger ======================
async function logFunctionError({
  functionName,
  uid,
  recordId,
  monthKey,
  error,
  extra,
}) {
  try {
    await admin.firestore().collection('function_errors').add({
      function: functionName,
      uid: uid || null,
      recordId: recordId || null,
      monthKey: monthKey || null,
      error: String(error?.message || error),
      stack: error?.stack || null,
      extra: extra || null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (e) {
    console.error('[FunctionErrorLog FAILED]', e);
  }
}


// ====================== Finish Route 랭킹: 컬렉션 규칙 ======================
function getFinishRouteCurrentRankingCollection() {
  return 'finish_route_rankings_current';
}

function getFinishRouteMonthlyArchiveDocRef(db, yyyyMm, uid) {
  return db
    .collection('finish_route_rankings_by_month')
    .doc(yyyyMm)
    .collection('users')
    .doc(uid);
}

// ✅ (호환용) 예전 방식: finish_route_rankings_2025_12 같은 top-level 컬렉션도 같이 갱신
function getFinishRouteLegacyMonthlyCollection(yyyyMm) {
  return `finish_route_rankings_${yyyyMm}`;
}

/**
 * ✅ 점수 계산(클라와 동일 로직)
 * time 40% + optimization 30% + routeMatch 30%
 */
function calculateFinishRouteScore(data) {
  const elapsedSeconds =
    typeof data.elapsedSeconds === 'number' ? data.elapsedSeconds : 0;

  const optimizationRate =
    typeof data.optimizationRate === 'number' ? data.optimizationRate : 0;

  const routeMatchRateRaw =
    typeof data.routeMatchRate === 'number'
      ? data.routeMatchRate
      : typeof data.routeAccuracy === 'number'
      ? data.routeAccuracy
      : typeof data.routeMatchRate === 'number'
      ? data.routeMatchRate
      : 0;

  const routeMatchRate = routeMatchRateRaw;

  const MAX_TIME_SECONDS = 600;
  const timeScore = Math.max(0, 1 - elapsedSeconds / MAX_TIME_SECONDS);

  const finalScoreRatio =
    timeScore * 0.4 + optimizationRate * 0.3 + routeMatchRate * 0.3;

  const score = Math.round(finalScoreRatio * 10000);

  return { score, timeScore, optimizationRate, routeMatchRate };
}

// ====================== 기존 함수들 ======================

// (Functions 목록에 있던 setCustomClaims 유지)
exports.setCustomClaims = functions.https.onRequest(async (req, res) => {
  try {
    // 간단 보호(원하면 더 빡세게 바꿔도 됨)
    const { uid, claims } = req.body || {};
    if (!uid || typeof uid !== 'string') {
      return res.status(400).json({ ok: false, error: 'uid required' });
    }
    if (!claims || typeof claims !== 'object') {
      return res.status(400).json({ ok: false, error: 'claims required' });
    }

    await admin.auth().setCustomUserClaims(uid, claims);
    return res.json({ ok: true });
  } catch (e) {
    console.error('[setCustomClaims] error:', e);
    return res.status(500).json({ ok: false, error: String(e) });
  }
});

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

// ====================== ✅ 피니쉬 루트 랭킹 업데이트 (서버 집계) ======================
/**
 * 트리거: users/{uid}/finish_route_practice/{recordId} 생성 시
 *
 * 갱신 대상(3곳):
 * 1) finish_route_rankings_current/{uid}
 * 2) finish_route_rankings_by_month/{YYYY_MM}/users/{uid}
 * 3) (호환용) finish_route_rankings_{YYYY_MM}/{uid}
 */
exports.updateMonthlyFinishRouteRanking = functions.firestore
  .document('users/{userId}/finish_route_practice/{recordId}')
  .onCreate(async (snap, context) => {
    const db = admin.firestore();
    const data = snap.data() || {};
    const uid = context.params.userId;
    const recordId = context.params.recordId;

    try {
      const fallbackDate = new Date(context.timestamp);
      const recordDate =
        data.timestamp && typeof data.timestamp.toDate === 'function'
          ? data.timestamp.toDate()
          : fallbackDate;

      const yyyyMm = getYearMonthKey(recordDate);

      // 유저 이름
      const userDoc = await db.collection('users').doc(uid).get();
      const koreanName = userDoc.exists
        ? (userDoc.data()?.koreanName || '이름 없음')
        : '이름 없음';

      const { score, routeMatchRate } = calculateFinishRouteScore(data);

      const elapsedSeconds =
        typeof data.elapsedSeconds === 'number' ? data.elapsedSeconds : 999999;

      // NaN 방지
      const safeScore = Number.isFinite(Number(score)) ? Number(score) : 0;
      const safeElapsed = Number.isFinite(Number(elapsedSeconds)) ? Number(elapsedSeconds) : 999999;

      const newRecord = {
        uid,
        koreanName,
        score: safeScore,
        elapsedSeconds: safeElapsed,

        successRate: typeof data.successRate === 'number' ? data.successRate : 0,
        avgDarts: typeof data.avgDarts === 'number' ? data.avgDarts : 99.9,
        optimizationRate:
          typeof data.optimizationRate === 'number' ? data.optimizationRate : 0,

        routeMatchRate,
        routeAccuracy: routeMatchRate,

        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        sessionId: snap.id,
        monthKey: yyyyMm,
      };

      const currentRef = db
        .collection(getFinishRouteCurrentRankingCollection())
        .doc(uid);

      const archiveRef = getFinishRouteMonthlyArchiveDocRef(db, yyyyMm, uid);

      const legacyRef = db
        .collection(getFinishRouteLegacyMonthlyCollection(yyyyMm))
        .doc(uid);

      await db.runTransaction(async (tx) => {
        // ✅ 1) READ 3개 먼저
        const [currentSnap, archiveSnap, legacySnap] = await Promise.all([
          tx.get(currentRef),
          tx.get(archiveRef),
          tx.get(legacyRef),
        ]);

        // ✅ 2) 업데이트 여부 계산
        const decideUpdate = (prevSnap, { isCurrent }) => {
          if (!prevSnap.exists) return true;

          const prev = prevSnap.data() || {};
          const prevScore = Number(prev.score || 0);
          const prevTime = Number(prev.elapsedSeconds || 999999);

          if (isCurrent) {
            const prevMonthKey = (prev.monthKey || '').toString();
            if (prevMonthKey && prevMonthKey !== yyyyMm) {
              // 달 바뀌면 current는 리셋
              return true;
            }
          }

          if (safeScore < prevScore) return false;
          if (safeScore === prevScore && safeElapsed >= prevTime) return false;
          return true;
        };

        const shouldUpdateCurrent = decideUpdate(currentSnap, { isCurrent: true });
        const shouldUpdateArchive = decideUpdate(archiveSnap, { isCurrent: false });
        const shouldUpdateLegacy = decideUpdate(legacySnap, { isCurrent: false });

        // ✅ 3) SET 3개를 마지막에 몰아서
        if (shouldUpdateCurrent) tx.set(currentRef, newRecord, { merge: true });
        if (shouldUpdateArchive) tx.set(archiveRef, newRecord, { merge: true });
        if (shouldUpdateLegacy) tx.set(legacyRef, newRecord, { merge: true });
      });

      console.log(
        `[FinishRoute 랭킹 처리 OK] uid=${uid} name=${koreanName} score=${safeScore} time=${safeElapsed}s month=${yyyyMm}`,
      );
    } catch (e) {
      console.error('[FinishRoute] 랭킹 업데이트 실패:', e, e?.stack);

      await logFunctionError({
        functionName: 'updateMonthlyFinishRouteRanking',
        uid,
        recordId,
        monthKey: null,
        error: e,
        extra: {
          hasTimestampField: !!data.timestamp,
          elapsedSeconds: data.elapsedSeconds,
          successRate: data.successRate,
          optimizationRate: data.optimizationRate,
          routeMatchRate: data.routeMatchRate,
          routeAccuracy: data.routeAccuracy,
        },
      });
    }

    return null;
  });


// ====================== (Functions 목록에 있던) Checkout 랭킹: 안전하게 유지 ======================
exports.updateMonthlyCheckoutRanking = functions.firestore
  .document('users/{userId}/checkout_practice/{recordId}')
  .onCreate(async (snap, context) => {
    try {
      console.log(
        `[Checkout 랭킹 트리거] uid=${context.params.userId} record=${context.params.recordId}`,
      );
    } catch (e) {
      console.error('[Checkout 랭킹] 실패:', e);
    }
    return null;
  });

// ====================== (Functions 목록에 있던) 월간 배지 지급: 삭제 방지용 ======================
exports.grantMonthlyBadges = functions.pubsub
  .schedule('every 24 hours')
  .timeZone('Asia/Seoul')
  .onRun(async () => {
    console.log('[grantMonthlyBadges] no-op (placeholder).');
    return null;
  });

// ====================== 참가자 명단 CSV 생성 ======================
function buildEntriesCsv(entriesDocs) {
  let csv = '\uFEFFnameKo,nameEn,phone,email,rating,homeShop,createdAt\n';

  entriesDocs.forEach((doc) => {
    const e = doc.data();
    const createdAt =
      e.createdAt && e.createdAt.toDate ? e.createdAt.toDate().toISOString() : '';

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
    .get();

  const entriesDocs = [...entriesSnap.docs].sort((a, b) => {
    const ad = a.data()?.createdAt?.toMillis ? a.data().createdAt.toMillis() : 0;
    const bd = b.data()?.createdAt?.toMillis ? b.data().createdAt.toMillis() : 0;
    return ad - bd;
  });

  const organizerEmails = Array.isArray(tournamentData.organizerEmails)
    ? tournamentData.organizerEmails.filter(
        (e) => typeof e === 'string' && e.includes('@'),
      )
    : [];

  if (organizerEmails.length === 0) {
    console.log(`[Arena] ${tournamentId} 유효한 주최자 이메일 없음 → 스킵`);
    return { skipped: true };
  }

  const rawTitle = (tournamentData.title || '토너먼트').substring(0, 80);
  const safeTitle = rawTitle.replace(/[^a-zA-Z0-9가-힣\s]/g, '_');
  const csv = buildEntriesCsv(entriesDocs);

  try {
    await transporter.sendMail({
      from: `"DAO Arena" <${functions.config().email.user}>`,
      to: organizerEmails.join(','),
      subject: `[DAO Arena] ${rawTitle} 참가자 명단`,
      text: `"${rawTitle}" 대회의 참가자 명단입니다.\n\n참가자 수: ${
        entriesDocs.length
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
    return { sent: true, recipients: organizerEmails, count: entriesDocs.length };
  } catch (error) {
    console.error(`[Arena] ${tournamentId} 메일 발송 실패:`, error?.message);
    throw new Error(error?.message || 'sendMail failed');
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
        const result = await sendSummaryForTournament(db, tournamentId, doc.data());

        if (result?.skipped) {
          console.log(`[Arena] ${tournamentId} 이메일 없음 → sent 처리 안 함`);
          await doc.ref
            .update({
              entrySummaryLastTriedAt: admin.firestore.FieldValue.serverTimestamp(),
              entrySummaryLastError: 'No valid organizerEmails (skipped)',
            })
            .catch(() => {});
          return;
        }

        await doc.ref.update({
          entrySummarySent: true,
          entrySummarySentAt: admin.firestore.FieldValue.serverTimestamp(),
          entrySummaryLastTriedAt: admin.firestore.FieldValue.serverTimestamp(),
          entrySummaryLastError: admin.firestore.FieldValue.delete(),
        });

        console.log(`[Arena] ${tournamentId} 메일 발송 완료`);
      } catch (e) {
        console.error(`[Arena] ${tournamentId} 메일 실패`, e);

        await doc.ref
          .update({
            entrySummaryLastError: String(e),
            entrySummaryLastTriedAt: admin.firestore.FieldValue.serverTimestamp(),
            entrySummaryTryCount: admin.firestore.FieldValue.increment(1),
          })
          .catch(() => {});
      }
    });

    await Promise.all(tasks);
    console.log(`[Arena] 마감 대회 ${snap.size}개 처리 시도 완료`);
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

  const result = await sendSummaryForTournament(db, tournamentId, doc.data());

  if (result?.skipped) {
    return { success: false, message: '유효한 organizerEmails가 없어 스킵되었습니다.' };
  }

  await doc.ref.update({
    entrySummarySent: true,
    entrySummarySentAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true, message: '테스트 메일이 발송되었습니다!' };
});
