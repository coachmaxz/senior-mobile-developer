import * as admin from "firebase-admin";
import express from "express";

admin.initializeApp();

const db = admin.database();
const trackingRouter = express.Router();

const isCheckByUuid = async (req: any, res: any) => {
  if (req.params.uuid == null || req.params.uuid == "" || req.params.uuid == undefined) {
    res.status(403).json({
      status: 403,
      message: "FORBIDDEN",
    });
    return;
  }
  const checkMember = await db.ref(`members/${req.params.uuid}`).once("value");
  if (!checkMember.exists()) {
    const now = Date.now();
    await db.ref(`members/${req.params.uuid}`).set({
      lastChanged: now,
      status: "new",
    });
    // res.status(404).json({
    //   status: 404,
    //   message: "NOT FOUND",
    // });
    // return;
  }
};

const isCheckByAccessToken = async (req: any, res: any) => {
  if (req.query.accessToken == null || req.query.accessToken == "" || req.query.accessToken == undefined) {
    res.status(403).json({
      status: 403,
      message: "FORBIDDEN",
    });
    return;
  }
  if (req.query.accessToken != "cQoSR9GLJBPAknS11gNHHBk3iZ-ABceMgIY5JWaQ") {
    res.status(403).json({
      status: 403,
      message: "FORBIDDEN",
    });
    return;
  }
};

const convertTrackingToJSON = (data: any) => {
  return {
    uuid: data.uuid ?? null,
    trackingId: data.trackingId ?? null,
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

trackingRouter.get("/currentLocation/:uuid", async (req: any, res: any) => {
  await isCheckByAccessToken(req, res);
  await isCheckByUuid(req, res);
  const currentLocation = await db.ref(`members/${req.params.uuid}/currentLocation`).once("value");
  res.status(200).json({
    status: 200,
    message: "OK",
    data: (
      currentLocation.exists() ?
      {
        ...convertTrackingToJSON(currentLocation.val()),
        uuid: req.params.uuid,
      } :
      null
    ),
  });
});

trackingRouter.get("/lists/:uuid", async (req: any, res: any) => {
  await isCheckByAccessToken(req, res);
  await isCheckByUuid(req, res);
  const realtimeLocation = await db.ref(`trackings/${req.params.uuid}/realtimeLocation`).once("value");
  const locationLists: any = [];
  if (realtimeLocation.exists()) {
    const locationValues = realtimeLocation.val();
    Object.keys(locationValues).forEach((trackingId: any) => {
      let firstlocationList: any = Object.values(locationValues[trackingId]);
      firstlocationList = firstlocationList.length > 0 ? firstlocationList[0] : null;
      locationLists.push({
        uuid: req.params.uuid,
        trackingId: trackingId,
        locationCount: Object.keys(locationValues[trackingId]).length ?? 0,
        createdAt: firstlocationList.timestamp,
      });
    });
  }
  res.status(200).json({
    status: 200,
    message: "OK",
    data: locationLists,
  });
});

trackingRouter.get("/detail/:uuid/:trackingId", async (req: any, res: any) => {
  await isCheckByAccessToken(req, res);
  await isCheckByUuid(req, res);
  const realtimeLocation = await db.ref(`trackings/${req.params.uuid}/realtimeLocation/${req.params.trackingId}`).once("value");
  const locationLists: any = [];
  if (realtimeLocation.exists()) {
    const locationValues = realtimeLocation.val();
    Object.values(locationValues).forEach((locationList: any) => {
      locationLists.push({
        ...convertTrackingToJSON(locationList),
        uuid: req.params.uuid,
        trackingId: req.params.trackingId ?? "",
      });
    });
  }
  res.status(200).json({
    status: 200,
    message: "OK",
    data: locationLists,
  });
});

trackingRouter.get("/:uuid", async (req: any, res: any) => {
  await isCheckByAccessToken(req, res);
  await isCheckByUuid(req, res);
  const realtimeLocation = await db.ref(`trackings/${req.params.uuid}/realtimeLocation`).once("value");
  const locationLists: any = [];
  if (realtimeLocation.exists()) {
    const locationValues = realtimeLocation.val();
    Object.keys(locationValues).forEach((trackingId: any) => {
      locationLists.push({
        uuid: req.params.uuid,
        trackingId: trackingId,
        locationLists: Object.values(locationValues[trackingId]).map((localtion: any) => {
          return {
            ...convertTrackingToJSON(localtion),
            uuid: req.params.uuid,
            trackingId: trackingId,
          };
        }),
      });
    });
  }
  res.status(200).json({
    status: 200,
    message: "OK",
    data: locationLists,
  });
});

trackingRouter.post("/start/:uuid", async (req: any, res: any) => {
  await isCheckByAccessToken(req, res);
  await isCheckByUuid(req, res);
  const now = Date.now();
  const bodyParams = {
    ...convertTrackingToJSON(req.body.location),
    uuid: req.params.uuid,
    trackingId: req.body.trackingId,
  };
  await db.ref(`members/${req.params.uuid}`).update({
    currentLocation: bodyParams,
    lastChanged: now,
    lastTrackingId: req.body.trackingId ?? null,
    status: "riding",
  });
  res.status(201).json({
    status: 201,
    message: "CREATED",
    data: {
      uuid: req.params.uuid,
      lastChanged: now,
      trackingId: req.body.trackingId ?? null,
      status: "riding",
    },
  });
});

trackingRouter.post("/:uuid", async (req: any, res: any) => {
  await isCheckByAccessToken(req, res);
  await isCheckByUuid(req, res);
  const now = Date.now();
  const trackingId = req.body.trackingId ?? now;
  const bodyParams = {
    ...convertTrackingToJSON(req.body.location),
    uuid: req.params.uuid,
    trackingId: trackingId,
  };
  await db.ref(`members/${req.params.uuid}`).update({
    currentLocation: bodyParams,
    lastChanged: now,
    lastTrackingId: trackingId,
    status: "online",
  });
  const ref = db.ref(`trackings/${req.params.uuid}/realtimeLocation/${trackingId}/${now}`);
  await ref.set(bodyParams);
  res.status(201).json({
    status: 201,
    message: "CREATED",
    data: {
      key: now,
      status: "online",
      ...bodyParams,
    },
  });
});

trackingRouter.put("/currentLocation/:uuid", async (req: any, res: any) => {
  await isCheckByAccessToken(req, res);
  await isCheckByUuid(req, res);
  const now = Date.now();
  const bodyParams = {
    ...convertTrackingToJSON(req.body.location),
    uuid: req.params.uuid,
    trackingId: req.body.trackingId,
  };
  await db.ref(`members/${req.params.uuid}`).update({
    currentLocation: bodyParams,
    lastTrackingId: req.body.trackingId,
    lastChanged: now,
  });
  res.status(200).json({
    status: 200,
    message: "UPDATED",
    data: {
      lastChanged: now,
      ...bodyParams,
    },
  });
});

trackingRouter.put("/presence/:uuid", async (req: any, res: any) => {
  await isCheckByAccessToken(req, res);
  await isCheckByUuid(req, res);
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

trackingRouter.put("/stop/:uuid", async (req: any, res: any) => {
  await isCheckByAccessToken(req, res);
  await isCheckByUuid(req, res);
  const now = Date.now();
  await db.ref(`members/${req.params.uuid}`).update({
    lastChanged: now,
    status: "stopped",
  });
  res.status(200).json({
    status: 200,
    message: "UPDATED",
    data: {
      lastChanged: now,
      status: "stopped",
    },
  });
});

export default trackingRouter;
