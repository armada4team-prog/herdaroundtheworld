// Photos: redrawn on a canvas as a JPEG no bigger than 1200px. Redrawing also drops the hidden
// location data (GPS) that phone cameras put inside photos.
const MAX = 1200;

function loadImage(file) {
  return new Promise((resolve, reject) => {
    const url = URL.createObjectURL(file);
    const img = new Image();
    img.onload = () => { resolve(img); setTimeout(() => URL.revokeObjectURL(url), 1000); };
    img.onerror = () => { URL.revokeObjectURL(url); reject(new Error('That photo couldn’t be used. Please try a different one.')); };
    img.src = url;
  });
}

/** A chosen file → { base64, mimeType, dataUrl }. */
export async function preparePhoto(file) {
  if (!file || !/^image\//.test(file.type || 'image/')) throw new Error('Please choose a photo.');
  let source;
  try {
    source = await createImageBitmap(file, { imageOrientation: 'from-image' });
  } catch (e) {
    source = await loadImage(file);
  }
  const w = source.width, h = source.height;
  const scale = Math.min(1, MAX / Math.max(w, h));
  const canvas = document.createElement('canvas');
  canvas.width = Math.max(1, Math.round(w * scale));
  canvas.height = Math.max(1, Math.round(h * scale));
  const ctx = canvas.getContext('2d');
  ctx.fillStyle = '#fff';
  ctx.fillRect(0, 0, canvas.width, canvas.height);
  ctx.drawImage(source, 0, 0, canvas.width, canvas.height);
  if (source.close) source.close();
  const dataUrl = canvas.toDataURL('image/jpeg', 0.85);
  return { base64: dataUrl.split(',')[1], mimeType: 'image/jpeg', dataUrl };
}
