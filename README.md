# Edgybot ![CI](https://github.com/jswny/edgybot/workflows/CI/badge.svg)
Edgy Discord bot.

## Running
Before running, make sure you have an environment variable `DISCORD_TOKEN` set to a valid bot token.

### Local
```shell
mix deps.get
mix run
```

### Docker
Build the image with `docker build -t jswny/edgybot .`, or pull it from GitHub Container Regsitry with `docker pull ghcr.io/jswny/edgybot`, and then run the image:
```shell
docker run --env DISCORD_TOKEN jswny/edgybot 
```
