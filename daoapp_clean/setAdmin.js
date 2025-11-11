// setAdmin.js
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json'); // 이거 추가!

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const uid = 'NanHPgCdsbMCFkHEs7MtxS51OSX2'; // 너의 UID!

admin.auth().setCustomUserClaims(uid, { admin: true })
  .then(() => {
    console.log('관리자 권한 부여 완료!');
    process.exit(0);
  })
  .catch(error => {
    console.log('에러:', error);
    process.exit(1);
  });