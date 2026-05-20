/**
 * Admin routes — wymaga is_admin=TRUE.
 *
 * Wpięcie w index.js:
 *   const auth = require('./middleware/auth');
 *   const requireAdmin = require('./middleware/requireAdmin');
 *   app.use('/api/v1/admin', auth, requireAdmin, require('./routes/admin'));
 */
const express = require('express');
const fs = require('fs');
const path = require('path');
const router = express.Router();

const BACKUP_DIR = '/home/ubuntu/backups';
const LAST_BACKUP_FILE = path.join(BACKUP_DIR, 'last_backup.json');

/**
 * GET /api/v1/admin/backup-status
 * Zwraca info o ostatnim backupie DB (timestamp, rozmiar, count).
 */
router.get('/backup-status', (req, res) => {
  try {
    if (!fs.existsSync(LAST_BACKUP_FILE)) {
      return res.status(404).json({
        error: 'No backup yet',
        hint: 'Cron didn\'t run, or first backup not completed',
      });
    }
    const raw = fs.readFileSync(LAST_BACKUP_FILE, 'utf-8');
    const data = JSON.parse(raw);

    // Compute staleness (h since last backup)
    const ts = new Date(data.timestamp);
    const ageHours = (Date.now() - ts.getTime()) / (1000 * 60 * 60);
    data.age_hours = Math.round(ageHours * 10) / 10;
    data.is_stale = ageHours > 26; // expect daily cron, alert after ~26h

    res.json(data);
  } catch (e) {
    console.error('backup-status error', e);
    res.status(500).json({ error: 'Cannot read backup status' });
  }
});

/**
 * GET /api/v1/admin/ping
 * Lightweight check that admin role works.
 */
router.get('/ping', (req, res) => {
  res.json({ ok: true, user: req.user.id });
});

module.exports = router;
