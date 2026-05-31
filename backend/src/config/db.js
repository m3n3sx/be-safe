const { Pool } = require('pg');
require('dotenv').config();

// Two ways to configure DB:
//   1) DATABASE_URL=postgresql://user:pass@host:port/db (AWS / local dev)
//   2) DB_HOST + DB_USER + DB_PASS + DB_NAME (Cloud Run + Cloud SQL Unix socket)
//      DB_HOST may be a Unix socket path like /cloudsql/PROJECT:REGION:INSTANCE.
let pool;
if (process.env.DATABASE_URL) {
  pool = new Pool({ connectionString: process.env.DATABASE_URL });
} else {
  pool = new Pool({
    host: process.env.DB_HOST || '/cloudsql/' + (process.env.CLOUD_SQL_CONNECTION_NAME || ''),
    user: process.env.DB_USER || 'alertmap',
    password: process.env.DB_PASS,
    database: process.env.DB_NAME || 'alertmap',
    // Unix sockets don't need port; TCP fallback uses 5432.
    port: process.env.DB_PORT ? parseInt(process.env.DB_PORT, 10) : undefined,
    max: parseInt(process.env.DB_POOL_MAX || '10', 10),
  });
}

module.exports = {
  query: (text, params) => pool.query(text, params),
  pool,
};
