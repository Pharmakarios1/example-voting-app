
FROM node:22-bookworm-slim

# Patch existing Debian packages and install required utilities
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends curl tini && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /usr/local/app

# Install only production dependencies
ENV NODE_ENV=production
ENV PORT=80

COPY package*.json ./

RUN npm ci --omit=dev && \
    npm cache clean --force && \
    mv /usr/local/app/node_modules /node_modules

COPY . .

EXPOSE 80

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["node", "server.js"]
