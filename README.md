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
mix run --no-halt
```

### Docker
You can run with Docker Compose, which will build the image locally.
```shell
docker-compose up
```
