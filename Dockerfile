FROM elixir:1.11.2-alpine AS builder

ENV MIX_ENV="prod"

WORKDIR /usr/src/edgybot

COPY . .

RUN mix local.hex --force \
  && mix local.rebar --force \
  && mix deps.get \
  && mix compile \
  && mix release

FROM alpine:3.12 AS runner

ENV NCURSES_DEV_VERSION="6.2_p20200523-r0"

RUN apk update \
  && apk add --no-cache ncurses-dev="${NCURSES_DEV_VERSION}"

WORKDIR /edgybot

COPY --from=builder /usr/src/edgybot/_build/prod/rel/edgybot .

ENTRYPOINT [ "bin/edgybot" ]
CMD [ "start" ]
