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

// ----------------------------------------------------------------------
// ❌ [피니시 루트 관련 랭킹 컬렉션 규칙 및 점수 계산 함수 삭제됨]
// ----------------------------------------------------------------------

// ====================== 기존 Auth 및 유틸 함수들 ======================

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

// ----------------------------------------------------------------------
// ❌ [updateMonthlyFinishRouteRanking 트리거 함수 삭제됨]
// ----------------------------------------------------------------------

exports.updateMonthlyCheckoutRanking = functions.firestore
  .document('users/{userId}/checkout_practice/{recordId}')
  .onCreate(async (snap, context) => {
    try {
      console.log(
        `[Checkout 랭킹 트리거] uid=${context.params.userId} record=${context.params.recordId}`,
      );
      // TODO: 향후 자유 랭킹(01/Cricket) 로직으로 대체 가능
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

// ====================== 참가자 명단 CSV 생성 및 토너먼트 메일 발송 ======================

function buildEntriesCsv(entriesDocs) {
  let csv = '\uFEFFnameKo,nameEn,phone,email,rating,homeShop,createdAt\n';
  entriesDocs.forEach((doc) => {
    const e = doc.data();
    const createdAt = e.createdAt && e.createdAt.toDate ? e.createdAt.toDate().toISOString() : '';
    const line = `"${e.nameKo || ''}","${e.nameEn || ''}","${e.phone || ''}","${e.email || ''}","${e.rating || ''}","${e.homeShop || ''}","${createdAt}"\n`;
    csv += line;
  });
  return csv;
}

async function sendSummaryForTournament(db, tournamentId, tournamentData) {
  const entriesSnap = await db.collection('tournaments').doc(tournamentId).collection('entries').get();
  const entriesDocs = [...entriesSnap.docs].sort((a, b) => {
    const ad = a.data()?.createdAt?.toMillis ? a.data().createdAt.toMillis() : 0;
    const bd = b.data()?.createdAt?.toMillis ? b.data().createdAt.toMillis() : 0;
    return ad - bd;
  });

  const organizerEmails = Array.isArray(tournamentData.organizerEmails)
    ? tournamentData.organizerEmails.filter((e) => typeof e === 'string' && e.includes('@'))
    : [];

  if (organizerEmails.length === 0) return { skipped: true };

  const rawTitle = (tournamentData.title || '토너먼트').substring(0, 80);
  const safeTitle = rawTitle.replace(/[^a-zA-Z0-9가-힣\s]/g, '_');
  const csv = buildEntriesCsv(entriesDocs);

  try {
    await transporter.sendMail({
      from: `"DAO Arena" <${functions.config().email.user}>`,
      to: organizerEmails.join(','),
      subject: `[DAO Arena] ${rawTitle} 참가자 명단`,
      text: `"${rawTitle}" 대회의 참가자 명단입니다.\n\n참가자 수: ${entriesDocs.length}명`,
      attachments: [{ filename: `${safeTitle}_참가자명단.csv`, content: Buffer.from(csv, 'utf-8') }],
    });
    return { sent: true, recipients: organizerEmails, count: entriesDocs.length };
  } catch (error) {
    throw new Error(error?.message || 'sendMail failed');
  }
}

exports.sendTournamentEntrySummary = functions.pubsub
  .schedule('every 60 minutes')
  .timeZone('Asia/Seoul')
  .onRun(async () => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();
    const snap = await db.collection('tournaments').where('entryEndDate', '<=', now).where('entrySummarySent', '==', false).get();

    if (snap.empty) return null;

    const tasks = snap.docs.map(async (doc) => {
      try {
        const result = await sendSummaryForTournament(db, doc.id, doc.data());
        if (result?.skipped) {
          await doc.ref.update({ entrySummaryLastTriedAt: admin.firestore.FieldValue.serverTimestamp(), entrySummaryLastError: 'No valid organizerEmails (skipped)' });
          return;
        }
        await doc.ref.update({ entrySummarySent: true, entrySummarySentAt: admin.firestore.FieldValue.serverTimestamp(), entrySummaryLastTriedAt: admin.firestore.FieldValue.serverTimestamp() });
      } catch (e) {
        await doc.ref.update({ entrySummaryLastError: String(e), entrySummaryLastTriedAt: admin.firestore.FieldValue.serverTimestamp(), entrySummaryTryCount: admin.firestore.FieldValue.increment(1) });
      }
    });
    await Promise.all(tasks);
    return null;
  });

exports.testSendEntrySummary = functions.https.onCall(async (data, context) => {
  if (!context.auth || context.auth.uid !== 'NanHPgCdsbMCFkHEs7MtxS51OSX2') {
    throw new functions.https.HttpsError('permission-denied', '관리자 전용 기능입니다');
  }
  const tournamentId = data.tournamentId;
  const db = admin.firestore();
  const doc = await db.collection('tournaments').doc(tournamentId).get();
  if (!doc.exists) throw new functions.https.HttpsError('not-found', '대회를 찾을 수 없습니다');

  const result = await sendSummaryForTournament(db, tournamentId, doc.data());
  if (result?.skipped) return { success: false, message: '이메일 주소 없음' };

  await doc.ref.update({ entrySummarySent: true, entrySummarySentAt: admin.firestore.FieldValue.serverTimestamp() });
  return { success: true, message: '발송 완료' };
});

// ====================== 삭제 시스템 (유저 데이터 + 스토리지 정리) ======================

const db = admin.firestore();
const bucket = admin.storage().bucket();

function extractStoragePathFromUrl(url) {
  try {
    if (!url || typeof url !== 'string') return null;
    if (url.startsWith('gs://')) {
      const without = url.replace('gs://', '');
      const firstSlash = without.indexOf('/');
      return firstSlash < 0 ? null : without.substring(firstSlash + 1);
    }
    const marker = '/o/';
    const i = url.indexOf(marker);
    if (i < 0) return null;
    const after = url.substring(i + marker.length);
    const q = after.indexOf('?');
    const encodedPath = q >= 0 ? after.substring(0, q) : after;
    return decodeURIComponent(encodedPath);
  } catch (e) { return null; }
}

async function deleteStorageByUrl(url) {
  const path = extractStoragePathFromUrl(url);
  if (path) await bucket.file(path).delete({ ignoreNotFound: true }).catch(() => {});
}

async function deleteManyStorageUrls(urls) {
  const uniq = [...new Set(urls.filter(u => typeof u === 'string' && u.trim()))];
  await Promise.all(uniq.map(u => deleteStorageByUrl(u)));
}

async function safeRecursiveDelete(docRef) {
  try { await db.recursiveDelete(docRef); } catch (e) { await docRef.delete().catch(() => {}); }
}

async function deleteDocsByQuery(query, options = {}) {
  const { beforeDeleteEach } = options;
  const snap = await query.get();
  if (snap.empty) return 0;
  for (const d of snap.docs) {
    if (beforeDeleteEach) await beforeDeleteEach(d);
    await safeRecursiveDelete(d.ref);
  }
  return snap.size;
}

exports.requestAccountDeletion = functions
  .region('asia-northeast3')
  .https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', '로그인 필요');
    const uid = context.auth.uid;
    const jobRef = db.collection('account_deletion_jobs').doc(uid);
    await jobRef.set({ uid, status: 'running', startedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });

    try {
      // A) 유저 문서 + 이미지
      const userDocRef = db.collection('users').doc(uid);
      const userSnap = await userDocRef.get();
      if (userSnap.exists) {
        const u = userSnap.data() || {};
        await deleteManyStorageUrls([u.profileImageUrl, u.barrelImageUrl, u.photoURL, u.photoUrl]);
        await safeRecursiveDelete(userDocRef);
      }

      // B) 커뮤니티
      await deleteDocsByQuery(db.collection('community').where('userId', '==', uid), {
        beforeDeleteEach: async (d) => await deleteManyStorageUrls([d.data().photoUrl, d.data().userPhotoUrl])
      });

      // C) 마이로그
      await deleteDocsByQuery(db.collection('my_logs').where('userId', '==', uid), {
        beforeDeleteEach: async (d) => {
          const p = d.data().photoUrls;
          const urls = Array.isArray(p) ? p : (p && typeof p === 'object' ? Object.values(p) : [p]);
          await deleteManyStorageUrls(urls);
        }
      });

      // D) 토너먼트
      await deleteDocsByQuery(db.collection('tournaments').where('createdByUid', '==', uid), {
        beforeDeleteEach: async (d) => await deleteManyStorageUrls([d.data().posterUrl])
      });

      // ----------------------------------------------------------------------
      // ❌ [E 섹션: 피니시 루트 랭킹 문서 삭제 로직 제거됨]
      // ----------------------------------------------------------------------

      // F) Auth 계정 삭제
      await admin.auth().deleteUser(uid);
      await jobRef.set({ status: 'done', finishedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });

      return { ok: true };
    } catch (e) {
      await jobRef.set({ status: 'failed', error: String(e) }, { merge: true });
      throw new functions.https.HttpsError('internal', '삭제 실패');
    }
  });

// ====================== Firestore Delete Triggers (스토리지 정리) ======================

async function cleanupImageFieldOnDelete(snap, fieldNames = []) {
  const data = snap.data() || {};
  const urls = [];
  fieldNames.forEach(f => {
    const v = data[f];
    if (Array.isArray(v)) urls.push(...v);
    else if (v && typeof v === 'object') urls.push(...Object.values(v));
    else if (typeof v === 'string') urls.push(v);
  });
  await deleteManyStorageUrls(urls);
}

exports.onSponsorDeleted = functions.region('asia-northeast3').firestore.document('sponsors/{docId}').onDelete(snap => cleanupImageFieldOnDelete(snap, ['imageUrl']));
exports.onCompetitionPhotoDeleted = functions.region('asia-northeast3').firestore.document('competition_photos/{docId}').onDelete(snap => cleanupImageFieldOnDelete(snap, ['imageUrl']));
exports.onNewsDeleted = functions.region('asia-northeast3').firestore.document('news/{docId}').onDelete(snap => cleanupImageFieldOnDelete(snap, ['imageUrl']));
exports.onTournamentDeleted = functions.region('asia-northeast3').firestore.document('tournaments/{tournamentId}').onDelete(snap => cleanupImageFieldOnDelete(snap, ['posterUrl']));
exports.onCommunityPostDeleted = functions.region('asia-northeast3').firestore.document('community/{postId}').onDelete(snap => cleanupImageFieldOnDelete(snap, ['photoUrl', 'userPhotoUrl']));
exports.onMyLogDeleted = functions.region('asia-northeast3').firestore.document('my_logs/{logId}').onDelete(snap => cleanupImageFieldOnDelete(snap, ['photoUrls']));
exports.onUserDeleted = functions.region('asia-northeast3').firestore.document('users/{uid}').onDelete(snap => cleanupImageFieldOnDelete(snap, ['profileImageUrl', 'barrelImageUrl', 'photoURL', 'photoUrl']));