import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

import express from "express";
import cors from "cors";

admin.initializeApp();

const app = express();
const db = admin.database();

app.use(cors({origin: true}));

const isCheckUUID = async (req: any, res: any) => {
  if (req.params.uuid == "" || req.params.uuid == null || req.params.uuid == undefined) {
    res.status(500).json({
      status: 500,
      message: "SERVER ERROR",
    });
    return false;
  } else {
    const checkUUID = await db.ref(`members/${req.params.uuid}/status`).once("value");
    if (!checkUUID.exists()) {
      res.status(404).json({
        status: 404,
        message: "NOT FOUND",
      });
      return false;
    }
  }
  return true;
};

app.get("/tracking/realtimeLocation/:uuid", async (req, res) => {
  await isCheckUUID(req, res);
  const realtimeLocation = await db.ref(`members/${req.params.uuid}/realtimeLocation`).once("value");
  const locationLists: any = [];
  if (realtimeLocation.exists()) {
    const locationValues = realtimeLocation.val();
    Object.values(locationValues).forEach((locationList: any) => {
      locationLists.push({
        "accuracy": locationList.accuracy ?? 0,
        "altitude": locationList.altitude ?? 0,
        "battery": locationList.battery ?? 0,
        "heading": locationList.heading ?? 0,
        "isMoving": locationList.isMoving ?? false,
        "lat": locationList.lat ?? 0,
        "lng": locationList.lng ?? 0,
        "speed": locationList.speed ?? 0,
        "timestamp": locationList.timestamp ?? 0,
        "updatedAt": locationList.updatedAt ?? 0,
      });
    });
  }
  res.status(200).json({
    status: 200,
    message: "OK",
    data: {
      uuid: req.params.uuid,
      realtimeLocation: locationLists,
    },
  });
});

app.get("/tracking/currentLocation/:uuid", async (req, res) => {
  await isCheckUUID(req, res);
  const currentLocation = await db.ref(`members/${req.params.uuid}/currentLocation`).once("value");
  if (currentLocation.exists()) {
    const locationValue: any = currentLocation.val();
    const locationList: any = {
      "accuracy": locationValue.accuracy ?? 0,
      "altitude": locationValue.altitude ?? 0,
      "battery": locationValue.battery ?? 0,
      "heading": locationValue.heading ?? 0,
      "isMoving": locationValue.isMoving ?? false,
      "lat": locationValue.lat ?? 0,
      "lng": locationValue.lng ?? 0,
      "speed": locationValue.speed ?? 0,
      "timestamp": locationValue.timestamp ?? 0,
      "updatedAt": locationValue.updatedAt ?? 0,
    };
    res.status(200).json({
      status: 200,
      message: "OK",
      data: {
        uuid: req.params.uuid,
        currentLocation: locationList,
      },
    });
  }
  res.status(200).json({
    status: 200,
    message: "OK",
    data: {
      uuid: req.params.uuid,
      currentLocation: null,
    },
  });
});

app.get("/tracking/:uuid", async (req, res) => {
  await isCheckUUID(req, res);
  const realtimeLocation = await db.ref(`members/${req.params.uuid}/realtimeLocation`).once("value");
  const locationLists: any = [];
  if (realtimeLocation.exists()) {
    const locationValues = realtimeLocation.val();
    Object.values(locationValues).forEach((locationList: any) => {
      locationLists.push({
        "accuracy": locationList.accuracy ?? 0,
        "altitude": locationList.altitude ?? 0,
        "battery": locationList.battery ?? 0,
        "heading": locationList.heading ?? 0,
        "isMoving": locationList.isMoving ?? false,
        "lat": locationList.lat ?? 0,
        "lng": locationList.lng ?? 0,
        "speed": locationList.speed ?? 0,
        "timestamp": locationList.timestamp ?? 0,
        "updatedAt": locationList.updatedAt ?? 0,
      });
    });
  }
  res.status(200).json({
    status: 200,
    message: "OK",
    data: {
      uuid: req.params.uuid,
      realtimeLocation: locationLists,
    },
  });
});

app.post("/tracking/start/:uuid", async (req, res) => {
  await isCheckUUID(req, res);
  const now = Date.now();
  await db.ref(`members/${req.params.uuid}`).update({
    lastChanged: now,
    status: "riding",
  });
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

app.post("/tracking/:uuid", async (req, res) => {
  await isCheckUUID(req, res);
  const bodyParams: any = {
    lat: req.body.lat ?? 0,
    lng: req.body.lng ?? 0,
    speed: req.body.speed ?? 0,
    heading: req.body.heading ?? 0,
    accuracy: req.body.accuracy ?? 0,
    altitude: req.body.altitude ?? 0,
    battery: req.body.battery ?? 0,
    isMoving: req.body.isMoving ?? true,
    timestamp: req.body.timestamp ?? 0,
  };
  await db.ref(`members/${req.params.uuid}/realtimeLocation/${req.body.timestamp}`).set(bodyParams);
  const now = Date.now();
  await db.ref(`members/${req.params.uuid}`).update({
    currentLocation: bodyParams,
    lastChanged: now,
    status: "online",
  });
  res.status(201).json({
    status: 201,
    message: "CREATED",
    data: {
      uuid: req.params.uuid,
      body: bodyParams,
      lastChanged: now,
      status: "online",
    },
  });
});

app.put("/tracking/currentLocation/:uuid", async (req, res) => {
  await isCheckUUID(req, res);
  const bodyParams: any = {
    lat: req.body.lat ?? 0,
    lng: req.body.lng ?? 0,
    speed: req.body.speed ?? 0,
    heading: req.body.heading ?? 0,
    accuracy: req.body.accuracy ?? 0,
    altitude: req.body.altitude ?? 0,
    battery: req.body.battery ?? 0,
    isMoving: req.body.isMoving ?? true,
    timestamp: req.body.timestamp ?? 0,
  };
  const now = Date.now();
  await db.ref(`members/${req.params.uuid}`).update({
    currentLocation: bodyParams,
    lastChanged: now,
  });
  res.status(200).json({
    status: 200,
    message: "UPDATED",
    data: {
      uuid: req.params.uuid,
      body: bodyParams,
      lastChanged: now,
    },
  });
});

app.put("/tracking/presence/:uuid", async (req, res) => {
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

app.put("/tracking/fcmToken/:uuid", async (req, res) => {
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

app.put("/tracking/stop/:uuid", async (req, res) => {
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

exports.api = functions.https.onRequest(app);
