# Edgybot ![CI](https://github.com/jswny/edgybot/workflows/CI/badge.svg)

Edgy Discord bot.

## Running

Before running, make sure you have the following environment variables set:

- `DISCORD_TOKEN`
- `OPENAI_API_KEY` (for AI functionality)
- `DATABASE_USERNAME` (default: `postgres`)
- `DATABASE_PASSWORD` (default: `postgres`)
- `DATABASE_HOSTNAME` (default: `localhost`)

### Local

```shell
mix deps.get
mix run
```

### Docker

You can run with Docker Compose, which will build the image locally (if you don't already have it cached), and use the environment variables from your current environment. You can alternatively setup a `.env` file which contains the appropriate environment variables and values which Compose will pick up automatically.

```shell
docker-compose build # If you want to force a build
docker-compose up
```

## Configuration

- `APPLICATION_COMMAND_PREFIX`: a prefix to prepend to all commands when registering with Discord

### Logflare

You can enable the [Logflare](https://logflare.app/) integration, which will ship logs out to Logflare in addition to continuing to log to the console normally. To enable the Logflare, set up a source and then set the following environment variables:

- `LF_ENABLED`: Enable or disable Logflare logging (default: `false`)
- `LF_API_KEY`: Logflare ingest API key
- `LF_SOURCE_ID`

### OpenAI

Various configuration is available to tweak how the bot interact with the OpenAI API. For key-value pair lists, these are defined as comma-separated lists of `<key>=<value>` pairs.

- `OPENAI_TIMEOUT`: HTTP request timeout to the OpenAI API (default: `840,000 ms`)
- `OPENAI_CHAT_MODELS`: a list of key-value pairs of chat models to make available to users (default: `GPT-3.5=gpt-3.5-turbo`). For each entry, `<key>` indicates the name to show users, while `<value>` indicates the value to be passed to the OpenAI API.
- `OPENAI_IMAGE_MODELS`: a list of key-value pairs of chat models to make available to users (default: `DALL-E-3=dall-e-3`). For each entry, `<key>` indicates the name to show users, while `<value>` indicates the value to be passed to the OpenAI API.
- `OPENAI_IMAGE_SIZES`: a list of image sizes to make available to users (default: `1024x1024,512x512,256x256`)
