const { setGlobalOptions } = require("firebase-functions/v2");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();
setGlobalOptions({ maxInstances: 10, region: "us-central1" });

const db = admin.firestore();
const messaging = admin.messaging();
const auth = admin.auth();

const ALL_USERS_TOPIC = "all_users";

async function isAdmin(uid) {
  if (!uid) return false;
  const doc = await db.collection("admins").doc(uid).get();
  return doc.exists;
}

function requireAdmin(request) {
  return isAdmin(request.auth && request.auth.uid).then((ok) => {
    if (!ok) {
      throw new HttpsError(
        "permission-denied",
        "You must be an admin to do this."
      );
    }
  });
}

async function sendToToken(token, payload) {
  if (!token) return;
  try {
    await messaging.send({ token, ...payload });
  } catch (err) {
    logger.warn("Failed to send notification to token", token, err.message);
  }
}

// ---------------------------------------------------------------------------
// Match created -> notify both matched users.
// ---------------------------------------------------------------------------
exports.onMatchCreated = onDocumentCreated(
  "matches/{matchId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const data = snap.data();
    const users = data.users || [];
    if (users.length !== 2) return;

    const [uidA, uidB] = users;
    const [profileA, profileB] = await Promise.all([
      db.collection("users").doc(uidA).get(),
      db.collection("users").doc(uidB).get(),
    ]);

    const nameA = profileA.exists ? profileA.data().name : "Someone";
    const nameB = profileB.exists ? profileB.data().name : "Someone";
    const tokenA = profileA.exists ? profileA.data().fcmToken : null;
    const tokenB = profileB.exists ? profileB.data().fcmToken : null;

    await Promise.all([
      sendToToken(tokenA, {
        notification: {
          title: "It's a Match! ❤️",
          body: `You and ${nameB} liked each other on Kisela.`,
        },
        data: { type: "match", matchId: event.params.matchId },
      }),
      sendToToken(tokenB, {
        notification: {
          title: "It's a Match! ❤️",
          body: `You and ${nameA} liked each other on Kisela.`,
        },
        data: { type: "match", matchId: event.params.matchId },
      }),
    ]);
  }
);

// ---------------------------------------------------------------------------
// New chat message -> notify the recipient (not the sender).
// ---------------------------------------------------------------------------
exports.onMessageCreated = onDocumentCreated(
  "matches/{matchId}/messages/{messageId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const message = snap.data();
    const matchId = event.params.matchId;

    const matchDoc = await db.collection("matches").doc(matchId).get();
    if (!matchDoc.exists) return;
    const users = matchDoc.data().users || [];
    const recipientUid = users.find((u) => u !== message.senderId);
    if (!recipientUid) return;

    const [senderDoc, recipientDoc] = await Promise.all([
      db.collection("users").doc(message.senderId).get(),
      db.collection("users").doc(recipientUid).get(),
    ]);
    if (!recipientDoc.exists) return;

    const senderName = senderDoc.exists ? senderDoc.data().name : "Someone";
    const token = recipientDoc.data().fcmToken;

    await sendToToken(token, {
      notification: {
        title: `${senderName} sent you a message`,
        body: message.text || "New message",
      },
      data: { type: "message", matchId },
    });
  }
);

// ---------------------------------------------------------------------------
// Admin: send a broadcast notification to every user right now.
// ---------------------------------------------------------------------------
exports.sendBroadcastNotification = onCall(async (request) => {
  await requireAdmin(request);
  const { title, body } = request.data || {};
  if (!title || !body) {
    throw new HttpsError("invalid-argument", "title and body are required.");
  }

  await messaging.send({
    topic: ALL_USERS_TOPIC,
    notification: { title, body },
    data: { type: "broadcast" },
  });

  await db.collection("scheduledNotifications").add({
    title,
    body,
    sendAt: admin.firestore.FieldValue.serverTimestamp(),
    status: "sent",
    sentAt: admin.firestore.FieldValue.serverTimestamp(),
    createdBy: request.auth.uid,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { ok: true };
});

// ---------------------------------------------------------------------------
// Admin: schedule a broadcast notification for a future time.
// ---------------------------------------------------------------------------
exports.scheduleBroadcastNotification = onCall(async (request) => {
  await requireAdmin(request);
  const { title, body, sendAtMillis } = request.data || {};
  if (!title || !body || !sendAtMillis) {
    throw new HttpsError(
      "invalid-argument",
      "title, body and sendAtMillis are required."
    );
  }

  const docRef = await db.collection("scheduledNotifications").add({
    title,
    body,
    sendAt: admin.firestore.Timestamp.fromMillis(sendAtMillis),
    status: "pending",
    createdBy: request.auth.uid,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { ok: true, id: docRef.id };
});

// ---------------------------------------------------------------------------
// Admin: cancel a pending scheduled notification.
// ---------------------------------------------------------------------------
exports.cancelScheduledNotification = onCall(async (request) => {
  await requireAdmin(request);
  const { id } = request.data || {};
  if (!id) {
    throw new HttpsError("invalid-argument", "id is required.");
  }
  const ref = db.collection("scheduledNotifications").doc(id);
  const doc = await ref.get();
  if (!doc.exists || doc.data().status !== "pending") {
    throw new HttpsError("failed-precondition", "Nothing pending to cancel.");
  }
  await ref.update({ status: "cancelled" });
  return { ok: true };
});

// ---------------------------------------------------------------------------
// Runs every 5 minutes: sends any scheduled notifications that are due.
// ---------------------------------------------------------------------------
exports.processScheduledNotifications = onSchedule("every 5 minutes", async () => {
  const now = admin.firestore.Timestamp.now();
  const dueSnap = await db
    .collection("scheduledNotifications")
    .where("status", "==", "pending")
    .where("sendAt", "<=", now)
    .get();

  if (dueSnap.empty) return;

  await Promise.all(
    dueSnap.docs.map(async (doc) => {
      const { title, body } = doc.data();
      try {
        await messaging.send({
          topic: ALL_USERS_TOPIC,
          notification: { title, body },
          data: { type: "broadcast" },
        });
        await doc.ref.update({
          status: "sent",
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } catch (err) {
        logger.error("Failed to send scheduled notification", doc.id, err);
        await doc.ref.update({ status: "failed", error: err.message });
      }
    })
  );
});

// ---------------------------------------------------------------------------
// Admin: create a brand new user (Auth account + Firestore profile).
// ---------------------------------------------------------------------------
exports.adminCreateUser = onCall(async (request) => {
  await requireAdmin(request);
  const { email, password, name, age, gender, bio } = request.data || {};
  if (!email || !password || !name || !age || !gender) {
    throw new HttpsError(
      "invalid-argument",
      "email, password, name, age and gender are required."
    );
  }

  const userRecord = await auth.createUser({ email, password });
  await db
    .collection("users")
    .doc(userRecord.uid)
    .set({
      name,
      age,
      gender,
      bio: bio || "",
      photoUrl: "",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

  return { ok: true, uid: userRecord.uid };
});

// ---------------------------------------------------------------------------
// Admin: fully delete a user (Auth account + Firestore profile).
// ---------------------------------------------------------------------------
exports.adminDeleteUser = onCall(async (request) => {
  await requireAdmin(request);
  const { uid } = request.data || {};
  if (!uid) {
    throw new HttpsError("invalid-argument", "uid is required.");
  }

  await db.collection("users").doc(uid).delete();
  try {
    await auth.deleteUser(uid);
  } catch (err) {
    logger.warn("Auth user already gone or failed to delete", uid, err.message);
  }

  return { ok: true };
});
