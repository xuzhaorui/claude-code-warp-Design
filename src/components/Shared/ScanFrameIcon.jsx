export default function ScanFrameIcon({ size = 20, animated = false }) {
  const s = size;
  const corner = s * 0.3;
  return (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" style={{ position: 'relative' }}>
      <path d={`M3 ${corner}V3h${corner}`} stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
      <path d={`M${24 - corner} 3H21v${corner}`} stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
      <path d={`M3 ${24 - corner}V21h${corner}`} stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
      <path d={`M${24 - corner} 21H21v${-corner}`} stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
      <line
        x1="5" y1="12" x2="19" y2="12"
        stroke="currentColor" strokeWidth="1.5" strokeLinecap="round"
        style={animated ? { animation: 'scanLineMove 2s ease-in-out infinite alternate' } : undefined}
      />
    </svg>
  );
}
