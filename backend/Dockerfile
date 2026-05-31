# be:Safe backend — Cloud Run (europe-central2)
# Node 22 Alpine, non-root, port 8080 (Cloud Run convention).
FROM node:22-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev --no-audit --no-fund

FROM node:22-alpine
WORKDIR /app
ENV NODE_ENV=production
ENV PORT=8080
# Cloud Run will inject secrets as env vars or mount files; FIREBASE_SERVICE_ACCOUNT
# path is set via Secret Manager volume in deploy command.
COPY --from=deps /app/node_modules ./node_modules
COPY package.json package-lock.json ./
COPY src ./src
# tini-style PID 1 via node directly. Run as non-root nobody.
USER node
EXPOSE 8080
CMD ["node", "src/index.js"]
