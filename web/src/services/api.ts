import type { Tracker, TrackerResponse } from "../types/tracker";

const API_URL = "https://api-xa65ksosta-uc.a.run.app";
const UUID = "453f546b-381a-4815-af41-866535a2d8bd";

export async function getFetchLocations(): Promise<TrackerResponse> {
  const response = await fetch(`${API_URL}/tracking/${UUID}`);
  if (!response.ok) { throw new Error("Failed to fetch tracking"); }
  return response.json();
}