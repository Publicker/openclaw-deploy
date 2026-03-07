# openclaw-deploy

Self-hosted OpenClaw deployment for Coolify. Connects to any OpenAI-compatible LLM endpoint and exposes a Telegram bot.

## Required Environment Variables

| Variable | Description |
|---|---|
| `API_KEY` | LLM provider API key |
| `LLM_BASE_URL` | OpenAI-compatible endpoint (e.g. `http://your-gateway:8000/v1`) |
| `LLM_MODEL` | Model name (e.g. `claude-sonnet-4`) |
| `TELEGRAM_BOT_TOKEN` | Telegram bot token from @BotFather |
| `TELEGRAM_USER_ID` | Your Telegram numeric user ID |

## Deploy on Coolify

1. Create a docker-compose application from this repo
2. Set the env vars above in the Coolify dashboard
3. Deploy

## Local Development

```bash
cp .env.example .env
# Edit .env with your values
docker compose up -d
```
