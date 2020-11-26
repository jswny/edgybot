FROM elixir:1.11.2-alpine as build

WORKDIR /usr/src/edgybot
COPY . .
RUN mix local.hex --force
RUN mix deps.get
RUN mix compile
