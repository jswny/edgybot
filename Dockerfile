FROM elixir:1.17.3-alpine AS builder

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

FROM elixir:1.15.7-alpine AS runner

WORKDIR /edgybot

COPY --from=builder /usr/src/edgybot/rel .

ENTRYPOINT [ "bin/edgybot" ]
CMD [ "start" ]
