// c:\Users\jha95\OneDrive\Documents\PROJECT\enterprise-oms\admin-portal\src\components\LiveTrackingMap.jsx
import React, { useEffect, useRef, useState, useCallback } from 'react';
import {
  MapContainer, TileLayer, Marker, Polyline,
  Popup, useMap, CircleMarker, useMapEvents
} from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { Maximize2, Minimize2, Layers, Navigation2, Clock, Route, AlertCircle } from 'lucide-react';

// ─── Fix Leaflet default icon broken in Vite ───────────────────────────────
delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
  iconUrl:       'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
  shadowUrl:     'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
});

// ─── Agent colors ──────────────────────────────────────────────────────────
const AGENT_COLORS = ['#ef4444', '#f59e0b', '#8b5cf6', '#06b6d4', '#10b981'];

// ─── Tile Layers (Light auto-detects from theme) ───────────────────────────
const TILES = {
  // Dark tiles
  dark: {
    label: '🌑 Dark',
    url: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
    attribution: '© <a href="https://carto.com/">CARTO</a>',
    maxZoom: 19,
    theme: 'dark',
  },
  // Light tiles  
  light: {
    label: '☀️ Light',
    url: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
    attribution: '© <a href="https://carto.com/">CARTO</a>',
    maxZoom: 19,
    theme: 'light',
  },
  // Street
  street: {
    label: '🗺️ Street',
    url: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
    attribution: '© <a href="https://www.openstreetmap.org/">OpenStreetMap</a>',
    maxZoom: 19,
    theme: 'any',
  },
  // Satellite
  satellite: {
    label: '🛰️ Satellite',
    url: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    attribution: '© Esri',
    maxZoom: 18,
    theme: 'any',
  },
};

// ─── HQ Marker ─────────────────────────────────────────────────────────────
const HQ_ICON = L.divIcon({
  html: `<div style="
    width:40px;height:40px;border-radius:50%;
    background:linear-gradient(135deg,#1d4ed8,#3b82f6);
    border:3px solid #fff;
    box-shadow:0 0 0 4px rgba(37,99,235,0.25),0 4px 20px rgba(37,99,235,0.5);
    display:flex;align-items:center;justify-content:center;
    color:#fff;font-size:11px;font-weight:800;font-family:sans-serif;
    letter-spacing:0.5px;
  ">HQ</div>`,
  className: '',
  iconSize: [40, 40],
  iconAnchor: [20, 20],
  popupAnchor: [0, -24],
});

// ─── Agent Marker ──────────────────────────────────────────────────────────
const makeAgentIcon = (color, initials) => L.divIcon({
  html: `
  <div class="agent-marker-wrap" style="position:relative;width:44px;height:56px;">
    <!-- Pulse ring -->
    <div style="
      position:absolute;top:2px;left:2px;
      width:36px;height:36px;border-radius:50%;
      background:${color};opacity:0.18;
      animation:agentRing 2s infinite;
    "></div>
    <!-- Body -->
    <div style="
      position:absolute;top:4px;left:4px;
      width:32px;height:32px;border-radius:50%;
      background:${color};
      border:2.5px solid #fff;
      box-shadow:0 2px 12px ${color}99;
      display:flex;align-items:center;justify-content:center;
      color:#fff;font-size:10px;font-weight:800;font-family:sans-serif;
    ">${initials}</div>
    <!-- Pointer -->
    <div style="
      position:absolute;bottom:0;left:50%;transform:translateX(-50%);
      width:0;height:0;
      border-left:7px solid transparent;
      border-right:7px solid transparent;
      border-top:14px solid ${color};
      filter:drop-shadow(0 2px 4px ${color}66);
    "></div>
  </div>`,
  className: '',
  iconSize: [44, 56],
  iconAnchor: [22, 56],
  popupAnchor: [0, -58],
});

// ─── Destination Marker ────────────────────────────────────────────────────
const makeDestIcon = (color) => L.divIcon({
  html: `<div style="
    width:22px;height:22px;border-radius:50%;
    border:3px solid ${color};
    background:${color}22;
    box-shadow:0 0 0 4px ${color}33;
    display:flex;align-items:center;justify-content:center;
  "><div style="width:7px;height:7px;border-radius:50%;background:${color};"></div></div>`,
  className: '',
  iconSize: [22, 22],
  iconAnchor: [11, 11],
  popupAnchor: [0, -14],
});

// ─── No OSRM Routing: User requested actual GPS history only ──────────

// ─── Map auto-fit controller ───────────────────────────────────────────────
function MapController({ duties, isFullscreen }) {
  const map = useMap();

  useEffect(() => {
    const pts = [];
    duties
      .filter(d => d.status === 'Active' && (d.coordinates || d.Coordinates || []).length > 0)
      .forEach(d => (d.coordinates || d.Coordinates || []).forEach(c => {
        const lat = c.lat || c.latitude || c.Latitude;
        const lng = c.lng || c.longitude || c.Longitude;
        if (lat !== undefined && lng !== undefined && !isNaN(lat) && !isNaN(lng)) {
          pts.push([lat, lng]);
        }
      }));

    pts.push([28.5494, 77.2519]); // always include HQ

    if (pts.length > 1) {
      map.fitBounds(L.latLngBounds(pts), { padding: [56, 56], animate: true, duration: 0.8 });
    } else {
      map.setView([28.5494, 77.2519], 14, { animate: true });
    }
  }, [duties, map]);

  useEffect(() => {
    setTimeout(() => map.invalidateSize(), 320);
  }, [isFullscreen, map]);

  return null;
}

// ─── Helpers ───────────────────────────────────────────────────────────────
const fmtDist = (m) =>
  m >= 1000 ? `${(m / 1000).toFixed(1)} km` : `${Math.round(m)} m`;

const fmtTime = (s) => {
  if (s < 60) return `${Math.round(s)}s`;
  if (s < 3600) return `${Math.round(s / 60)} min`;
  return `${Math.floor(s / 3600)}h ${Math.round((s % 3600) / 60)}m`;
};

const initials = (name = '') =>
  name.split(' ').map(w => w[0]).join('').slice(0, 2).toUpperCase();

// ─── Main Component ────────────────────────────────────────────────────────
export default function LiveTrackingMap({ duties = [], theme = 'theme-light' }) {
  const isDark = theme === 'theme-dark';

  // Auto-select tile based on theme; user can override
  const [tileKey, setTileKey] = useState(() => isDark ? 'dark' : 'light');
  const [showLayerMenu, setShowLayerMenu] = useState(false);
  const [isFullscreen, setIsFullscreen] = useState(false);
  const [selectedAgent, setSelectedAgent] = useState(null);
  const layerMenuRef = useRef(null);

  // Sync tile with theme changes
  useEffect(() => {
    // Only auto-switch if currently on a theme-bound layer
    const cur = TILES[tileKey];
    if (cur.theme !== 'any') {
      setTileKey(isDark ? 'dark' : 'light');
    }
  }, [isDark]);

  // Close layer menu on outside click
  useEffect(() => {
    const h = (e) => {
      if (layerMenuRef.current && !layerMenuRef.current.contains(e.target)) {
        setShowLayerMenu(false);
      }
    };
    document.addEventListener('mousedown', h);
    return () => document.removeEventListener('mousedown', h);
  }, []);

  // ESC exits fullscreen
  useEffect(() => {
    const h = (e) => { if (e.key === 'Escape') setIsFullscreen(false); };
    document.addEventListener('keydown', h);
    return () => document.removeEventListener('keydown', h);
  }, []);

  const activeDuties = duties.filter(d => d.status === 'Active');
  const tile = TILES[tileKey];
  const HQ = [28.5494, 77.2519];

  // Theme-aware UI colors
  const ui = isDark
    ? {
        header: 'rgba(6,10,18,0.96)',
        headerBorder: 'rgba(59,130,246,0.18)',
        text: '#e8edf5',
        textSub: '#8b9cb8',
        accent: '#3b82f6',
        card: 'rgba(10,16,32,0.92)',
        cardBorder: 'rgba(59,130,246,0.15)',
        menuBg: 'rgba(10,16,32,0.97)',
        menuBorder: 'rgba(59,130,246,0.2)',
        legendBg: 'rgba(6,10,18,0.88)',
        scrollbar: '#1e2d45',
      }
    : {
        header: 'rgba(255,255,255,0.97)',
        headerBorder: 'rgba(37,99,235,0.12)',
        text: '#0d1117',
        textSub: '#4b5563',
        accent: '#2563eb',
        card: 'rgba(255,255,255,0.96)',
        cardBorder: 'rgba(37,99,235,0.15)',
        menuBg: 'rgba(255,255,255,0.98)',
        menuBorder: 'rgba(226,232,240,1)',
        legendBg: 'rgba(255,255,255,0.92)',
        scrollbar: '#e2e8f0',
      };

  return (
    <div style={{
      position: isFullscreen ? 'fixed' : 'relative',
      inset: isFullscreen ? 0 : 'unset',
      zIndex: isFullscreen ? 99999 : 1,
      width: '100%',
      height: isFullscreen ? '100vh' : '100%',
      display: 'flex',
      flexDirection: 'column',
      overflow: 'hidden',
      background: isDark ? '#060a12' : '#f0f4f8',
      borderRadius: isFullscreen ? 0 : '0 0 12px 12px',
    }}>

      {/* ── Top bar */}
      <div style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        padding: '8px 14px',
        background: ui.header,
        borderBottom: `1px solid ${ui.headerBorder}`,
        flexShrink: 0,
        zIndex: 1000,
        backdropFilter: 'blur(12px)',
        gap: 10,
        boxShadow: isDark
          ? '0 1px 0 rgba(255,255,255,0.03)'
          : '0 1px 3px rgba(0,0,0,0.06)',
      }}>
        {/* Left: live badge + count */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{
            width: 8, height: 8, borderRadius: '50%',
            background: '#10b981',
            boxShadow: '0 0 8px #10b981',
            flexShrink: 0,
            animation: 'pulse 1.5s infinite',
          }} />
          <span style={{
            color: ui.text,
            fontWeight: 700,
            fontSize: 12.5,
            fontFamily: 'var(--font-display)',
            letterSpacing: '-0.01em',
          }}>
            IOD Live Field Ops
          </span>
          <span style={{
            background: isDark ? 'rgba(59,130,246,0.15)' : '#dbeafe',
            border: `1px solid ${isDark ? 'rgba(59,130,246,0.3)' : '#bfdbfe'}`,
            color: '#2563eb',
            fontSize: 9.5,
            fontWeight: 700,
            padding: '2px 8px',
            borderRadius: 99,
            letterSpacing: '0.07em',
          }}>
            {activeDuties.length} ACTIVE
          </span>
        </div>

        {/* Right: controls */}
        <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
          {/* Layer menu */}
          <div ref={layerMenuRef} style={{ position: 'relative' }}>
            <button
              onClick={() => setShowLayerMenu(v => !v)}
              style={{
                background: isDark ? 'rgba(255,255,255,0.05)' : '#f1f5f9',
                border: `1px solid ${isDark ? 'rgba(255,255,255,0.1)' : '#e2e8f0'}`,
                color: ui.textSub,
                padding: '5px 9px',
                borderRadius: 6,
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                gap: 5,
                fontSize: 11.5,
                fontFamily: 'var(--font-sans)',
                transition: 'all 0.15s',
              }}
            >
              <Layers size={12} /> {tile.label}
            </button>
            {showLayerMenu && (
              <div style={{
                position: 'absolute',
                top: 'calc(100% + 4px)',
                right: 0,
                background: ui.menuBg,
                border: `1px solid ${ui.menuBorder}`,
                borderRadius: 10,
                overflow: 'hidden',
                boxShadow: isDark ? '0 20px 40px rgba(0,0,0,0.7)' : '0 8px 24px rgba(0,0,0,0.12)',
                zIndex: 10000,
                minWidth: 150,
                backdropFilter: 'blur(16px)',
              }}>
                {Object.entries(TILES).map(([k, t]) => (
                  <button
                    key={k}
                    onClick={() => { setTileKey(k); setShowLayerMenu(false); }}
                    style={{
                      display: 'block',
                      width: '100%',
                      padding: '8px 14px',
                      background: tileKey === k
                        ? (isDark ? 'rgba(59,130,246,0.18)' : '#eff6ff')
                        : 'transparent',
                      border: 'none',
                      color: tileKey === k ? '#2563eb' : ui.textSub,
                      fontSize: 12.5,
                      fontWeight: tileKey === k ? 700 : 400,
                      cursor: 'pointer',
                      textAlign: 'left',
                      fontFamily: 'var(--font-sans)',
                      borderBottom: `1px solid ${isDark ? 'rgba(255,255,255,0.04)' : '#f1f5f9'}`,
                      transition: 'background 0.1s',
                    }}
                  >
                    {t.label}
                  </button>
                ))}
              </div>
            )}
          </div>

          {/* Fullscreen */}
          <button
            onClick={() => setIsFullscreen(v => !v)}
            title={isFullscreen ? 'Exit fullscreen' : 'Fullscreen'}
            style={{
              background: isDark ? 'rgba(255,255,255,0.05)' : '#f1f5f9',
              border: `1px solid ${isDark ? 'rgba(255,255,255,0.1)' : '#e2e8f0'}`,
              color: ui.textSub,
              width: 30, height: 30,
              borderRadius: 6,
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              transition: 'all 0.15s',
            }}
            onMouseEnter={e => { e.currentTarget.style.background = isDark ? 'rgba(59,130,246,0.18)' : '#eff6ff'; e.currentTarget.style.color = '#2563eb'; }}
            onMouseLeave={e => { e.currentTarget.style.background = isDark ? 'rgba(255,255,255,0.05)' : '#f1f5f9'; e.currentTarget.style.color = ui.textSub; }}
          >
            {isFullscreen ? <Minimize2 size={14} /> : <Maximize2 size={14} />}
          </button>
        </div>
      </div>

      {/* ── Map area + sidebar for fullscreen */}
      <div style={{ flex: 1, display: 'flex', overflow: 'hidden', position: 'relative' }}>

        {/* Google-Maps-style Info Panel (when fullscreen) */}
        {isFullscreen && activeDuties.length > 0 && (
          <div style={{
            width: 290,
            flexShrink: 0,
            background: ui.card,
            backdropFilter: 'blur(12px)',
            borderRight: `1px solid ${ui.cardBorder}`,
            overflowY: 'auto',
            zIndex: 2,
            boxShadow: isDark ? '4px 0 24px rgba(0,0,0,0.5)' : '4px 0 16px rgba(0,0,0,0.06)',
          }}>
            <div style={{ padding: '14px 16px', borderBottom: `1px solid ${ui.cardBorder}` }}>
              <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.08em', color: ui.textSub, textTransform: 'uppercase', marginBottom: 2 }}>
                Field Agents — Road Directions
              </div>
              <div style={{ fontSize: 12, color: ui.textSub }}>Click an agent to focus on map</div>
            </div>
            {activeDuties.map((duty, idx) => {
              const color = AGENT_COLORS[idx % AGENT_COLORS.length];
              const coordsArr = duty.coordinates || duty.Coordinates || [];
              const hasRoute = coordsArr.length > 1;
              return (
                <div
                  key={duty.id}
                  onClick={() => setSelectedAgent(duty.id === selectedAgent ? null : duty.id)}
                  style={{
                    padding: '14px 16px',
                    borderBottom: `1px solid ${ui.cardBorder}`,
                    cursor: 'pointer',
                    background: selectedAgent === duty.id
                      ? (isDark ? 'rgba(59,130,246,0.1)' : '#eff6ff')
                      : 'transparent',
                    transition: 'background 0.15s',
                  }}
                >
                  {/* Agent header */}
                  <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 8 }}>
                    <div style={{
                      width: 34, height: 34, borderRadius: '50%',
                      background: color,
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                      color: '#fff', fontSize: 11, fontWeight: 800,
                      flexShrink: 0,
                      boxShadow: `0 0 0 3px ${color}33`,
                    }}>
                      {initials(duty.employeeName)}
                    </div>
                    <div>
                      <div style={{ fontWeight: 700, fontSize: 13, color: ui.text }}>{duty.employeeName}</div>
                      <div style={{ fontSize: 11, color: ui.textSub }}>📍 {duty.destination}</div>
                    </div>
                  </div>

                  {/* Route info */}
                  {hasRoute ? (
                    <div style={{
                      background: isDark ? 'rgba(255,255,255,0.04)' : '#f8fafc',
                      border: `1px solid ${ui.cardBorder}`,
                      borderRadius: 8,
                      padding: '8px 12px',
                      display: 'flex',
                      gap: 16,
                      fontSize: 11.5,
                      color: ui.textSub,
                      justifyContent: 'center',
                    }}>
                      Tracking Actual Travel Route
                    </div>
                  ) : (
                    <div style={{ fontSize: 11, color: ui.textSub, display: 'flex', alignItems: 'center', gap: 4 }}>
                      <AlertCircle size={11} /> Waiting for more GPS pings
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        )}

        {/* ── Leaflet Map ───────────────────────────────────────────── */}
        <div style={{ flex: 1, position: 'relative' }}>
          <MapContainer
            center={HQ}
            zoom={14}
            style={{ width: '100%', height: '100%' }}
            zoomControl
          >
            <TileLayer
              key={tileKey}
              url={tile.url}
              attribution={tile.attribution}
              maxZoom={tile.maxZoom}
            />

            <MapController duties={duties} isFullscreen={isFullscreen} />

            {/* HQ Marker */}
            <Marker position={HQ} icon={HQ_ICON}>
              <Popup>
                <div style={{ fontFamily: 'sans-serif', minWidth: 170 }}>
                  <div style={{ fontWeight: 800, fontSize: 13, color: '#1d4ed8', marginBottom: 4 }}>
                    🏢 IOD GK-II Headquarters
                  </div>
                  <div style={{ fontSize: 12, color: '#64748b' }}>Greater Kailash-II, New Delhi</div>
                  <div style={{ fontSize: 10.5, color: '#94a3b8', marginTop: 5, fontFamily: 'monospace' }}>
                    28.5494°N, 77.2519°E
                  </div>
                </div>
              </Popup>
            </Marker>

            {/* Active Agents */}
            {activeDuties.map((duty, idx) => {
              const color = AGENT_COLORS[idx % AGENT_COLORS.length];
              const coordsArr = duty.coordinates || duty.Coordinates || [];
              const coords = coordsArr
                .map(c => [c.lat ?? c.latitude ?? c.Latitude, c.lng ?? c.longitude ?? c.Longitude])
                .filter(p => p[0] != null && p[1] != null && !isNaN(p[0]) && !isNaN(p[1]));
              const lastCoord = coords[coords.length - 1];
              if (!lastCoord) return null;

              return (
                <React.Fragment key={duty.id}>
                  {/* ── Actual GPS Travel Route ── */}
                  {coords.length > 1 && (
                    <>
                      {/* Shadow for route */}
                      <Polyline
                        positions={coords}
                        pathOptions={{
                          color: '#fff',
                          weight: 7,
                          opacity: isDark ? 0.08 : 0.4,
                          lineCap: 'round',
                          lineJoin: 'round'
                        }}
                      />
                      {/* Main actual travel line */}
                      <Polyline
                        positions={coords}
                        pathOptions={{
                          color,
                          weight: 4,
                          opacity: 0.9,
                          lineCap: 'round',
                          lineJoin: 'round'
                        }}
                      />
                    </>
                  )}

                  {/* Historical dots */}
                  {coords.slice(0, -1).map((c, i) => (
                    <CircleMarker
                      key={i}
                      center={c}
                      radius={3}
                      pathOptions={{
                        color,
                        fillColor: color,
                        fillOpacity: (i + 1) / coords.length * 0.45,
                        weight: 1,
                        opacity: 0.35,
                      }}
                    />
                  ))}

                  {/* Agent Marker */}
                  <Marker
                    position={lastCoord}
                    icon={makeAgentIcon(color, initials(duty.employeeName))}
                  >
                    <Popup>
                      <div style={{ fontFamily: 'sans-serif', minWidth: 210 }}>
                        {/* Header */}
                        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 10 }}>
                          <div style={{
                            width: 36, height: 36, borderRadius: '50%',
                            background: color,
                            display: 'flex', alignItems: 'center', justifyContent: 'center',
                            color: '#fff', fontSize: 12, fontWeight: 800, flexShrink: 0,
                          }}>
                            {initials(duty.employeeName)}
                          </div>
                          <div>
                            <div style={{ fontWeight: 800, fontSize: 13.5, color: '#0f172a', lineHeight: 1.2 }}>
                              {duty.employeeName}
                            </div>
                            <div style={{ display: 'flex', alignItems: 'center', gap: 4, marginTop: 2 }}>
                              <span style={{ background: '#fee2e2', color: '#dc2626', fontSize: 9, fontWeight: 800, padding: '1px 5px', borderRadius: 3 }}>LIVE</span>
                              <span style={{ fontSize: 11, color: '#64748b' }}>On Duty</span>
                            </div>
                          </div>
                        </div>

                        {/* Info */}
                        <div style={{ display: 'flex', flexDirection: 'column', gap: 5, fontSize: 12, color: '#475569' }}>
                          <div><strong style={{ color: '#334155' }}>Destination:</strong> {duty.destination}</div>
                          <div><strong style={{ color: '#334155' }}>Purpose:</strong> {duty.reason}</div>
                        </div>

                        {/* GPS Stats Info */}
                        <div style={{
                          marginTop: 10, padding: '8px 12px',
                          background: '#f8fafc',
                          borderRadius: 8,
                          border: '1px solid #e2e8f0',
                          display: 'flex',
                          justifyContent: 'center',
                          color: '#64748b',
                          fontSize: 11
                        }}>
                          Live travel route tracking
                        </div>

                        {/* Coordinates */}
                        <div style={{ marginTop: 8, fontSize: 10.5, color: '#94a3b8', fontFamily: 'monospace', borderTop: '1px solid #f1f5f9', paddingTop: 7 }}>
                          {(lastCoord[0] || 0).toFixed(6)}°N  {(lastCoord[1] || 0).toFixed(6)}°E
                        </div>
                      </div>
                    </Popup>
                  </Marker>
                </React.Fragment>
              );
            })}
          </MapContainer>

          {/* ── Compact legend (always visible) */}
          <div style={{
            position: 'absolute',
            bottom: 18, right: isFullscreen ? 18 : 12,
            background: ui.legendBg,
            backdropFilter: 'blur(12px)',
            border: `1px solid ${ui.cardBorder}`,
            borderRadius: 10,
            padding: '10px 14px',
            zIndex: 999,
            display: 'flex',
            flexDirection: 'column',
            gap: 6,
            fontSize: 11,
            color: ui.textSub,
            pointerEvents: 'none',
            fontFamily: 'var(--font-mono)',
            boxShadow: isDark ? '0 8px 24px rgba(0,0,0,0.5)' : '0 4px 12px rgba(0,0,0,0.08)',
          }}>
            <div style={{ fontWeight: 700, fontSize: 9, letterSpacing: '0.08em', color: ui.textSub, textTransform: 'uppercase', marginBottom: 2 }}>
              Legend
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 7 }}>
              <div style={{ width: 11, height: 11, borderRadius: '50%', background: '#2563eb', boxShadow: '0 0 5px #2563eb44' }} />
              HQ Office
            </div>
            {activeDuties.map((d, i) => {
              const c = AGENT_COLORS[i % AGENT_COLORS.length];
              return (
                <div key={d.id} style={{ display: 'flex', alignItems: 'center', gap: 7 }}>
                  <div style={{ width: 10, height: 10, borderRadius: '50%', background: c, boxShadow: `0 0 4px ${c}66` }} />
                  <span>{d.employeeName.split(' ')[0]}</span>
                </div>
              );
            })}
          </div>

          {/* Fullscreen ESC hint */}
          {isFullscreen && (
            <div style={{
              position: 'absolute',
              top: 12, left: '50%',
              transform: 'translateX(-50%)',
              background: isDark ? 'rgba(6,10,18,0.85)' : 'rgba(255,255,255,0.9)',
              border: `1px solid ${ui.cardBorder}`,
              color: ui.textSub,
              fontSize: 11,
              padding: '4px 14px',
              borderRadius: 99,
              zIndex: 1000,
              pointerEvents: 'none',
              fontFamily: 'var(--font-mono)',
              backdropFilter: 'blur(8px)',
            }}>
              <kbd style={{ background: ui.card, padding: '0 5px', borderRadius: 3 }}>ESC</kbd> or ⊡ to exit fullscreen
            </div>
          )}
        </div>
      </div>

      {/* Inline styles for animation */}
      <style>{`
        @keyframes agentRing {
          0%   { transform: scale(0.9); opacity: 0.5; }
          50%  { transform: scale(1.4); opacity: 0; }
          100% { transform: scale(0.9); opacity: 0; }
        }
        @keyframes spin {
          from { transform: rotate(0deg); }
          to   { transform: rotate(360deg); }
        }
        @keyframes pulse {
          0%,100% { opacity:1; }
          50%     { opacity:0.4; }
        }
      `}</style>
    </div>
  );
}
