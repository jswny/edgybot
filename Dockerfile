FROM elixir:1.13.1-alpine AS builder

ARG MIX_ENV="prod"
ARG GIT_VERSION="2.34.7-r0"

RUN apk update \
  && apk add --no-cache \
  git="${GIT_VERSION}"

WORKDIR /usr/src/edgybot

COPY . .

RUN mix local.hex --force \
  && mix local.rebar --force \
  && mix deps.get \
  && mix compile \
  && mix release --path rel

FROM alpine:3.12 AS runner

ARG LIBSTDCPP_VERSION="9.3.0-r2"
ARG LIBGCC_VERSION="9.3.0-r2"
ARG NCURSES_LIBS_VERSION="6.2_p20200523-r1"

RUN apk update \
  && apk add --no-cache \
  libstdc++="${LIBSTDCPP_VERSION}" \
  libgcc="${LIBGCC_VERSION}" \
  ncurses-libs="${NCURSES_LIBS_VERSION}"

WORKDIR /edgybot

COPY --from=builder /usr/src/edgybot/rel .

ENTRYPOINT [ "bin/edgybot" ]
CMD [ "start" ]
