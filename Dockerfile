FROM elixir:1.13.1-alpine AS builder

ENV MIX_ENV="prod"

WORKDIR /usr/src/edgybot

COPY . .

RUN mix local.hex --force \
  && mix local.rebar --force \
  && mix deps.get \
  && mix compile \
  && mix release

FROM alpine:3.12 AS runner

WORKDIR /edgybot

COPY --from=builder /usr/src/edgybot/_build/prod/rel/edgybot .

ENTRYPOINT [ "bin/edgybot" ]
CMD [ "start" ]
