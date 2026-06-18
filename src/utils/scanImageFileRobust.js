import { Html5Qrcode, Html5QrcodeSupportedFormats } from 'html5-qrcode';

const SCAN_VARIANTS = [
  { scale: 2, mode: 'contrast' },
  { scale: 3, mode: 'contrast' },
  { scale: 3, mode: 'threshold' },
];

function loadImage(file) {
  return new Promise((resolve, reject) => {
    const url = URL.createObjectURL(file);
    const image = new Image();
    image.onload = () => {
      URL.revokeObjectURL(url);
      resolve(image);
    };
    image.onerror = () => {
      URL.revokeObjectURL(url);
      reject(new Error('image load failed'));
    };
    image.src = url;
  });
}

function clampChannel(value) {
  return Math.max(0, Math.min(255, value));
}

function enhanceImageData(imageData, mode) {
  const data = imageData.data;
  for (let i = 0; i < data.length; i += 4) {
    const gray = data[i] * 0.299 + data[i + 1] * 0.587 + data[i + 2] * 0.114;
    const value = mode === 'threshold'
      ? (gray > 145 ? 255 : 0)
      : clampChannel((gray - 128) * 1.65 + 128);
    data[i] = value;
    data[i + 1] = value;
    data[i + 2] = value;
  }
  return imageData;
}

async function createEnhancedFile(file, variant, index) {
  const image = await loadImage(file);
  const canvas = document.createElement('canvas');
  canvas.width = Math.max(1, Math.round(image.naturalWidth * variant.scale));
  canvas.height = Math.max(1, Math.round(image.naturalHeight * variant.scale));

  const context = canvas.getContext('2d', { willReadFrequently: true });
  context.imageSmoothingEnabled = false;
  context.drawImage(image, 0, 0, canvas.width, canvas.height);
  const imageData = context.getImageData(0, 0, canvas.width, canvas.height);
  context.putImageData(enhanceImageData(imageData, variant.mode), 0, 0);

  const blob = await new Promise((resolve, reject) => {
    canvas.toBlob((nextBlob) => {
      if (nextBlob) resolve(nextBlob);
      else reject(new Error('canvas export failed'));
    }, 'image/png');
  });
  return new File([blob], `scan-enhanced-${index}.png`, { type: 'image/png' });
}

async function tryScanFile(scanner, file) {
  try {
    return await scanner.scanFile(file, false);
  } catch {
    return null;
  }
}

export async function scanImageFileRobust(file, scannerElementId) {
  const scanner = new Html5Qrcode(scannerElementId, {
    formatsToSupport: [Html5QrcodeSupportedFormats.QR_CODE],
  });

  try {
    const originalCode = await tryScanFile(scanner, file);
    if (originalCode) return originalCode;

    for (let i = 0; i < SCAN_VARIANTS.length; i += 1) {
      const enhancedFile = await createEnhancedFile(file, SCAN_VARIANTS[i], i);
      const enhancedCode = await tryScanFile(scanner, enhancedFile);
      if (enhancedCode) return enhancedCode;
    }
  } finally {
    scanner.clear();
  }

  throw new Error('QR code not found');
}
