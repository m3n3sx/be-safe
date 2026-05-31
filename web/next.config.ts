import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Cloud Run deployment: emit standalone server bundle to /app/.next/standalone/server.js
  output: "standalone",
};

export default nextConfig;
