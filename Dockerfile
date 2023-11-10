FROM elixir:1.15.7-alpine AS builder

ARG MIX_ENV="prod"

RUN apk update \
  && apk add --no-cache \
  git

WORKDIR /usr/src/edgybot

COPY . .

RUN mix local.hex --force \
  && mix local.rebar --force \
  && mix deps.get \
  && mix compile \
  && mix release --path rel

FROM alpine:3.12 AS runner

RUN apk update \
  && apk add --no-cache \
  libstdc++ \
  libgcc \
  ncurses-libs

WORKDIR /edgybot

COPY --from=builder /usr/src/edgybot/rel .

ENTRYPOINT [ "bin/edgybot" ]
CMD [ "start" ]
