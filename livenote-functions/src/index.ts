import {onRequest} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

admin.initializeApp();

export const createCustomToken = onRequest(async (request, response) => {
  const { uid, username, password } = request.body;
  
  try {
    const customToken = await admin.auth().createCustomToken(uid, {
      username: username,
      password: password
    });
    
    response.json({ token: customToken });
  } catch (error) {
    response.status(500).send(error);
  }
});
