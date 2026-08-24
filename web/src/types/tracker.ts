export type TrackerStatus = | "online" | "offline";

export interface Tracker {
  id: string;
  name: string;
  lat: number;
  lng: number;
  speed: number;
  heading: number;
  status: TrackerStatus;
  updatedAt: string;
}

export interface TrackerResponse {
  data: Tracker[];
}