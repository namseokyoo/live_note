/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {onRequest} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const functions = require("firebase-functions");

admin.initializeApp();

exports.verifyNoteAccess = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', '인증이 필요합니다');
  }

  const { noteId, password } = data;
  
  try {
    const noteSnapshot = await admin.database().ref(`notes/${noteId}`).get();
    const noteData = noteSnapshot.val();
    
    if (!noteData) {
      throw new functions.https.HttpsError('not-found', '노트를 찾을 수 없습니다');
    }

    const isHost = noteData.hostPassword === password;
    const isGuest = noteData.guestPassword === password;
    
    if (!isHost && !isGuest) {
      throw new functions.https.HttpsError('permission-denied', '잘못된 비밀번호입니다');
    }

    return { 
      isHost: isHost 
    };
  } catch (error) {
    throw new functions.https.HttpsError('internal', error.message);
  }
});
