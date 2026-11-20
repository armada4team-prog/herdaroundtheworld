// Stands in for Velo's `mediaManager.upload` over the Media Manager REST upload flow:
//   1. POST /site-media/v1/files/generate-upload-url  → { uploadUrl }
//      https://dev.wix.com/docs/api-reference/assets/media/media-manager/files/generate-file-upload-url
//   2. PUT <uploadUrl>?filename=… with the bytes and Content-Type → { file }
//      https://dev.wix.com/docs/api-reference/assets/media/media-manager/files/upload-api
// `filePath` puts the photo in the "Herd Around the World" folder (Wix creates it if missing).
// The CMS photo fields are IMAGE fields, which take a wix:image://v1/… address or an https URL
// (https://dev.wix.com/docs/api-reference/business-solutions/cms/skills/cms-data-items-crud).
import { wixFetch } from '../wix-rest.js';

/** The value an IMAGE field takes for an uploaded Media Manager file. */
export function imageFieldValue(file, fallbackName) {
  const img = file && file.media && file.media.image && file.media.image.image;
  const id = (img && img.id) || (file && file.id);
  const name = (img && img.filename) || (file && file.displayName) || fallbackName;
  if (id && img && img.width && img.height) {
    return `wix:image://v1/${id}/${encodeURIComponent(name)}#originWidth=${img.width}&originHeight=${img.height}`;
  }
  if (file && file.url) return file.url;
  if (id) return `wix:image://v1/${id}/${encodeURIComponent(name)}`;
  throw new Error('Wix did not say where the uploaded photo is.');
}

async function upload(folder, bytes, fileName, options = {}) {
  const mimeType = (options.mediaOptions && options.mediaOptions.mimeType) || 'image/jpeg';
  const isPrivate = !!(options.metadataOptions && options.metadataOptions.isPrivate);
  const { uploadUrl } = await wixFetch('/site-media/v1/files/generate-upload-url', {
    body: { mimeType, fileName, sizeInBytes: String(bytes.length), filePath: folder, private: isPrivate },
  });
  if (!uploadUrl) throw new Error('Wix did not give an upload address.');
  const sep = uploadUrl.includes('?') ? '&' : '?';
  // The upload address is already signed: it doesn't take the API key.
  const res = await fetch(uploadUrl + sep + 'filename=' + encodeURIComponent(fileName), {
    method: 'PUT',
    headers: { 'Content-Type': mimeType },
    body: bytes,
  });
  const text = await res.text();
  if (!res.ok) throw new Error(`Photo upload answered ${res.status}: ${text.slice(0, 300)}`);
  const { file } = JSON.parse(text);
  return { fileUrl: imageFieldValue(file, fileName), file };
}

export const mediaManager = { upload };
