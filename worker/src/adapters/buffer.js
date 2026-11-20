// The checker turns photos from base64 into bytes with Buffer.from(text, 'base64'). Workers have
// no Buffer (without Node compatibility), so the build injects this small stand-in.
// Like Node, it skips characters that aren't base64 and accepts the URL-safe alphabet.
export const Buffer = {
  from(input, encoding) {
    if (encoding !== 'base64') throw new Error('Only base64 is supported');
    let s = String(input).replace(/-/g, '+').replace(/_/g, '/').replace(/[^A-Za-z0-9+/]/g, '');
    if (s.length % 4 === 1) s = s.slice(0, -1);
    while (s.length % 4) s += '=';
    const bin = atob(s);
    const bytes = new Uint8Array(bin.length);
    for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
    return bytes;
  },
};
