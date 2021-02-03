const functions = require("firebase-functions");

const admin = require("firebase-admin");

var serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

 exports.helloWorld = functions.https.onRequest((request, response) => {
   functions.logger.info("Hello logs!", {structuredData: true});
   response.send("Hello from Loyd Firebase!");
 });

 exports.sendMessage = functions.https.onRequest(async (request, response) => {
await admin.messaging().sendMulticast({
  tokens: ["Your_FCM_Token_One", "Your_FCM_Token_Two"],
  notification: {
    title: "Hello Loyd!",
    body: "This message is from Cloud Function",
    imageUrl: "https://yt3.ggpht.com/ytc/AAUvwnjuH8xEOYQyRAE2NMrVieRw0GBbcJ9l5wLPpvgHDQ=s88-c-k-c0x00ffffff-no-rj",
  },
});

  response.json({result: "Sending message done"});
 });


