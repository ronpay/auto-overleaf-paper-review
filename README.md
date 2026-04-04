# Auto Paper Review

Automated daily review system that pulls LaTeX papers from Overleaf and uses Claude to identify critical errors (logical errors, insufficient rigor, formula mistakes). Results are sent via Telegram.

## How It Works

1. Pulls LaTeX projects from Overleaf via git
2. Invokes Claude as a subagent to review each paper
3. Sends review summaries via Telegram bot

## Setup

1. Copy `.env.example` to `.env` and fill in your credentials:
   - `OVERLEAF_TOKEN` — Overleaf git auth token
   - `PROJECT_IDS` — Comma-separated Overleaf project IDs
   - `TELEGRAM_BOT_TOKEN` — Token from @BotFather
   - `TELEGRAM_CHAT_ID` — Chat ID for notifications
2. Ensure `claude` CLI is installed and authenticated
3. Run: `bash run.sh`

## Scheduled Execution

Add to crontab (`crontab -e`):

```
0 9 * * * cd /path/to/auto-paper-review && bash run.sh >> /tmp/auto-paper-review.log 2>&1
```
