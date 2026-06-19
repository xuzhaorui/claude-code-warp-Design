// Single source of truth for scanner access across business pages.
//
// Inside the Flutter APK the WebView exposes window.ScannerChannel, which routes
// scan requests to the Flutter native ScannerPage (mobile_scanner / ML Kit). In a
// plain browser the channel is absent and callers fall back to the existing
// ScannerOverlay / html5-qrcode path.
//
// Wire contract: docs/flutter-scanner-migration/01-migration-spec.md §5.
//   Web  -> Flutter : ScannerChannel.postMessage(JSON { type, requestId, mode })
//   Flutter -> Web  : window.dispatchEvent(CustomEvent 'warehouse-scan-result')

const SCAN_RESULT_EVENT = 'warehouse-scan-result';
// A single scan may wait on the operator for a while; keep the listener alive but
// bound it so a dropped Flutter response cannot leak forever.
const SCAN_TIMEOUT_MS = 5 * 60 * 1000;

export function isFlutterScannerAvailable() {
  return Boolean(typeof window !== 'undefined' && window.ScannerChannel);
}

export async function scanWarehouseCode({ mode } = {}) {
  const channel = typeof window !== 'undefined' ? window.ScannerChannel : null;
  if (!channel) {
    throw new Error('FLUTTER_SCANNER_NOT_AVAILABLE');
  }

  const requestId = `scan_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;

  return new Promise((resolve, reject) => {
    let settled = false;
    let timeoutId = null;

    const cleanup = () => {
      if (timeoutId) clearTimeout(timeoutId);
      window.removeEventListener(SCAN_RESULT_EVENT, onResult);
    };

    const onResult = (event) => {
      const detail = event?.detail;
      if (!detail || detail.requestId !== requestId) return;
      if (settled) return;
      settled = true;
      cleanup();
      if (detail.ok) {
        resolve({
          text: detail.text,
          format: detail.format,
          source: detail.source || 'flutter-mobile-scanner',
        });
      } else {
        const error = new Error(detail.message || '扫码失败');
        error.code = detail.errorCode || 'SCAN_FAILED';
        reject(error);
      }
    };

    window.addEventListener(SCAN_RESULT_EVENT, onResult);
    timeoutId = setTimeout(() => {
      if (settled) return;
      settled = true;
      cleanup();
      const error = new Error('扫码超时');
      error.code = 'SCAN_TIMEOUT';
      reject(error);
    }, SCAN_TIMEOUT_MS);

    try {
      channel.postMessage(JSON.stringify({ type: 'scan', requestId, mode }));
    } catch (err) {
      if (settled) return;
      settled = true;
      cleanup();
      reject(err);
    }
  });
}
