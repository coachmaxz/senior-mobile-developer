import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

import express from "express";
import cors from "cors";

import trackingRoutes from "./routes/tracking.route";
import memberRoutes from "./routes/member.route";

admin.initializeApp();

const app = express();

app.use(cors({origin: true}));
app.use(express.json());
app.use(express.urlencoded({extended: true}));

app.use("/tracking", trackingRoutes);
app.use("/member", memberRoutes);

exports.api = functions.https.onRequest(app);
