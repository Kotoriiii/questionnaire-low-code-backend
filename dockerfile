###################

# BUILD FOR LOCAL DEVELOPMENT

###################

FROM node:18 AS development
RUN curl -f https://get.pnpm.io/v6.16.js | node - add --global pnpm

WORKDIR /usr/src/app

COPY --chown=node:node pnpm-lock.yaml ./

RUN pnpm fetch --prod

COPY --chown=node:node . .
RUN pnpm install

USER node

###################

# BUILD FOR PRODUCTION

###################

FROM node:18 AS build
RUN curl -f https://get.pnpm.io/v6.16.js | node - add --global pnpm

WORKDIR /usr/src/app

COPY --chown=node:node pnpm-lock.yaml ./

COPY --chown=node:node --from=development /usr/src/app/node_modules ./node_modules

COPY --chown=node:node . .

RUN pnpm build

RUN pnpm install --prod

USER node

###################

# PRODUCTION

###################

FROM node:18-alpine AS production

ENV NODE_ENV=production
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8 TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nestjs

COPY --chown=nestjs:nodejs --from=build /usr/src/app/node_modules ./node_modules
COPY --chown=nestjs:nodejs --from=build /usr/src/app/dist ./dist

EXPOSE 3005

CMD [ "node", "dist/src/main.js" ]
