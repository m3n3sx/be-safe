const router = require('express').Router();
const db = require('../config/db');
const auth = require('../middleware/auth');

router.use(auth);

// Pobierz wszystkie badges użytkownika + dostępne do zdobycia
router.get('/me/badges', async (req, res) => {
  const uid = req.user.id;
  // Auto-check & grant badges
  await _checkAndGrantBadges(uid);

  const { rows: earned } = await db.query(`
    SELECT b.id, b.name, b.description, b.icon, b.color, b.category, ub.awarded_at
    FROM user_badges ub JOIN badges b ON b.id = ub.badge_id
    WHERE ub.user_id = $1 ORDER BY ub.awarded_at DESC`, [uid]);
  const { rows: all } = await db.query(`SELECT * FROM badges ORDER BY threshold ASC`);

  const earnedIds = new Set(earned.map(e => e.id));
  const available = all.filter(b => !earnedIds.has(b.id));

  res.json({ earned, available });
});

async function _checkAndGrantBadges(uid) {
  try {
    const { rows: stats } = await db.query(`
      SELECT
        (SELECT COUNT(*)::int FROM alerts WHERE author_id = $1 AND status != 'removed') AS alerts_count,
        (SELECT COUNT(*)::int FROM alert_votes WHERE user_id = $1) AS votes_count,
        (SELECT COUNT(*)::int FROM family_groups WHERE owner_id = $1) AS groups_owned,
        (SELECT COUNT(*)::int FROM users WHERE referred_by = $1) AS referrals,
        (SELECT reputation_score FROM users WHERE id = $1) AS reputation,
        (SELECT COALESCE(SUM(confirms), 0)::int FROM alerts WHERE author_id = $1) AS total_confirms
    `, [uid]);
    const s = stats[0];
    const toGrant = [];
    if (s.alerts_count >= 1) toGrant.push('first_alert');
    if (s.alerts_count >= 10) toGrant.push('alerts_10');
    if (s.alerts_count >= 50) toGrant.push('alerts_50');
    if (s.alerts_count >= 100) toGrant.push('alerts_100');
    if (s.votes_count >= 10) toGrant.push('votes_10');
    if (s.votes_count >= 50) toGrant.push('votes_50');
    if (s.groups_owned >= 1) toGrant.push('family_creator');
    if (s.referrals >= 5) toGrant.push('referrer');
    if (s.reputation >= 200) toGrant.push('high_rep');
    if (s.total_confirms >= 25) toGrant.push('helpful');

    for (const bid of toGrant) {
      await db.query(`INSERT INTO user_badges (user_id, badge_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`, [uid, bid]);
    }
  } catch (e) {
    console.error('[Badges] error:', e.message);
  }
}

// List posts (public feed)
router.get('/posts', async (req, res) => {
  const { rows } = await db.query(
    `SELECT id, title, content, image_url, category, created_at FROM posts
     WHERE published = TRUE ORDER BY created_at DESC LIMIT 50`
  );
  res.json({ posts: rows });
});

router.get('/posts/:id', async (req, res) => {
  const { rows } = await db.query(`SELECT * FROM posts WHERE id = $1 AND published = TRUE`, [req.params.id]);
  if (!rows[0]) return res.status(404).json({ error: 'Not found' });
  res.json(rows[0]);
});

module.exports = router;
