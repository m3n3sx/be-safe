// Email service.
// Default provider: Mailgun (MAILGUN_API_KEY + MAILGUN_DOMAIN).
// Fallback: nodemailer SMTP (legacy, local Postfix or SES SMTP).
// Dev mode: EMAIL_DISABLED=1 logs instead of sending.

const fs = require('fs');
const path = require('path');

const FROM = process.env.EMAIL_FROM || 'info@besafe.org.pl';
const FROM_NAME = process.env.EMAIL_FROM_NAME || 'be:Safe';
const APP_URL = process.env.APP_URL || 'https://besafe.org.pl';
const DISABLED = process.env.EMAIL_DISABLED === '1' || process.env.EMAIL_DISABLED === 'true';

const MG_KEY = process.env.MAILGUN_API_KEY || '';
const MG_DOMAIN = process.env.MAILGUN_DOMAIN || '';
const MG_REGION = process.env.MAILGUN_REGION || 'us'; // 'us' or 'eu'
const MG_HOST = MG_REGION === 'eu' ? 'https://api.eu.mailgun.net' : 'https://api.mailgun.net';

let mgClient = null;
function getMailgun() {
  if (mgClient) return mgClient;
  const formData = require('form-data');
  const Mailgun = require('mailgun.js');
  const mg = new Mailgun(formData);
  mgClient = mg.client({ username: 'api', key: MG_KEY, url: MG_HOST });
  return mgClient;
}

// SMTP fallback (legacy paths)
let transporter = null;
function getTransporter() {
  if (transporter) return transporter;
  const nodemailer = require('nodemailer');
  const host = process.env.SMTP_HOST || 'localhost';
  const port = parseInt(process.env.SMTP_PORT || '25', 10);
  const useAuth = !!process.env.SMTP_USER;
  transporter = nodemailer.createTransport({
    host,
    port,
    secure: port === 465,
    requireTLS: useAuth,
    ignoreTLS: !useAuth,
    auth: useAuth ? { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS } : undefined,
  });
  return transporter;
}

function renderTemplate(name, vars = {}) {
  const file = path.join(__dirname, '..', 'templates', `${name}.html`);
  if (!fs.existsSync(file)) throw new Error(`Email template not found: ${name}`);
  let html = fs.readFileSync(file, 'utf8');
  for (const [k, v] of Object.entries(vars)) {
    html = html.replaceAll(`{{${k}}}`, escapeHtml(String(v ?? '')));
    html = html.replaceAll(`{{${k}_RAW}}`, String(v ?? ''));
  }
  const text = html
    .replace(/<style[\s\S]*?<\/style>/gi, '')
    .replace(/<[^>]+>/g, '')
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/\n\s*\n/g, '\n\n')
    .trim();
  return { html, text };
}

function escapeHtml(s) {
  return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
}

async function send({ to, subject, template, vars = {}, replyTo }) {
  if (DISABLED) {
    console.log(`[email:dev] to=${to} subject=${subject} template=${template}`);
    return { ok: true, devMode: true };
  }
  try {
    const { html, text } = renderTemplate(template, { ...vars, APP_URL });
    const fromHeader = `"${FROM_NAME}" <${FROM}>`;

    if (MG_KEY && MG_DOMAIN) {
      // Mailgun path
      const mg = getMailgun();
      const r = await mg.messages.create(MG_DOMAIN, {
        from: fromHeader,
        to: [to],
        subject,
        html,
        text,
        'h:Reply-To': replyTo || FROM,
      });
      console.log(`[email/mailgun] sent to=${to} subject="${subject}" id=${r.id || ''}`);
      return { ok: true, messageId: r.id };
    }

    // SMTP fallback
    const info = await getTransporter().sendMail({
      from: fromHeader,
      to,
      subject,
      html,
      text,
      replyTo: replyTo || FROM,
    });
    console.log(`[email/smtp] sent to=${to} subject="${subject}" messageId=${info.messageId}`);
    return { ok: true, messageId: info.messageId };
  } catch (e) {
    console.error(`[email] FAILED to=${to} subject="${subject}": ${e.message}`);
    return { ok: false, error: e.message };
  }
}

async function sendVerificationEmail({ to, username, verifyUrl }) {
  return send({
    to,
    subject: 'Potwierdź swój email w be:Safe',
    template: 'verification',
    vars: { username: username || 'Użytkowniku', verify_url: verifyUrl, VERIFY_URL_RAW: verifyUrl },
  });
}

async function sendPasswordResetEmail({ to, username, resetUrl }) {
  return send({
    to,
    subject: 'Resetowanie hasła w be:Safe',
    template: 'reset-password',
    vars: { username: username || 'Użytkowniku', reset_url: resetUrl, RESET_URL_RAW: resetUrl },
  });
}

async function sendWelcomeEmail({ to, username }) {
  return send({
    to,
    subject: 'Witamy w be:Safe!',
    template: 'welcome',
    vars: { username: username || 'Użytkowniku' },
  });
}

module.exports = { send, sendVerificationEmail, sendPasswordResetEmail, sendWelcomeEmail };
