// Stands in for Velo's `contacts.appendOrCreateContact` + `triggeredEmails.emailContact`, which
// the checker uses to email the sign-in code. Wix's Email Transmissions API takes the email
// address directly (and creates the contact itself), so "creating the contact" here just carries
// the address along, and "emailing the contact" sends the code (see ../email.js).
// In CompanionSettings, any value in `signInEmailId` (for example "on") switches sign-in on;
// it no longer names a Wix triggered email.
import { sendSignInCode } from '../email.js';

export const contacts = {
  async appendOrCreateContact(info) {
    const email = info && info.emails && info.emails[0] && info.emails[0].email;
    if (!email) throw new Error('No email to send the code to.');
    return { contactId: email, identityType: 'CONTACT' };
  },
};

export const triggeredEmails = {
  async emailContact(_emailId, contactId, options) {
    const code = options && options.variables && options.variables.code;
    await sendSignInCode(contactId, String(code));
  },
};
