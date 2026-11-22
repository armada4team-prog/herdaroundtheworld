// Sends the 6-digit sign-in code. One small function per way of sending, picked with the
// EMAIL_PROVIDER variable (default "wix"), so another free email service can be added later
// without touching the checker.
//
// "wix": Wix Email Transmissions API, sent from The Herd's own Wix site. The recipient is given
// by email address; Wix creates the contact if it doesn't exist yet.
//   POST /email-transmissions/v1/email-transmissions/send
//   https://dev.wix.com/docs/api-reference/business-management/marketing/emails/email-transmission-v1/send-email-transmission
// Emails sent this way count toward the site's Wix Email Marketing allowance. Without a verified
// sender address on a custom domain, Wix sends from no-reply@et.wixsitemail.com.
import { wixFetch, config } from './wix-rest.js';

const MINUTES = 15;

function texts(code) {
  const subject = 'Your Herd Around the World sign-in code: ' + code;
  const text = `Your sign-in code is ${code}\n\nType it where you asked for it. It works for ${MINUTES} minutes.\n` +
    'If you didn’t ask for a code, you can ignore this email.\n\nThe Herd · companions.theherdstudio.com';
  const html = `<div style="font-family: 'Fira Sans', Arial, sans-serif; color: #566E62; line-height: 1.5">
<p>Your sign-in code for Herd Around the World is</p>
<p style="font-size: 32px; letter-spacing: 6px; font-weight: bold; color: #2F4A3D">${code}</p>
<p>Type it where you asked for it. It works for ${MINUTES} minutes.</p>
<p style="color: #8A9A91">If you didn’t ask for a code, you can ignore this email.</p>
<p>The Herd · <a href="https://companions.theherdstudio.com" style="color: #5B7869">companions.theherdstudio.com</a></p>
</div>`;
  return { subject, text, html };
}

const providers = {
  async wix({ to, subject, text, html, env }) {
    const emailTransmission = {
      emailSubject: subject,
      emailHtmlContent: html,
      emailTextContent: text,
      senderName: env.EMAIL_SENDER_NAME || 'The Herd',
      toRecipients: [{ emailAddress: to }],
      type: 'TRANSACTIONAL',
    };
    if (env.EMAIL_FROM) emailTransmission.senderEmailAddress = env.EMAIL_FROM;
    if (env.EMAIL_REPLY_TO) emailTransmission.replyTo = { emailAddress: env.EMAIL_REPLY_TO };
    await wixFetch('/email-transmissions/v1/email-transmissions/send', {
      body: { emailTransmission, idempotencyKey: crypto.randomUUID() },
    });
  },
  // TODO (only if Wix sending doesn't suit): add another provider here, e.g. a free transactional
  // email service called with fetch() and its key stored as a Worker secret, then set
  // EMAIL_PROVIDER to its name.
};

async function sendEmail(to, { subject, text, html }) {
  const { env } = config();
  const name = String(env.EMAIL_PROVIDER || 'wix').toLowerCase();
  const send = providers[name];
  if (!send) throw new Error('Unknown EMAIL_PROVIDER: ' + name);
  await send({ to, subject, text, html, env });
}

export async function sendSignInCode(to, code) {
  await sendEmail(to, texts(code));
}

const escHtml = (s) => String(s).replace(/[&<>"']/g, (ch) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[ch]));

/**
 * The gentle reminder to someone who has held a Companion for a long time (see ../nudge.js):
 * pass them on, or tell The Herd they found a forever home.
 */
export async function sendNudge(to, { name, nickname, days, passOnUrl, adoptUrl }) {
  const hi = nickname ? `Hi ${nickname},` : 'Hi there,';
  const subject = `${name} misses the road!`;
  const text = `${hi}\n\n${name} has been with you for ${days} days. Ready to send them on their next adventure? ` +
    `Leave them somewhere new or hand them to a friend, and log it so their story keeps going:\n${passOnUrl}\n\n` +
    `Or did ${name} find a forever home with you? That's a happy ending too. Let us know here:\n${adoptUrl}\n\n` +
    'The Herd · companions.theherdstudio.com\nYou’re getting this because you signed in to Herd Around the World with this email.';
  const button = (href, label, bg, fg) => `<a href="${escHtml(href)}" style="display:inline-block;background:${bg};color:${fg};text-decoration:none;font-weight:bold;padding:12px 22px;border-radius:999px;margin:4px 0">${label}</a>`;
  const html = `<div style="font-family: 'Fira Sans', Arial, sans-serif; color: #566E62; line-height: 1.5; max-width: 520px">
<p>${escHtml(hi)}</p>
<p><strong style="color:#2F4A3D">${escHtml(name)}</strong> has been with you for ${days} days. Ready to send them on their next adventure? Leave them somewhere new or hand them to a friend, and log it so their story keeps going.</p>
<p>${button(passOnUrl, 'Pass them on', '#5B7869', '#ffffff')}</p>
<p>Or did ${escHtml(name)} find a forever home with you? That’s a happy ending too.</p>
<p>${button(adoptUrl, 'They’re staying with me', '#DDEFEA', '#2F4A3D')}</p>
<p>The Herd · <a href="https://companions.theherdstudio.com" style="color: #5B7869">companions.theherdstudio.com</a></p>
<p style="color: #8A9A91; font-size: 13px">You’re getting this because you signed in to Herd Around the World with this email.</p>
</div>`;
  await sendEmail(to, { subject, text, html });
}


const WHAT = { broke: 'They broke', chipped: 'Chipped, still traveling', lost: 'They got lost', adopted: 'Found a forever home (adopted)', flagged: 'Reported by a traveler: please take a look' };

/** The daily email to The Herd (see ../digest.js): photos to approve and new reports. */
export async function sendDigest(to, { photos, reports, stopsUrl, reportsUrl }) {
  const parts = [];
  if (photos.length) parts.push(`${photos.length} new photo${photos.length === 1 ? '' : 's'} to approve`);
  if (reports.length) parts.push(`${reports.length} new report${reports.length === 1 ? '' : 's'}`);
  const subject = 'Herd Around the World: ' + parts.join(', ');
  const line = (bits) => bits.filter(Boolean).join(' · ');

  let text = subject + '\n\n';
  for (const p of photos) {
    text += `${line([p.title, p.where, p.by && 'by ' + p.by])}\n`;
    if (p.chapter) text += `“${p.chapter}”\n`;
    if (p.photo) text += `Photo: ${p.photo}\n`;
    if (p.wishPhoto) text += `Wish photo: ${p.wishPhoto}\n`;
    text += `Approve photo: ${p.approveUrl}\n\n`;
  }
  if (photos.length) text += `All photos in Wix: ${stopsUrl}\n\n`;
  for (const r of reports) {
    text += `${line([r.title, WHAT[r.what] || r.what, r.where, r.by && 'by ' + r.by])}\n`;
    if (r.note) text += `“${r.note}”\n`;
    if (r.sendPieces) text += `Wants to send the pieces home${r.email ? ': ' + r.email : ''}\n`;
    else if (r.email) text += `Email: ${r.email}\n`;
    text += '\n';
  }
  if (reports.length) text += `All reports in Wix: ${reportsUrl}\n`;

  const btn = (href, label, bg, fg) => `<a href="${escHtml(href)}" style="display:inline-block;background:${bg};color:${fg};text-decoration:none;font-weight:bold;padding:10px 18px;border-radius:999px;margin:4px 6px 4px 0;font-size:14px">${label}</a>`;
  const img = (src, alt) => src ? `<a href="${escHtml(src)}"><img src="${escHtml(src)}" alt="${escHtml(alt)}" width="260" style="display:block;width:260px;max-width:100%;border-radius:12px;margin:8px 0"></a>` : '';
  let html = `<div style="font-family: 'Fira Sans', Arial, sans-serif; color: #566E62; line-height: 1.5; max-width: 560px">
<h2 style="color:#3F5A4C;font-size:20px;margin:0 0 12px">${escHtml(subject)}</h2>`;
  if (photos.length) {
    html += '<h3 style="color:#3F5A4C;font-size:16px;margin:18px 0 6px">Photos to approve</h3>';
    for (const p of photos) {
      html += `<div style="border:2px solid #DDEFEA;border-radius:16px;padding:12px 14px;margin:10px 0">
<p style="margin:0;font-weight:bold;color:#2F4A3D">${escHtml(line([p.title, p.where]))}</p>
${p.by ? `<p style="margin:0;font-size:14px">by ${escHtml(p.by)}</p>` : ''}
${p.chapter ? `<p style="margin:6px 0;font-style:italic">“${escHtml(p.chapter)}”</p>` : ''}
${img(p.photo, 'Photo of ' + p.title)}${p.wishPhoto ? '<p style="margin:6px 0 0;font-size:14px">Wish photo:</p>' + img(p.wishPhoto, 'Wish photo of ' + p.title) : ''}
<p style="margin:6px 0 0">${btn(p.approveUrl, 'Approve photo', '#5B7869', '#ffffff')}${btn(stopsUrl, 'Open in Wix', '#DDEFEA', '#2F4A3D')}</p>
</div>`;
    }
    html += '<p style="font-size:13px;color:#8A9A91">Not okay? Leave it unapproved and it stays hidden. You can delete it in Wix.</p>';
  }
  if (reports.length) {
    html += '<h3 style="color:#3F5A4C;font-size:16px;margin:18px 0 6px">New reports</h3>';
    for (const r of reports) {
      html += `<div style="border:2px solid #F6D3D3;border-radius:16px;padding:12px 14px;margin:10px 0">
<p style="margin:0;font-weight:bold;color:#2F4A3D">${escHtml(r.title)} · ${escHtml(WHAT[r.what] || r.what)}</p>
<p style="margin:0;font-size:14px">${escHtml(line([r.where, r.by && 'by ' + r.by]))}</p>
${r.note ? `<p style="margin:6px 0;font-style:italic">“${escHtml(r.note)}”</p>` : ''}
${r.sendPieces ? `<p style="margin:6px 0;font-size:14px"><strong>Wants to send the pieces home</strong>${r.email ? ': ' + escHtml(r.email) : ''}</p>` : r.email ? `<p style="margin:6px 0;font-size:14px">Email: ${escHtml(r.email)}</p>` : ''}
</div>`;
    }
    html += `<p>${btn(reportsUrl, 'Open reports in Wix', '#DDEFEA', '#2F4A3D')}</p>`;
  }
  html += '<p style="font-size:13px;color:#8A9A91">Sent by your Herd Around the World checker. Change the address (ownerEmail) in Companion Settings in Wix.</p></div>';
  await sendEmail(to, { subject, text, html });
}
