FROM node:20-alpine

WORKDIR /app

# Copy package file
COPY package.json .

# Install dependencies
RUN npm install -g pnpm && \
    pnpm install --no-frozen-lockfile

# Copy source
COPY src ./src

ENV NODE_ENV=production
EXPOSE 3001

# Start script
CMD ["pnpm", "run", "dev"]
