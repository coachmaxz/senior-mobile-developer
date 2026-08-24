import { useEffect } from "react";
import { useMap } from "react-leaflet";

interface MapViewControllerProps {
  start: [number, number];
  destination: [number, number];
}

export default function MapViewController({
  start,
  destination,
}: MapViewControllerProps) {
  const map = useMap();
  useEffect(() => {
    map.fitBounds([start, destination], {
      padding: [60, 60],
      maxZoom: 15,
    });
  }, [map, start, destination]);
  return null;
}