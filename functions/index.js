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
  const month = String(kst.getUTCMonth() + 1).padStart(2, '0');
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

function getFinishRouteLegacyMonthlyCollection(yyyyMm) {
  return `finish_route_rankings_${yyyyMm}`;
}

/**
 * ✅ 점수 계산(클라와 동일 로직)
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
      : 0;

  const routeMatchRate = routeMatchRateRaw;

  const MAX_TIME_SECONDS = 600;
  const timeScore = Math.max(0, 1 - elapsedSeconds / MAX_TIME_SECONDS);

  const finalScoreRatio =
    timeScore * 0.4 + optimizationRate * 0.3 + routeMatchRate * 0.3;

  const score = Math.round(finalScoreRatio * 10000);

  return { score, timeScore, optimizationRate, routeMatchRate };
}

// ====================== 기존 함수들 (그대로 유지) ======================

exports.setCustomClaims = functions.https.onRequest(async (req, res) => {
  try {
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

      const userDoc = await db.collection('users').doc(uid).get();
      const koreanName = userDoc.exists
        ? (userDoc.data()?.koreanName || '이름 없음')
        : '이름 없음';

      const { score, routeMatchRate } = calculateFinishRouteScore(data);

      const elapsedSeconds =
        typeof data.elapsedSeconds === 'number' ? data.elapsedSeconds : 999999;

      const safeScore = Number.isFinite(Number(score)) ? Number(score) : 0;
      const safeElapsed = Number.isFinite(Number(elapsedSeconds))
        ? Number(elapsedSeconds)
        : 999999;

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
        const [currentSnap, archiveSnap, legacySnap] = await Promise.all([
          tx.get(currentRef),
          tx.get(archiveRef),
          tx.get(legacyRef),
        ]);

        const decideUpdate = (prevSnap, { isCurrent }) => {
          if (!prevSnap.exists) return true;

          const prev = prevSnap.data() || {};
          const prevScore = Number(prev.score || 0);
          const prevTime = Number(prev.elapsedSeconds || 999999);

          if (isCurrent) {
            const prevMonthKey = (prev.monthKey || '').toString();
            if (prevMonthKey && prevMonthKey !== yyyyMm) return true;
          }

          if (safeScore < prevScore) return false;
          if (safeScore === prevScore && safeElapsed >= prevTime) return false;
          return true;
        };

        const shouldUpdateCurrent = decideUpdate(currentSnap, { isCurrent: true });
        const shouldUpdateArchive = decideUpdate(archiveSnap, { isCurrent: false });
        const shouldUpdateLegacy = decideUpdate(legacySnap, { isCurrent: false });

        if (shouldUpdateCurrent) tx.set(currentRef, newRecord, { merge: true });
        if (shouldUpdateArchive) tx.set(archiveRef, newRecord, { merge: true });
        if (shouldUpdateLegacy) tx.set(legacyRef, newRecord, { merge: true });
      });

      console.log(
        `[FinishRoute OK] uid=${uid} name=${koreanName} score=${safeScore} time=${safeElapsed}s month=${yyyyMm}`,
      );
    } catch (e) {
      console.error('[FinishRoute] 실패:', e, e?.stack);

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

exports.grantMonthlyBadges = functions.pubsub
  .schedule('every 24 hours')
  .timeZone('Asia/Seoul')
  .onRun(async () => {
    console.log('[grantMonthlyBadges] no-op (placeholder).');
    return null;
  });

// ====================== 참가자 명단 CSV 생성 (기존 유지) ======================
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

exports.sendTournamentEntrySummary = functions.pubsub
  .schedule('every 60 minutes')
  .timeZone('Asia/Seoul')
  .onRun(async () => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();

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

// ======================================================================
// ✅✅✅ 여기부터 “삭제 시스템” 추가 (계정삭제 + 문서삭제시 스토리지 자동정리)
// ======================================================================

const db = admin.firestore();
const bucket = admin.storage().bucket();

// URL → storage path 추출
function extractStoragePathFromUrl(url) {
  try {
    if (!url || typeof url !== 'string') return null;

    // 1) gs://bucket/path
    if (url.startsWith('gs://')) {
      // gs://<bucket>/<path>
      const without = url.replace('gs://', '');
      const firstSlash = without.indexOf('/');
      if (firstSlash < 0) return null;
      return without.substring(firstSlash + 1);
    }

    // 2) https://firebasestorage.googleapis.com/v0/b/<bucket>/o/<path>?...
    const marker = '/o/';
    const i = url.indexOf(marker);
    if (i < 0) return null;

    const after = url.substring(i + marker.length);
    const q = after.indexOf('?');
    const encodedPath = q >= 0 ? after.substring(0, q) : after;
    const path = decodeURIComponent(encodedPath); // %2F → /
    return path || null;
  } catch (e) {
    return null;
  }
}

async function deleteStorageByUrl(url) {
  const path = extractStoragePathFromUrl(url);
  if (!path) return;

  try {
    await bucket.file(path).delete({ ignoreNotFound: true });
  } catch (e) {
    // 파일이 이미 없거나 권한 문제일 수 있음 → 에러로 중단시키지 않음
    console.warn('[deleteStorageByUrl] failed:', path, e?.message || e);
  }
}

async function deleteManyStorageUrls(urls) {
  const uniq = new Set();
  for (const u of urls) {
    if (typeof u === 'string' && u.trim()) uniq.add(u.trim());
  }
  const tasks = [...uniq].map((u) => deleteStorageByUrl(u));
  await Promise.all(tasks);
}

// Firestore 문서(서브컬렉션 포함) 삭제
async function safeRecursiveDelete(docRef) {
  try {
    await db.recursiveDelete(docRef);
  } catch (e) {
    // recursiveDelete가 환경에서 막히면 fallback: 그냥 doc만 삭제
    console.warn('[safeRecursiveDelete] fallback doc.delete()', e?.message || e);
    await docRef.delete().catch(() => {});
  }
}

// Query 결과 여러 문서 삭제(서브컬렉션 포함)
async function deleteDocsByQuery(query, options = {}) {
  const { beforeDeleteEach } = options;
  const snap = await query.get();
  if (snap.empty) return 0;

  for (const d of snap.docs) {
    try {
      if (beforeDeleteEach) {
        await beforeDeleteEach(d);
      }
      await safeRecursiveDelete(d.ref);
    } catch (e) {
      console.warn('[deleteDocsByQuery] failed:', d.ref.path, e?.message || e);
    }
  }
  return snap.size;
}

// --------------------------------------------------------------
// ✅ 1) 계정삭제: 로그인된 유저가 버튼 누르면 “전체 삭제”
// --------------------------------------------------------------
exports.requestAccountDeletion = functions
  .region('asia-northeast3')
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', '로그인 필요');
    }

    const uid = context.auth.uid;

    // (중요) 마지막에 auth 삭제할 거라서, 여기서 오래 걸려도 됨
    // 다만 너무 큰 데이터면 1~2분 걸릴 수 있어.
    const deletionReport = {
      uid,
      deleted: {
        usersDoc: false,
        communityPosts: 0,
        myLogs: 0,
        tournaments: 0,
        finishRouteRankingDocs: 0,
      },
      storageFilesAttempted: 0,
      startedAt: Date.now(),
    };

    // 혹시 대비용: 삭제 작업 로그 남기고 싶으면
    const jobRef = db.collection('account_deletion_jobs').doc(uid);
    await jobRef.set(
      { uid, status: 'running', startedAt: admin.firestore.FieldValue.serverTimestamp() },
      { merge: true },
    );

    try {
      // --------------------------
      // A) users/{uid} 문서 + 유저 이미지 삭제
      // --------------------------
      const userDocRef = db.collection('users').doc(uid);
      const userSnap = await userDocRef.get();
      if (userSnap.exists) {
        const u = userSnap.data() || {};
        const urls = [
          u.profileImageUrl,
          u.barrelImageUrl,
          u.photoURL,
          u.photoUrl,
        ].filter(Boolean);

        deletionReport.storageFilesAttempted += urls.length;
        await deleteManyStorageUrls(urls);

        // users 문서 자체(서브컬렉션 포함) 삭제
        await safeRecursiveDelete(userDocRef);
        deletionReport.deleted.usersDoc = true;
      }

      // --------------------------
      // B) community: userId == uid 인 글 삭제 (+ 사진 삭제)
      //  - comments/likes 서브컬렉션까지 같이 삭제됨
      // --------------------------
      const communityQuery = db.collection('community').where('userId', '==', uid);
      const deletedCommunityCount = await deleteDocsByQuery(communityQuery, {
        beforeDeleteEach: async (docSnap) => {
          const p = docSnap.data() || {};
          const urls = [p.photoUrl, p.userPhotoUrl].filter(Boolean);
          deletionReport.storageFilesAttempted += urls.length;
          await deleteManyStorageUrls(urls);
        },
      });
      deletionReport.deleted.communityPosts = deletedCommunityCount;

      // --------------------------
      // C) my_logs: userId == uid 인 로그 삭제 (+ photoUrls 삭제)
      // --------------------------
      const myLogsQuery = db.collection('my_logs').where('userId', '==', uid);
      const deletedMyLogsCount = await deleteDocsByQuery(myLogsQuery, {
        beforeDeleteEach: async (docSnap) => {
          const m = docSnap.data() || {};
          const photoUrls = m.photoUrls;

          let urls = [];
          // photoUrls가 배열/맵/단일문자열 어떤 형태든 최대한 커버
          if (Array.isArray(photoUrls)) {
            urls = photoUrls;
          } else if (photoUrls && typeof photoUrls === 'object') {
            urls = Object.values(photoUrls);
          } else if (typeof photoUrls === 'string') {
            urls = [photoUrls];
          }

          urls = urls.filter((x) => typeof x === 'string' && x.trim());
          deletionReport.storageFilesAttempted += urls.length;
          await deleteManyStorageUrls(urls);
        },
      });
      deletionReport.deleted.myLogs = deletedMyLogsCount;

      // --------------------------
      // D) tournaments: "운영 대회도 삭제"라고 했으니
      //    createdByUid == uid 인 것만이 아니라,
      //    유저가 만든 대회/운영 대회 구분 없이 "그 유저가 만든 것만" 삭제는 의미가 없어짐.
      //
      //    여기서 네 요구는 "계정삭제한 유저가 만든 모든 대회 삭제"가 가장 합리적임.
      //    (운영대회도 삭제 = 운영자 계정으로 만든 대회도, 그 운영자 계정 삭제 시 같이 삭제)
      // --------------------------
      const tournamentsQuery = db.collection('tournaments').where('createdByUid', '==', uid);
      const deletedTournamentsCount = await deleteDocsByQuery(tournamentsQuery, {
        beforeDeleteEach: async (docSnap) => {
          const t = docSnap.data() || {};
          const urls = [t.posterUrl].filter(Boolean);
          deletionReport.storageFilesAttempted += urls.length;
          await deleteManyStorageUrls(urls);
        },
      });
      deletionReport.deleted.tournaments = deletedTournamentsCount;

      // --------------------------
      // E) finish_route rankings: uid 문서 삭제
      // 1) finish_route_rankings_current/{uid}
      // 2) finish_route_rankings_by_month/{YYYY_MM}/users/{uid}
      // 3) legacy finish_route_rankings_{YYYY_MM}/{uid} (월키 기반)
      // --------------------------
      let finishRouteDeleted = 0;

      // current
      await db.collection('finish_route_rankings_current').doc(uid).delete().catch(() => {});
      finishRouteDeleted += 1;

      // by_month: 모든 월 문서 읽어서 users/{uid} 삭제 + legacy도 같이 정리
      const monthSnap = await db.collection('finish_route_rankings_by_month').get();
      for (const monthDoc of monthSnap.docs) {
        const monthKey = monthDoc.id;

        await monthDoc.ref.collection('users').doc(uid).delete().catch(() => {});
        finishRouteDeleted += 1;

        // legacy
        await db.collection(`finish_route_rankings_${monthKey}`).doc(uid).delete().catch(() => {});
        finishRouteDeleted += 1;
      }

      // 혹시 월 문서가 하나도 없을 때 대비: 이번달 legacy도 한번 더 시도
      const nowMonthKey = getYearMonthKey(new Date());
      await db.collection(`finish_route_rankings_${nowMonthKey}`).doc(uid).delete().catch(() => {});
      finishRouteDeleted += 1;

      deletionReport.deleted.finishRouteRankingDocs = finishRouteDeleted;

      // --------------------------
      // F) 마지막: Auth 계정 삭제 (진짜 마지막에!)
      // --------------------------
      await admin.auth().deleteUser(uid);

      deletionReport.finishedAt = Date.now();
      deletionReport.ms = deletionReport.finishedAt - deletionReport.startedAt;

      await jobRef.set(
        {
          status: 'done',
          finishedAt: admin.firestore.FieldValue.serverTimestamp(),
          report: deletionReport,
        },
        { merge: true },
      );

      return { ok: true, report: deletionReport };
    } catch (e) {
      console.error('[requestAccountDeletion] failed:', e);

      await jobRef.set(
        {
          status: 'failed',
          error: String(e?.message || e),
          failedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      throw new functions.https.HttpsError(
        'internal',
        '계정 삭제 처리 중 오류가 발생했습니다.',
      );
    }
  });

// --------------------------------------------------------------
// ✅ 2) 문서가 삭제되면 Storage도 자동 삭제 (어드민 운영데이터 포함)
// --------------------------------------------------------------
async function cleanupImageFieldOnDelete(snap, fieldNames = []) {
  const data = snap.data() || {};
  const urls = [];
  for (const f of fieldNames) {
    const v = data[f];
    if (Array.isArray(v)) urls.push(...v);
    else if (v && typeof v === 'object') urls.push(...Object.values(v));
    else if (typeof v === 'string') urls.push(v);
  }
  await deleteManyStorageUrls(urls);
}

// sponsors: imageUrl
exports.onSponsorDeleted = functions
  .region('asia-northeast3')
  .firestore.document('sponsors/{docId}')
  .onDelete(async (snap) => {
    await cleanupImageFieldOnDelete(snap, ['imageUrl']);
    return null;
  });

// competition_photos: imageUrl
exports.onCompetitionPhotoDeleted = functions
  .region('asia-northeast3')
  .firestore.document('competition_photos/{docId}')
  .onDelete(async (snap) => {
    await cleanupImageFieldOnDelete(snap, ['imageUrl']);
    return null;
  });

// news: imageUrl
exports.onNewsDeleted = functions
  .region('asia-northeast3')
  .firestore.document('news/{docId}')
  .onDelete(async (snap) => {
    await cleanupImageFieldOnDelete(snap, ['imageUrl']);
    return null;
  });

// tournaments: posterUrl (어드민이 대회 삭제해도 스토리지 정리)
exports.onTournamentDeleted = functions
  .region('asia-northeast3')
  .firestore.document('tournaments/{tournamentId}')
  .onDelete(async (snap) => {
    await cleanupImageFieldOnDelete(snap, ['posterUrl']);
    return null;
  });

// community: photoUrl, userPhotoUrl (글 삭제시 스토리지 정리)
exports.onCommunityPostDeleted = functions
  .region('asia-northeast3')
  .firestore.document('community/{postId}')
  .onDelete(async (snap) => {
    await cleanupImageFieldOnDelete(snap, ['photoUrl', 'userPhotoUrl']);
    return null;
  });

// my_logs: photoUrls (로그 삭제시 스토리지 정리)
exports.onMyLogDeleted = functions
  .region('asia-northeast3')
  .firestore.document('my_logs/{logId}')
  .onDelete(async (snap) => {
    await cleanupImageFieldOnDelete(snap, ['photoUrls']);
    return null;
  });

// users: profileImageUrl, barrelImageUrl, photoURL (유저 문서 삭제시 스토리지 정리)
exports.onUserDeleted = functions
  .region('asia-northeast3')
  .firestore.document('users/{uid}')
  .onDelete(async (snap) => {
    await cleanupImageFieldOnDelete(snap, ['profileImageUrl', 'barrelImageUrl', 'photoURL', 'photoUrl']);
    return null;
  });
