import type { Tracker, TrackerResponse } from "../types/tracker";

const API_URL = "https://api-xa65ksosta-uc.a.run.app";
const UUID = "453f546b-381a-4815-af41-866535a2d8bd";

export async function getFetchMemberLists(accessToken: String): Promise<TrackerResponse> {
  const response = await fetch(`${API_URL}/member/lists?accessToken=${accessToken}`);
  if (!response.ok) { throw new Error("Failed to fetch tracking"); }
  return response.json();
}

export async function getFetchTrackingLists(uuid: String, accessToken: String): Promise<TrackerResponse> {
  const response = await fetch(`${API_URL}/tracking/lists/${uuid}?accessToken=${accessToken}`);
  if (!response.ok) { throw new Error("Failed to fetch tracking"); }
  return response.json();
}

export async function getFetchLocations(uuid: String, trackingId: String, accessToken: String): Promise<TrackerResponse> {
  const response = await fetch(`${API_URL}/tracking/detail/${uuid}/${trackingId}?accessToken=${accessToken}`);
  if (!response.ok) { throw new Error("Failed to fetch tracking"); }
  return response.json();
}