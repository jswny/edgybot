# Edgybot ![CI](https://github.com/jswny/edgybot/workflows/CI/badge.svg)

Edgy Discord bot.

## Running

Before running, make sure you have an environment variable `DISCORD_TOKEN` set to a valid bot token. In addition, you can set the following environment variables to configure the database connection to Postgres:

- `DATABASE_USERNAME` (default: `postgres`)
- `DATABASE_PASSWORD` (default: `postgres`)
- `DATABASE_HOSTNAME` (default: `localhost`)

You may also set `SILENT_MODE` if you want to prevent the bot from responding publicly and instead send responses that only the caller of the command can see.

### Local

```shell
mix deps.get
mix run --no-halt
```

### Docker

You can run with Docker Compose, which will build the image locally, and use the environment variables from your current environment. You can alternatively setup a .env file which contains the appropriate environment variables and values which Compose will pick up automatically.

```shell
docker-compose up
```

## Error Handling

- Most errors, especially in commands, will be reported back as a response to the command execution
- Internal errors and stacktraces will only be exposed in messages if `MIX_ENV` is not `:prod`
- All errors with full stack traces will be logged to the console
