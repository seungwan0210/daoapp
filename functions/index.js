const functions = require('firebase-functions/v1'); // 1세대로 유지하여 충돌 방지
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

admin.initializeApp();

// ====================== 이메일 발송 설정 (.env 사용) ======================
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
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

// ====================== 기존 Auth 및 유틸 함수들 ======================

exports.setCustomClaims = functions.https.onRequest(async (req, res) => {
  try {
    const { uid, claims } = req.body || {};
    if (!uid || typeof uid !== 'string') return res.status(400).json({ ok: false, error: 'uid required' });
    await admin.auth().setCustomUserClaims(uid, claims);
    return res.json({ ok: true });
  } catch (e) { return res.status(500).json({ ok: false, error: String(e) }); }
});

exports.setHasProfile = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', '로그인 필요');
  await admin.auth().setCustomUserClaims(context.auth.uid, { hasProfile: true });
  return { success: true };
});

/**
 * ✅ [수정] 1세대 스케줄러 문법으로 복구 (에러 방지)
 */
exports.cleanupOnlineUsers = functions.pubsub.schedule('every 5 minutes').onRun(async (context) => {
  const cutoff = admin.firestore.Timestamp.fromDate(new Date(Date.now() - 60 * 1000));
  const snapshot = await admin.firestore().collection('online_users').where('lastSeen', '<', cutoff).get();
  if (snapshot.empty) return null;
  const batch = admin.firestore().batch();
  snapshot.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();
  return null;
});

exports.updateMonthlyCheckoutRanking = functions.firestore
  .document('users/{userId}/checkout_practice/{recordId}')
  .onCreate(async (snap, context) => {
    try { console.log(`[Checkout 랭킹 트리거] uid=${context.params.userId}`); } catch (e) {}
    return null;
  });

/**
 * ✅ [수정] 1세대 스케줄러 문법으로 복구
 */
exports.grantMonthlyBadges = functions.pubsub.schedule('every 24 hours').timeZone('Asia/Seoul').onRun(async (context) => {
  console.log('[grantMonthlyBadges] no-op (placeholder).');
  return null;
});

// ====================== 참가자 명단 CSV 생성 및 토너먼트 메일 발송 ======================

function buildEntriesCsv(entriesDocs) {
  if (entriesDocs.length === 0) return '';

  // 1. 모든 엔트리(팀장+팀원)를 뒤져서 존재하는 모든 '추가 질문 키'를 중복 없이 수집합니다.
  const customKeysSet = new Set();
  entriesDocs.forEach((doc) => {
    const e = doc.data();
    // 팀장(또는 개인전 참가자)의 답변 키 수집
    if (e.customAnswers) {
      Object.keys(e.customAnswers).forEach(key => customKeysSet.add(key));
    }
    // 팀원들의 답변 키 수집
    if (e.members && Array.isArray(e.members)) {
      e.members.forEach(m => {
        if (m.customAnswers) {
          Object.keys(m.customAnswers).forEach(key => customKeysSet.add(key));
        }
      });
    }
  });

  const customHeaderList = Array.from(customKeysSet);

  // 2. CSV 헤더 생성 (기존 필드 + 동적 추가 질문 필드)
  let header = 'Type,TeamName,Name(Ko),Name(En),Phone,Email,Rating,HomeShop,CreatedAt';
  customHeaderList.forEach(key => {
    header += `,${key}`; // 질문 내용을 컬럼명으로 추가
  });

  let csv = '\uFEFF' + header + '\n'; // 한글 깨짐 방지용 BOM 추가

  // 3. 데이터 행 생성
  entriesDocs.forEach((doc) => {
    const e = doc.data();
    const createdAt = e.createdAt && e.createdAt.toDate ? e.createdAt.toDate().toISOString() : '';

    // 헬퍼 함수: 질문 헤더 순서대로 답변 값을 가져와서 CSV용 문자열로 변환
    const getCustomValues = (answersMap) => {
      return customHeaderList.map(key => {
        const val = (answersMap && answersMap[key]) ? answersMap[key] : '';
        // 답변에 쉼표(,)가 있을 경우 CSV 형식이 깨지므로 따옴표로 감싸줌
        return `"${String(val).replace(/"/g, '""')}"`;
      }).join(',');
    };

    if (e.members && Array.isArray(e.members) && e.members.length > 0) {
      // --- 팀장 행 ---
      const leaderCustoms = getCustomValues(e.customAnswers);
      csv += `"TEAM","${e.teamName || ''}","${e.nameKo || ''}(팀장)","${e.nameEn || ''}","${e.phone || ''}","${e.email || ''}","${e.rating || ''}","${e.homeShop || ''}","${createdAt}",${leaderCustoms}\n`;

      // --- 팀원 행 ---
      e.members.forEach((m) => {
        const memberCustoms = getCustomValues(m.customAnswers);
        csv += `"MEMBER","${e.teamName || ''}","${m.name || ''}","","","","${m.rating || ''}","","",${memberCustoms}\n`;
      });
    } else {
      // --- 개인전 행 ---
      const singleCustoms = getCustomValues(e.customAnswers);
      csv += `"SINGLE","","${e.nameKo || ''}","${e.nameEn || ''}","${e.phone || ''}","${e.email || ''}","${e.rating || ''}","${e.homeShop || ''}","${createdAt}",${singleCustoms}\n`;
    }
  });

  return csv;
}

// sendSummaryForTournament 함수는 기존 코드를 그대로 사용해도 무방합니다.
async function sendSummaryForTournament(db, tournamentId, tournamentData) {
  const entriesSnap = await db.collection('tournaments').doc(tournamentId).collection('entries').get();
  const entriesDocs = [...entriesSnap.docs].sort((a, b) => (a.data()?.createdAt?.toMillis() || 0) - (b.data()?.createdAt?.toMillis() || 0));
  const organizerEmails = Array.isArray(tournamentData.organizerEmails) ? tournamentData.organizerEmails.filter((e) => typeof e === 'string' && e.includes('@')) : [];

  if (organizerEmails.length === 0) return { skipped: true };

  const rawTitle = (tournamentData.title || '토너먼트').substring(0, 80);
  const safeTitle = rawTitle.replace(/[^a-zA-Z0-9가-힣\s]/g, '_');
  const csv = buildEntriesCsv(entriesDocs);

  try {
    await transporter.sendMail({
      from: `"DAO Arena" <${process.env.EMAIL_USER}>`,
      to: organizerEmails.join(','),
      subject: `[DAO Arena] ${rawTitle} 참가자 명단`,
      text: `"${rawTitle}" 대회의 참가자 명단입니다.\n\n참가 신청 건수: ${entriesDocs.length}건`,
      attachments: [{ filename: `${safeTitle}_참가자명단.csv`, content: Buffer.from(csv, 'utf-8') }],
    });
    return { sent: true };
  } catch (error) {
    throw new Error(error?.message || 'sendMail failed');
  }
}

/**
 * ✅ [최종 통합본] 관리자 전용: 유저의 모든 흔적 소멸 함수
 * 수정사항: free_rankings 월별 대응, chats 필드명(uid) 대응, community 하위 댓글/좋아요 찌꺼기 대응
 */
exports.adminHardCleanup = functions.region('asia-northeast3').https.onCall(async (data, context) => {
  // 1. 보안 체크
  if (!context.auth || (context.auth.token.admin !== true && context.auth.uid !== 'NanHPgCdsbMCFkHEs7MtxS51OSX2')) {
    throw new functions.https.HttpsError('permission-denied', '관리자 권한이 필요합니다.');
  }

  const targetUid = data.uid;
  if (!targetUid) throw new functions.https.HttpsError('invalid-argument', '대상 UID가 누락되었습니다.');

  console.log(`[Admin Hard Cleanup] UID: ${targetUid} 소멸 작업을 시작합니다.`);

  try {
    // --- 1. 유저 메인 문서 및 하위 찌꺼기 (readNotices 등) 삭제 ---
    const userDocRef = db.collection('users').doc(targetUid);
    await safeRecursiveDelete(userDocRef);

    // --- 2. free_rankings 월별 데이터 삭제 (문서 ID가 UID인 경우 대응) ---
    const monthsSnap = await db.collection('free_rankings').get();
    for (const monthDoc of monthsSnap.docs) {
      await safeRecursiveDelete(monthDoc.ref.collection('ranking_list').doc(targetUid));
      await safeRecursiveDelete(monthDoc.ref.collection('total_rankings').doc(targetUid));
    }

    // --- 3. chats 컬렉션 삭제 (필드명이 'uid'인 경우 대응) ---
    const chatSnap = await db.collection('chats').where('uid', '==', targetUid).get();
    for (const d of chatSnap.docs) {
      await d.ref.delete(); // 개별 채팅 메시지 삭제
    }

    // --- 4. 계층형 컬렉션 삭제 (내가 쓴 글 + 그 글의 모든 댓글/좋아요) ---
    const recursiveCols = ['community', 'trainingProfiles'];
    for (const col of recursiveCols) {
      const snap = await db.collection(col).where('userId', '==', targetUid).get();
      for (const doc of snap.docs) {
        await safeRecursiveDelete(doc.ref);
      }
    }

    // --- 5. [중요] 내가 '다른 사람 글'에 남긴 댓글 및 좋아요 삭제 (찌꺼기 방지) ---
    // ※ 주의: Firebase 콘솔에서 색인(Index) 생성이 필요할 수 있습니다.
    const myComments = await db.collectionGroup('comments').where('userId', '==', targetUid).get();
    for (const d of myComments.docs) await d.ref.delete();

    const myLikes = await db.collectionGroup('likes').where('userId', '==', targetUid).get();
    for (const d of myLikes.docs) await d.ref.delete();

    // --- 6. 단순 평면 데이터 삭제 (필드명이 'userId'인 것들) ---
    const flatCols = ['community_chat', 'my_logs', 'online_users', 'entries', 'point_records'];
    for (const col of flatCols) {
      await deleteDocsByQuery(db.collection(col).where('userId', '==', targetUid));
    }

    // --- 7. 유저가 생성한 상위 데이터 (createdByUid 기준) ---
    const ownerCols = ['tournaments', 'competition_photos'];
    for (const col of ownerCols) {
      await deleteDocsByQuery(db.collection(col).where('createdByUid', '==', targetUid));
    }

    // --- 8. Firebase Auth 계정 최종 삭제 ---
    try {
      await admin.auth().deleteUser(targetUid);
    } catch (e) {
      console.log('Auth 계정이 이미 없거나 삭제됨');
    }

    return {
      success: true,
      message: `UID: ${targetUid}의 모든 흔적이 완벽히 소멸되었습니다.`
    };

  } catch (error) {
    console.error(`[Admin Hard Cleanup Error] uid=${targetUid}`, error);
    throw new functions.https.HttpsError('internal', `삭제 중 오류 발생: ${error.message}`);
  }
});

/**
 * ✅ [수정] 1세대 스케줄러 문법으로 복구
 */
exports.sendTournamentEntrySummary = functions.pubsub.schedule('every 60 minutes').timeZone('Asia/Seoul').onRun(async (context) => {
  const db = admin.firestore();
  const now = admin.firestore.Timestamp.now();
  const snap = await db.collection('tournaments').where('entryEndDate', '<=', now).where('entrySummarySent', '==', false).get();
  if (snap.empty) return null;
  for (const doc of snap.docs) {
    try {
      const result = await sendSummaryForTournament(db, doc.id, doc.data());
      if (result?.skipped) continue;
      await doc.ref.update({ entrySummarySent: true, entrySummarySentAt: admin.firestore.FieldValue.serverTimestamp() });
    } catch (e) { await doc.ref.update({ entrySummaryLastError: String(e) }); }
  }
  return null;
});

exports.testSendEntrySummary = functions.https.onCall(async (data, context) => {
  if (!context.auth || context.auth.uid !== 'NanHPgCdsbMCFkHEs7MtxS51OSX2') throw new functions.https.HttpsError('permission-denied', '관리자 전용');
  const tournamentId = data.tournamentId;
  const db = admin.firestore();
  const doc = await db.collection('tournaments').doc(tournamentId).get();
  if (!doc.exists) throw new functions.https.HttpsError('not-found', '대회 없음');
  const result = await sendSummaryForTournament(db, tournamentId, doc.data());
  if (result?.skipped) return { success: false, message: '이메일 주소 없음' };
  await doc.ref.update({ entrySummarySent: true, entrySummarySentAt: admin.firestore.FieldValue.serverTimestamp() });
  return { success: true };
});

// ====================== 삭제 시스템 (유저 데이터 + 스토리지 정리) ======================

const db = admin.firestore();
const bucket = admin.storage().bucket();

function extractStoragePathFromUrl(url) {
  try { if (!url) return null; const marker = '/o/'; const i = url.indexOf(marker); if (i < 0) return null;
    const after = url.substring(i + marker.length); const q = after.indexOf('?');
    const encodedPath = q >= 0 ? after.substring(0, q) : after; return decodeURIComponent(encodedPath);
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

async function safeRecursiveDelete(docRef) { try { await db.recursiveDelete(docRef); } catch (e) { await docRef.delete().catch(() => {}); } }

async function deleteDocsByQuery(query, options = {}) {
  const snap = await query.get(); if (snap.empty) return 0;
  for (const d of snap.docs) { if (options.beforeDeleteEach) await options.beforeDeleteEach(d); await safeRecursiveDelete(d.ref); }
  return snap.size;
}

exports.requestAccountDeletion = functions.region('asia-northeast3').https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', '로그인 필요');
  const uid = context.auth.uid;
  const jobRef = db.collection('account_deletion_jobs').doc(uid);
  await jobRef.set({ uid, status: 'running', startedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
  try {
    const userDocRef = db.collection('users').doc(uid);
    const userSnap = await userDocRef.get();
    if (userSnap.exists) {
      const u = userSnap.data();
      await deleteManyStorageUrls([u.profileImageUrl, u.barrelImageUrl, u.photoURL, u.photoUrl]);
      await safeRecursiveDelete(userDocRef);
    }
    await deleteDocsByQuery(db.collection('community').where('userId', '==', uid), { beforeDeleteEach: async (d) => await deleteManyStorageUrls([d.data().photoUrl, d.data().userPhotoUrl]) });
    await deleteDocsByQuery(db.collection('my_logs').where('userId', '==', uid), { beforeDeleteEach: async (d) => { const p = d.data().photoUrls; const urls = Array.isArray(p) ? p : (p && typeof p === 'object' ? Object.values(p) : [p]); await deleteManyStorageUrls(urls); } });
    await deleteDocsByQuery(db.collection('tournaments').where('createdByUid', '==', uid), { beforeDeleteEach: async (d) => await deleteManyStorageUrls([d.data().posterUrl]) });
    await admin.auth().deleteUser(uid);
    await jobRef.set({ status: 'done', finishedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
    return { ok: true };
  } catch (e) { await jobRef.set({ status: 'failed', error: String(e) }, { merge: true }); throw new functions.https.HttpsError('internal', '삭제 실패'); }
});

// ====================== Firestore Delete Triggers ======================

async function cleanupImageFieldOnDelete(snap, fieldNames = []) {
  const data = snap.data() || {}; const urls = [];
  fieldNames.forEach(f => { const v = data[f]; if (Array.isArray(v)) urls.push(...v); else if (v && typeof v === 'object') urls.push(...Object.values(v)); else if (typeof v === 'string') urls.push(v); });
  await deleteManyStorageUrls(urls);
}

exports.onSponsorDeleted = functions.region('asia-northeast3').firestore.document('sponsors/{docId}').onDelete(snap => cleanupImageFieldOnDelete(snap, ['imageUrl']));
exports.onCompetitionPhotoDeleted = functions.region('asia-northeast3').firestore.document('competition_photos/{docId}').onDelete(snap => cleanupImageFieldOnDelete(snap, ['imageUrl']));
exports.onNewsDeleted = functions.region('asia-northeast3').firestore.document('news/{docId}').onDelete(snap => cleanupImageFieldOnDelete(snap, ['imageUrl']));
exports.onTournamentDeleted = functions.region('asia-northeast3').firestore.document('tournaments/{tournamentId}').onDelete(snap => cleanupImageFieldOnDelete(snap, ['posterUrl']));
exports.onCommunityPostDeleted = functions.region('asia-northeast3').firestore.document('community/{postId}').onDelete(snap => cleanupImageFieldOnDelete(snap, ['photoUrl', 'userPhotoUrl']));
exports.onMyLogDeleted = functions.region('asia-northeast3').firestore.document('my_logs/{logId}').onDelete(snap => cleanupImageFieldOnDelete(snap, ['photoUrls']));
exports.onUserDeleted = functions.region('asia-northeast3').firestore.document('users/{uid}').onDelete(snap => cleanupImageFieldOnDelete(snap, ['profileImageUrl', 'barrelImageUrl', 'photoURL', 'photoUrl']));