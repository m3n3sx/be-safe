// PowerAdmin — metryki GCP via Cloud Monitoring API (Cloud Run + GCS).
// Fail-soft: każda metryka w try/catch; brak uprawnień/błąd → null, nie wywala /admin/system.
// Wymaga roles/monitoring.viewer dla tożsamości (compute SA na Cloud Run).
const PROJECT = process.env.GCP_PROJECT_ID || 'project-1674d55f-90e0-4e1a-884';
const RUN_SERVICE = process.env.K_SERVICE || 'besafe-backend'; // K_SERVICE ustawiane przez Cloud Run
const GCS_BUCKET = process.env.GCS_BUCKET || 'besafe-uploads';

let _client = null;
function client() {
  if (_client) return _client;
  try {
    const { MetricServiceClient } = require('@google-cloud/monitoring');
    _client = new MetricServiceClient();
    return _client;
  } catch (e) {
    console.error('[gcp_metrics] init failed:', e.message);
    return null;
  }
}

// Pobiera ostatni punkt serii czasowej dla danego filtra + agregacji.
async function latestPoint(c, filter, aligner, reducer, lookbackMin = 10) {
  const now = Date.now();
  const [series] = await c.listTimeSeries({
    name: c.projectPath(PROJECT),
    filter,
    interval: {
      startTime: { seconds: Math.floor((now - lookbackMin * 60000) / 1000) },
      endTime: { seconds: Math.floor(now / 1000) },
    },
    aggregation: {
      alignmentPeriod: { seconds: 60 },
      perSeriesAligner: aligner,
      crossSeriesReducer: reducer || 'REDUCE_NONE',
    },
    view: 'FULL',
  });
  if (!series || !series.length) return null;
  // weź najświeższy punkt z pierwszej (zredukowanej) serii
  const pts = series[0].points || [];
  if (!pts.length) return null;
  const v = pts[0].value;
  return v.doubleValue ?? (v.int64Value != null ? Number(v.int64Value) : null);
}

async function cloudRun(c) {
  const base = `resource.type="cloud_run_revision" resource.labels.service_name="${RUN_SERVICE}"`;
  const out = {};
  const safe = async (k, fn) => { try { out[k] = await fn(); } catch (e) { out[k] = null; out[`${k}_err`] = e.message?.slice(0, 80); } };
  await Promise.all([
    safe('cpu_util_pct', async () => {
      const v = await latestPoint(c, `${base} metric.type="run.googleapis.com/container/cpu/utilizations"`, 'ALIGN_PERCENTILE_99', 'REDUCE_MEAN');
      return v != null ? Math.round(v * 1000) / 10 : null;
    }),
    safe('mem_util_pct', async () => {
      const v = await latestPoint(c, `${base} metric.type="run.googleapis.com/container/memory/utilizations"`, 'ALIGN_PERCENTILE_99', 'REDUCE_MEAN');
      return v != null ? Math.round(v * 1000) / 10 : null;
    }),
    safe('instances', async () => {
      const v = await latestPoint(c, `${base} metric.type="run.googleapis.com/container/instance_count"`, 'ALIGN_MEAN', 'REDUCE_SUM');
      return v != null ? Math.round(v) : null;
    }),
    safe('req_per_min', async () => {
      const v = await latestPoint(c, `${base} metric.type="run.googleapis.com/request_count"`, 'ALIGN_RATE', 'REDUCE_SUM');
      return v != null ? Math.round(v * 60 * 10) / 10 : null;
    }),
    safe('p95_latency_ms', async () => {
      const v = await latestPoint(c, `${base} metric.type="run.googleapis.com/request_latencies"`, 'ALIGN_PERCENTILE_95', 'REDUCE_MEAN');
      return v != null ? Math.round(v) : null;
    }),
  ]);
  return out;
}

async function gcs(c) {
  const base = `resource.type="gcs_bucket" resource.labels.bucket_name="${GCS_BUCKET}"`;
  const out = {};
  const safe = async (k, fn) => { try { out[k] = await fn(); } catch (e) { out[k] = null; } };
  await Promise.all([
    // total_bytes raportowane raz dziennie → lookback 36h
    safe('total_bytes', async () => {
      const v = await latestPoint(c, `${base} metric.type="storage.googleapis.com/storage/total_bytes"`, 'ALIGN_MEAN', 'REDUCE_MEAN', 36 * 60);
      return v != null ? Math.round(v) : null;
    }),
    safe('object_count', async () => {
      const v = await latestPoint(c, `${base} metric.type="storage.googleapis.com/storage/object_count"`, 'ALIGN_MEAN', 'REDUCE_MEAN', 36 * 60);
      return v != null ? Math.round(v) : null;
    }),
  ]);
  return out;
}

async function gcpMetrics() {
  const c = client();
  if (!c) return { available: false, error: 'monitoring_client_unavailable' };
  try {
    const [run, storage] = await Promise.all([cloudRun(c), gcs(c)]);
    return { available: true, cloud_run: run, gcs: storage, service: RUN_SERVICE, bucket: GCS_BUCKET };
  } catch (e) {
    return { available: false, error: e.message };
  }
}

module.exports = { gcpMetrics };
