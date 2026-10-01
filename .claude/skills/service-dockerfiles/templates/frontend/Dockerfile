# Stage 0: build Vite/React app
FROM node:20-alpine AS builder
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY index.html vite.config.ts tsconfig.json tsconfig.app.json tsconfig.node.json ./
COPY public ./public
COPY src ./src

# Vite embeds these at build time (must be VITE_*)
ARG VITE_API_URL=http://localhost:8100
ENV VITE_API_URL=$VITE_API_URL

RUN npm run build

# Stage 1: serve static build with nginx
FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
