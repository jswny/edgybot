# Edgybot ![CI](https://github.com/jswny/edgybot/workflows/CI/badge.svg)

Edgy Discord bot.

## Running

Before running, make sure you have an environment variable `DISCORD_TOKEN` set to a valid bot token. In addition, you can set the following environment variables to configure the database connection to Postgres:

- `DATABASE_USERNAME` (default: `postgres`)
- `DATABASE_PASSWORD` (default: `postgres`)
- `DATABASE_HOSTNAME` (default: `localhost`)

### Local

```shell
mix deps.get
mix run
```

### Docker

You can run with Docker Compose, which will build the image locally, and use the environment variables from your current environment. You can alternatively setup a `.env` file which contains the appropriate environment variables and values which Compose will pick up automatically.

```shell
docker-compose up
```

## Logflare

You can enable the [Logflare](https://logflare.app/) integration, which will ship logs out to Logflare in addition to continuing to log to the console normally. To enable the Logflare, set up a source and then set the following environment variables:

- `LF_ENABLED` (default: `false`)
- `LF_API_KEY` (your Logflare ingest API key)
- `LF_SOURCE_ID`
