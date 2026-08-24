import { MapContainer, TileLayer, Marker, Popup, Polyline, Circle, } from "react-leaflet";

import L from "leaflet";

import "leaflet/dist/leaflet.css";
import MapViewController from "./MapViewController";

delete L.Icon.Default.prototype._getIconUrl;

L.Icon.Default.mergeOptions({
  iconRetinaUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png",
  iconUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png",
  shadowUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png",
});

const startIcon = L.divIcon({
  className: "",
  html: `
    <div style="
      width: 32px;
      height: 32px;
      background: #16a34a;
      border: 3px solid white;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      color: white;
      font-weight: bold;
      box-shadow: 0 2px 6px rgba(0,0,0,.3);
    ">
      S
    </div>
  `,
  iconSize: [32, 32],
  iconAnchor: [16, 16],
});

const destinationIcon = L.divIcon({
  className: "",
  html: `
    <div style="
      width: 32px;
      height: 32px;
      background: #dc2626;
      border: 3px solid white;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      color: white;
      font-weight: bold;
      box-shadow: 0 2px 6px rgba(0,0,0,.3);
    ">
      E
    </div>
  `,
  iconSize: [32, 32],
  iconAnchor: [16, 16],
});

export default function TrackingMap({ startPosition, destinationPosition, track }) {
  return (
    <MapContainer center={startPosition} zoom={16} className="h-full w-full">
      <TileLayer
        attribution='&copy; OpenStreetMap contributors'
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
      />
      <Circle 
        center={startPosition} 
        adius={30}  
        pathOptions={{
          fillOpacity: 0.1,
        }} 
      />
      <MapViewController
        start={startPosition}
        destination={destinationPosition}
      />
      <Marker position={startPosition} icon={startIcon}>
        <Popup>
          <strong>{"จุดเริ่มต้น"}</strong>
          <div>Latitude: {startPosition[0].toFixed(6)}</div>
          <div>Longitude: {startPosition[1].toFixed(6)}</div>
        </Popup>
      </Marker>
      <Marker position={destinationPosition} icon={destinationIcon}>
        <Popup>
          <strong>{"จุดปลายทาง"}</strong>
          <div>Latitude: {destinationPosition[0].toFixed(6)}</div>
          <div>Longitude: {destinationPosition[1].toFixed(6)}</div>
        </Popup>
      </Marker>
      {track.length > 1 && (
        <Polyline 
          positions={track} 
          pathOptions={{ 
            weight: 5,
            // dashArray: "5, 5",
          }} 
        />
      )}
    </MapContainer>
  );

}