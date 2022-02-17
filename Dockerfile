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

ENV LIBSTDCPP_VERSION="9.3.0-r2"
ENV LIBGCC_VERSION="9.3.0-r2"
ENV NCURSES_LIBS_VERSION="6.2_p20200523-r1"

RUN apk update \
  && apk add --no-cache \
  libstdc++="${LIBSTDCPP_VERSION}" \
  libgcc="${LIBGCC_VERSION}" \
  ncurses-libs="${NCURSES_LIBS_VERSION}"

WORKDIR /edgybot

COPY --from=builder /usr/src/edgybot/_build/prod/rel/edgybot .

ENTRYPOINT [ "bin/edgybot" ]
CMD [ "start" ]
