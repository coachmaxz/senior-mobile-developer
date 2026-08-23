import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();
// const db = admin.database();

export const helloWorld = functions.https.onCall(async (data, context) => {
  return {success: true, status: "active", data: data, context: context};
});
