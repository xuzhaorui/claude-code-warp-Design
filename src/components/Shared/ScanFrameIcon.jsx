export default function ScanFrameIcon({ size = 20, animated = false }) {
  return (
    <svg width={size} height={size} viewBox="0 0 100 100" fill="none">
      {/* Top-left corner */}
      <path d="M4 32V8a4 4 0 0 1 4-4h20" stroke="currentColor" strokeWidth="7" strokeLinecap="round" />
      {/* Top-right corner */}
      <path d="M72 4h20a4 4 0 0 1 4 4v24" stroke="currentColor" strokeWidth="7" strokeLinecap="round" />
      {/* Bottom-left corner */}
      <path d="M4 68v24a4 4 0 0 0 4 4h20" stroke="currentColor" strokeWidth="7" strokeLinecap="round" />
      {/* Bottom-right corner */}
      <path d="M68 96h24a4 4 0 0 0 4-4V72" stroke="currentColor" strokeWidth="7" strokeLinecap="round" />

      {/* Scan line with gradient */}
      <defs>
        <linearGradient id="scanGrad" x1="0" y1="0" x2="1" y2="0">
          <stop offset="0%" stopColor="currentColor" stopOpacity="0.1" />
          <stop offset="50%" stopColor="currentColor" stopOpacity="1" />
          <stop offset="100%" stopColor="currentColor" stopOpacity="0.1" />
        </linearGradient>
      </defs>
      <rect
        x="16" y="47" width="68" height="3" rx="1.5" fill="url(#scanGrad)"
        style={animated ? { animation: 'scanLineMove 2s ease-in-out infinite', willChange: 'transform' } : undefined}
      />
    </svg>
  );
}
