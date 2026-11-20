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
  async wix({ to, code, env }) {
    const { subject, text, html } = texts(code);
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

export async function sendSignInCode(to, code) {
  const { env } = config();
  const name = String(env.EMAIL_PROVIDER || 'wix').toLowerCase();
  const send = providers[name];
  if (!send) throw new Error('Unknown EMAIL_PROVIDER: ' + name);
  await send({ to, code, env });
}
