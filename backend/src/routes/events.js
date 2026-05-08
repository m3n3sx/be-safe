const router = require('express').Router();
const db = require('../config/db');
const auth = require('../middleware/auth');

// Table created on first use
let _tableReady = false;
async function ensureTable() {
  if (_tableReady) return;
  await db.query(`
    CREATE TABLE IF NOT EXISTS analytics_events (
      id BIGSERIAL PRIMARY KEY,
      user_id UUID REFERENCES users(id) ON DELETE SET NULL,
      event VARCHAR(100) NOT NULL,
      session VARCHAR(50),
      params JSONB,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );
    CREATE INDEX IF NOT EXISTS idx_analytics_event ON analytics_events(event, created_at DESC);
    CREATE INDEX IF NOT EXISTS idx_analytics_user ON analytics_events(user_id, created_at DESC);
  `);
  _tableReady = true;
}

router.use(auth);

// Batch event ingestion
router.post('/', async (req, res) => {
  try {
    await ensureTable();
    const events = req.body.events;
    if (!Array.isArray(events) || events.length === 0) return res.json({ ok: true });
    if (events.length > 100) return res.status(400).json({ error: 'Too many events' });

    const values = [];
    const params = [];
    let i = 1;
    for (const e of events) {
      const { event, session, ts, ...rest } = e;
      if (!event || typeof event !== 'string') continue;
      values.push(`($${i++}, $${i++}, $${i++}, $${i++}, $${i++})`);
      params.push(req.user.id, event.substring(0, 100), session || null, rest, ts ? new Date(ts) : new Date());
    }
    if (values.length === 0) return res.json({ ok: true });

    await db.query(
      `INSERT INTO analytics_events (user_id, event, session, params, created_at) VALUES ${values.join(',')}`,
      params
    );
    res.json({ ok: true, stored: values.length });
  } catch (e) {
    // Don't fail — analytics nie powinno blokować apki
    console.error('[Analytics] error:', e.message);
    res.json({ ok: false });
  }
});

// Admin stats — tylko dla zalogowanego, prosta agregacja
router.get('/stats', async (req, res) => {
  try {
    await ensureTable();
    const { rows: totals } = await db.query(
      `SELECT event, COUNT(*)::int AS count
       FROM analytics_events
       WHERE created_at > NOW() - interval '7 days'
       GROUP BY event ORDER BY count DESC LIMIT 20`
    );
    const { rows: dau } = await db.query(
      `SELECT DATE(created_at) AS day, COUNT(DISTINCT user_id)::int AS users
       FROM analytics_events
       WHERE created_at > NOW() - interval '30 days'
       GROUP BY day ORDER BY day`
    );
    res.json({ top_events: totals, daily_active_users: dau });
  } catch (e) {
    res.json({ top_events: [], daily_active_users: [] });
  }
});

module.exports = router;
