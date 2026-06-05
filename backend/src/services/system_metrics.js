// PowerAdmin — metryki zasobów: proces backendu + baza danych.
// Lekkie (bez zewnętrznych API). Cache TTL żeby /admin/system nie bił po DB co render.
const os = require('os');
const db = require('../config/db');

const startCpu = process.cpuUsage();
const startTime = Date.now();

function processMetrics() {
  const mem = process.memoryUsage();
  const cpu = process.cpuUsage(startCpu);
  const elapsedMs = Date.now() - startTime;
  // % CPU = (user+system µs) / (elapsed ms * 1000) — uśrednione od startu.
  const cpuPct = elapsedMs > 0 ? ((cpu.user + cpu.system) / 1000 / elapsedMs) * 100 : 0;
  return {
    node_version: process.version,
    platform: `${process.platform}/${process.arch}`,
    pid: process.pid,
    uptime_s: Math.round(process.uptime()),
    rss_mb: Math.round(mem.rss / 1048576),
    heap_used_mb: Math.round(mem.heapUsed / 1048576),
    heap_total_mb: Math.round(mem.heapTotal / 1048576),
    cpu_pct_avg: Math.round(cpuPct * 10) / 10,
    os_total_mem_mb: Math.round(os.totalmem() / 1048576),
    os_free_mem_mb: Math.round(os.freemem() / 1048576),
    os_loadavg: os.loadavg().map((n) => Math.round(n * 100) / 100),
    cpus: os.cpus().length,
  };
}

async function dbMetrics() {
  const out = {};
  try {
    const size = await db.query("SELECT pg_database_size(current_database()) AS bytes, pg_size_pretty(pg_database_size(current_database())) AS pretty");
    out.size_bytes = parseInt(size.rows[0].bytes, 10);
    out.size_pretty = size.rows[0].pretty;
    const conn = await db.query(`SELECT count(*)::int AS total,
        count(*) FILTER (WHERE state='active')::int AS active,
        count(*) FILTER (WHERE state='idle')::int AS idle
      FROM pg_stat_activity WHERE datname = current_database()`);
    out.connections = conn.rows[0];
    const max = await db.query("SELECT setting::int AS max_connections FROM pg_settings WHERE name='max_connections'");
    out.max_connections = max.rows[0].max_connections;
    // Liczniki domenowe (lekkie — indexowane / małe tabele)
    const counts = await db.query(`SELECT
        (SELECT count(*)::int FROM users) AS users,
        (SELECT count(*)::int FROM alerts WHERE status='active') AS alerts_active,
        (SELECT count(*)::int FROM family_groups) AS groups,
        (SELECT count(*)::int FROM notifications) AS notifications,
        (SELECT count(*)::int FROM alert_reports WHERE status='pending') AS reports_pending`);
    out.counts = counts.rows[0];
    // Top 5 największych tabel
    const tables = await db.query(`SELECT relname AS table, pg_size_pretty(pg_total_relation_size(relid)) AS size,
        pg_total_relation_size(relid) AS bytes
      FROM pg_catalog.pg_statio_user_tables ORDER BY pg_total_relation_size(relid) DESC LIMIT 5`);
    out.top_tables = tables.rows;
  } catch (e) {
    out.error = e.message;
  }
  return out;
}

// Cache wspólny dla całego /admin/system (proces+DB+GCP łączone w route).
const _cache = new Map();
async function cached(key, ttlMs, fn) {
  const hit = _cache.get(key);
  if (hit && Date.now() - hit.t < ttlMs) return hit.v;
  const v = await fn();
  _cache.set(key, { t: Date.now(), v });
  return v;
}

module.exports = { processMetrics, dbMetrics, cached };
