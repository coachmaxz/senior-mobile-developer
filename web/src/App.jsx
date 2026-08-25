import { useEffect, useState } from "react";
import { useNavigate } from "react-router";

import TrackingMap from "./components/TrackingMap";
import { getFetchMemberLists, getFetchTrackingLists, getFetchLocations } from "./services/api";

function App() {

  const navigate = useNavigate();
  const searchParams = new URLSearchParams(window.location.search);
  
  const uuid = searchParams.get('uuid');
  const trackingId = searchParams.get('trackingId');

  const accessToken = searchParams.get('accessToken');

  const [startPosition, setStartPosition] = useState([]);
  const [destinationPosition, setDestinationPosition] = useState([]);

  const [mode, setMode] = useState("member"); // member, tracking, localtion
  const [members, setMembers] = useState([]);

  const [track, setTrack] = useState([]);
  const [trackLists, setTrackLists] = useState([]);

  const [loading, setLoading] = useState(false);
  const [tracking, setTracking] = useState(true);

  const loadMapWithLocations = async (realtimeLocation) => {
    if (realtimeLocation[0].lat > 0 && realtimeLocation[0].lng > 0) {
      const firstTrack = [ realtimeLocation[0].lat, realtimeLocation[0].lng ];
      const lastTrack = [ realtimeLocation[realtimeLocation.length - 1].lat, realtimeLocation[realtimeLocation.length - 1].lng ];
      setStartPosition(firstTrack);
      setDestinationPosition(lastTrack);
      setTracking(true);
      setLoading(false);
      setTrack(realtimeLocation.map((location, key) => {
        return [ location.lat, location.lng ];
      }));
    }
  }

  async function getFetchLocation() {
    try {
      if (accessToken == "" || accessToken == null) { setTracking(false); return; }
      setLoading(true);
      const resMemberLists = await getFetchMemberLists(accessToken);
      if (resMemberLists.status == 200 && resMemberLists.data.length > 0) {
        setMembers(resMemberLists.data);
      }
      if (uuid != "" && uuid != null) {
        const resTrackingLists = await getFetchTrackingLists(uuid, accessToken);
        if (resTrackingLists.status == 200 && resTrackingLists.data.length > 0) {
          console.log(resTrackingLists.data);
          setTrackLists(resTrackingLists.data);
        }
        if (trackingId != "" && trackingId != null) {
          const resRealtimeLocation = await getFetchLocations(uuid, trackingId, accessToken);
          if (resRealtimeLocation.status == 200 && resRealtimeLocation.data.length > 0) {
            loadMapWithLocations(resRealtimeLocation.data);
          }
        }
      }
    } catch (err) {
      setLoading(false);
    } finally {
      setLoading(false);
    }
  }

  async function onGoTo(location) {
    if (mode == 'member' && location != null && location != "") {
      navigate(`?uuid=${location.uuid}&accessToken=${accessToken}`);
      window.location.reload();
      return;
    }
    if (mode == 'tracking' && location != null && location != "") {
      navigate(`?uuid=${location.uuid}&trackingId=${location.trackingId}&accessToken=${accessToken}`);
      window.location.reload();
      return;
    }
  }

  async function onBack() {
    if (mode == 'localtion') {
      navigate(`?uuid=${uuid}&accessToken=${accessToken}`); 
      window.location.reload();
      return;
    }
    if (mode == 'tracking') {
      navigate(`?accessToken=${accessToken}`); 
      window.location.reload();
      return;
    }
  }

  const formatDateTH = (timestamp) => {
    const datetime = new Date(timestamp);
    return datetime.toLocaleDateString('th-TH', { 
      year: 'numeric',
      month: 'numeric',
      day: 'numeric',
      hour: 'numeric',
      minute: 'numeric',
      second: 'numeric',
      calendar: 'buddhist'
    });
  }

  useEffect(() => {
    getFetchLocation();
    if (uuid != null && uuid != "" && trackingId != null && trackingId != "") {
      setMode("localtion");
      return;
    }
    if (uuid != null && uuid != "") {
      setMode("tracking");
      return;
    }
    setMode("member");
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
            { mode != "member" && (
              <button onClick={onBack} className="rounded-lg bg-white/10 px-4 py-2 text-sm hover:bg-white/20">
                Back
              </button>
            )}
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
      </main> : <div className="grid h-full grid-cols-1 gap-4">
        <section className="overflow-hidden rounded-xl bg-white shadow icon-container">
          {!loading && members.length > 0 && trackLists.length == 0 && members.map((member, i) => {
            return (
              <a key={i} className="max-w-md text-white member text-center" onClick={() => onGoTo(member, null)}>
                <div className="relative">
                  <img className="w-12 h-12" src={"src/assets/ic-person.png"} alt="person" />
                  {/* <span className="top-0 left-7 absolute w-3.5 h-3.5 bg-success border-2 border-buffer rounded-full"></span> */}
                </div>
              </a>
            );
          })}
          {!loading && members.length > 0 && trackLists.length > 0 && trackLists.map((tracks, i) => {
            return (
              <a key={i} className="max-w-md text-white track text-center" onClick={() => onGoTo(tracks, null)}>
                <div className="relative">
                  <img className="w-15 h-15" src={"src/assets/ic-tracking.png"} alt="tracking" />
                  <span className="">{formatDateTH(tracks.createdAt)}</span>
                </div>
              </a>
            );
          })}
        </section>
      </div>}
    </div>
  );

}

export default App;