import * as admin from "firebase-admin";
import express from "express";

admin.initializeApp();

const db = admin.database();
const router = express.Router();

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

router.get("/lists", async (req: any, res: any) => {
  await isCheckByAccessToken(req, res);
  const memberData = await db.ref("members").once("value");
  const memberLists: any = [];
  if (memberData.exists()) {
    const memberValues = memberData.val();
    Object.keys(memberValues).forEach((memberKey: any) => {
      memberLists.push({
        uuid: memberKey,
        ...memberValues[memberKey],
      });
    });
  }
  res.status(200).json({
    status: 200,
    message: "OK",
    data: memberLists,
  });
});

router.get("/:uuid", async (req: any, res: any) => {
  await isCheckByAccessToken(req, res);
  await isCheckByUuid(req, res);
  const memberData = await db.ref(`members/${req.params.uuid}`).once("value");
  res.status(200).json({
    status: 200,
    message: "OK",
    data: memberData,
  });
});

router.put("/fcmToken/:uuid", async (req: any, res: any) => {
  await isCheckByAccessToken(req, res);
  await isCheckByUuid(req, res);
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

export default router;
