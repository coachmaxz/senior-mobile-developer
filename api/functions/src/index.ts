import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

import express from "express";
import cors from "cors";

admin.initializeApp();

const app = express();
const db = admin.database();

app.use(cors({origin: true}));

const isCheckByUuid = async (req: any, res: any) => {
  const checkUUID = await db.ref(`members/${req.params.uuid}/status`).once("value");
  if (!checkUUID.exists()) {
    res.status(404).json({
      status: 404,
      message: "NOT FOUND",
    });
    return;
  }
};

const convertTrackingToJSON = (data: any) => {
  return {
    accuracy: data.accuracy ?? 0,
    altitude: data.altitude ?? 0,
    battery: data.battery ?? 0,
    heading: data.heading ?? 0,
    isMoving: data.isMoving ?? false,
    lat: data.lat ?? 0,
    lng: data.lng ?? 0,
    speed: data.speed ?? 0,
    timestamp: data.timestamp ?? 0,
    updatedAt: data.updatedAt ?? 0,
  };
};

// ========================================================
// Tracking
// ========================================================

app.get("/tracking/currentLocation/:uuid", async (req: any, res: any) => {
  await isCheckByUuid(req, res);
  const currentLocation = await db.ref(`members/${req.params.uuid}/currentLocation`).once("value");
  res.status(200).json({
    status: 200,
    message: "OK",
    data: (
      currentLocation.exists() ?
      convertTrackingToJSON(currentLocation.val()) :
      null
    ),
  });
});

app.get("/tracking/:uuid", async (req: any, res: any) => {
  await isCheckByUuid(req, res);
  const realtimeLocation = await db.ref(`trackings/${req.params.uuid}/realtimeLocation`).once("value");
  const locationLists: any = [];
  if (realtimeLocation.exists()) {
    const locationValues = realtimeLocation.val();
    Object.values(locationValues).forEach((locationList: any) => {
      locationLists.push(convertTrackingToJSON(locationList));
    });
  }
  res.status(200).json({
    status: 200,
    message: "OK",
    data: locationLists,
  });
});

app.post("/tracking/start/:uuid", async (req: any, res: any) => {
  await isCheckByUuid(req, res);
  const now = Date.now();
  await db.ref(`members/${req.params.uuid}`).update({
    lastChanged: now,
    status: "riding",
  });
  await db.ref(`trackings/${req.params.uuid}/realtimeLocation`).remove();
  res.status(201).json({
    status: 201,
    message: "CREATED",
    data: {
      uuid: req.params.uuid,
      lastChanged: now,
      status: "riding",
    },
  });
});

app.post("/tracking/:uuid", async (req: any, res: any) => {
  await isCheckByUuid(req, res);
  const bodyParams = convertTrackingToJSON(req.body);
  const now = Date.now();
  await db.ref(`members/${req.params.uuid}`).update({
    currentLocation: bodyParams,
    lastChanged: now,
    status: "online",
  });
  const ref = db.ref(`trackings/${req.params.uuid}/realtimeLocation`);
  const newItemRef = await ref.push(bodyParams);
  res.status(201).json({
    status: 201,
    message: "CREATED",
    data: {
      uuid: req.params.uuid,
      key: newItemRef.key,
      status: "online",
      ...bodyParams,
    },
  });
});

app.put("/tracking/currentLocation/:uuid", async (req: any, res: any) => {
  await isCheckByUuid(req, res);
  const now = Date.now();
  const bodyParams = convertTrackingToJSON(req.body);
  await db.ref(`members/${req.params.uuid}`).update({
    currentLocation: bodyParams,
    lastChanged: now,
  });
  res.status(200).json({
    status: 200,
    message: "UPDATED",
    data: {
      uuid: req.params.uuid,
      lastChanged: now,
      ...bodyParams,
    },
  });
});

// ========================================================
// Member
// ========================================================

app.get("/member/:uuid", async (req: any, res: any) => {
  await isCheckByUuid(req, res);
  const memberData = await db.ref(`members/${req.params.uuid}`).once("value");
  res.status(200).json({
    status: 200,
    message: "OK",
    data: memberData,
  });
});

/*
app.put("/tracking/presence/:uuid", async (req: any, res: any) => {
  await isCheckUUID(req, res);
  const now = Date.now();
  await db.ref(`members/${req.params.uuid}`).update({
    lastChanged: now,
    status: "online",
  });
  res.status(200).json({
    status: 200,
    message: "UPDATED",
    data: {
      uuid: req.params.uuid,
      lastChanged: now,
      status: "online",
    },
  });
});

app.put("/tracking/fcmToken/:uuid", async (req: any, res: any) => {
  await isCheckUUID(req, res);
  const now = Date.now();
  await db.ref(`members/${req.params.uuid}`).update({
    fcmToken: req.body.fcmToken ?? "",
    lastChanged: now,
  });
  res.status(200).json({
    status: 200,
    message: "UPDATED",
    data: {
      uuid: req.params.uuid,
      fcmToken: req.body.fcmToken ?? "",
      lastChanged: now,
    },
  });
});

app.put("/tracking/stop/:uuid", async (req: any, res: any) => {
  await isCheckUUID(req, res);
  const now = Date.now();
  await db.ref(`members/${req.params.uuid}`).update({
    lastChanged: now,
    status: "stopped",
  });
  res.status(200).json({
    status: 200,
    message: "UPDATED",
  });
});
*/

exports.api = functions.https.onRequest(app);
