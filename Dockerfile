# Base node image
FROM node:20-alpine AS base
RUN npm install -g pnpm@8.15.1

# Install dependencies only when needed
FROM base AS deps
WORKDIR /app

# Files needed for installing dependencies
COPY package.json pnpm-lock.yaml ./

# Install dependencies
RUN pnpm install --no-frozen-lockfile --ignore-scripts

# Rebuild the source code only when needed
FROM base AS builder
WORKDIR /app

# Copy files needed for build
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Create production build
ENV NEXT_TELEMETRY_DISABLED 1
ENV NEXT_SHARP_PATH=/usr/local/lib/node_modules/sharp

# Install dependencies
RUN apk add --no-cache python3 make g++ openssl && \
    npm install -g sharp && \
    mkdir -p certificates && \
    # Generate a stronger SSL certificate
    openssl req -x509 \
    -newkey rsa:4096 \
    -keyout certificates/key.pem \
    -out certificates/cert.pem \
    -days 365 \
    -nodes \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost" \
    -addext "subjectAltName=DNS:localhost,IP:127.0.0.1" && \
    apk del python3 make g++

# Create production build with turbopack
ENV NEXT_TURBO=1
RUN pnpm run build

# Production image, copy all the files and run next
FROM base AS runner
WORKDIR /app

ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1
ENV NEXT_SHARP_PATH=/usr/local/lib/node_modules/sharp
ENV NEXT_TURBO=1

# Create app directory
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Copy built files and certificates
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
COPY --from=builder /usr/local/lib/node_modules/sharp /usr/local/lib/node_modules/sharp
COPY --from=builder /app/certificates ./certificates

# Switch to non-root user
USER nextjs

# Expose HTTPS port
EXPOSE 3000

ENV PORT 3000
ENV HOSTNAME "0.0.0.0"
ENV HTTPS_KEY_PATH=/app/certificates/key.pem
ENV HTTPS_CERT_PATH=/app/certificates/cert.pem

# Start with HTTPS enabled
CMD ["pnpm", "seed"] 