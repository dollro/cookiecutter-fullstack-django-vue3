# syntax = docker/dockerfile:1.3
FROM node:18-bookworm-slim
ARG TARGETPLATFORM
ARG BUILDKIT_INLINE_CACHE
RUN apt-get update \
    && apt-get install -y git python3 build-essential
#
COPY ./frontend_vue/package.json /app/frontend_vue/package.json
RUN npm install -g pnpm
WORKDIR /app/frontend_vue
#RUN pnpm install
RUN --mount=type=cache,id=pnpm-cache-$TARGETPLATFORM,target=$HOME/.local/share/pnpm/store/v3 pnpm install
RUN npx browserslist@latest --update-db
#&& npm cache clean --force
WORKDIR /app

COPY ./compose/local/node-vue/start-vue /start-vue
RUN sed -i 's/\r$//g' /start-vue
RUN chmod +x /start-vue

RUN chown -R node:node /app/frontend_vue
ENV PATH ./node_modules/.bin/:./frontend_vue/node_modules/.bin/:$PATH
