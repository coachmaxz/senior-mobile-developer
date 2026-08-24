import { useEffect, useState } from "react";
import TrackingMap from "./components/TrackingMap";

import { getFetchLocations } from "./services/api";

function App() {

  const [startPosition, setStartPosition] = useState([]);
  const [destinationPosition, setDestinationPosition] = useState([]);

  const [track, setTrack] = useState([]);

  const [loading, setLoading] = useState(false);
  const [tracking, setTracking] = useState(true);

  async function getFetchLocation() {
    try {
      setLoading(true);
      const response = await getFetchLocations();
      if (response.data.realtimeLocation.length > 0) {
        if (response.data.realtimeLocation[0].lat > 0 && response.data.realtimeLocation[0].lng > 0) {
          const firstTrack = [ response.data.realtimeLocation[0].lat, response.data.realtimeLocation[0].lng ];
          const lastTrack = [ response.data.realtimeLocation[response.data.realtimeLocation.length - 1].lat, response.data.realtimeLocation[response.data.realtimeLocation.length - 1].lng ];
          setStartPosition(firstTrack);
          setDestinationPosition(lastTrack);
          setTracking(true);
          setLoading(false);
          setTrack(response.data.realtimeLocation.map((location, key) => {
            return [ location.lat, location.lng ];
          }));
        }
      }
    } catch (err) {
      setLoading(false);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    getFetchLocation();
  }, []);

  return (
    <div className="h-screen bg-gray-100">
      <header className="h-16 bg-gray-900 text-white flex items-center justify-between px-6">
        <div>
          <h1 className="text-xl font-bold text-left">
            GPS Tracking
          </h1>
          <p className="text-xs text-gray-400 text-left">
            Realtime Location Dashboard
          </p>
        </div>
        <div className="flex items-center gap-3">
          <div className="flex items-center gap-2">
            <span className={`h-3 w-3 rounded-full ${tracking ? "bg-green-500" : "bg-red-500"}`} />
            <span>{tracking ? "Tracking" : "Offline"}</span>
          </div>
        </div>
      </header>
      {!loading && startPosition.length > 0 ? <main className="h-[calc(94vh-64px)] p-4">
        <div className="grid h-full grid-cols-1 gap-4">
          <section className="overflow-hidden rounded-xl bg-white shadow">
            <TrackingMap
              startPosition={startPosition}
              destinationPosition={destinationPosition}
              track={track}
            />
          </section>
        </div>
      </main> : <></>}
    </div>
  );

}

export default App;