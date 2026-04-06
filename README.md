# Auto Paper Review

Automated daily review system that pulls LaTeX papers from Overleaf and uses Claude to identify critical errors (logical errors, insufficient rigor, formula mistakes). Results are sent via Telegram.

Runs as a [Claude Code scheduled task](https://code.claude.com/docs/en/web-scheduled-tasks) — fully cloud-hosted, no local machine required.

## Requirements

- A [Claude Code](https://code.claude.com) account (Pro, Max, Team, or Enterprise)
- Overleaf project(s) with git access enabled
- A Telegram bot (create one via [@BotFather](https://t.me/BotFather))

## How It Works

1. Scheduled task triggers on Claude Code cloud
2. Agent follows `program.md` to:
   - Pull LaTeX projects from Overleaf via git
   - Review each paper for critical errors
   - Send review summaries via Telegram bot

## Setup

1. Push this repo to GitHub
2. Go to [claude.ai/code/scheduled](https://claude.ai/code/scheduled) and create a new scheduled task
3. Connect this GitHub repository
4. Configure environment variables in the cloud environment settings:
   - `OVERLEAF_TOKEN` — Overleaf git auth token
   - `PROJECT_IDS` — Comma-separated Overleaf project IDs
   - `TELEGRAM_BOT_TOKEN` — Token from @BotFather
   - `TELEGRAM_CHAT_ID` — Chat ID for notifications
   - `TELEGRAM_TOPIC_ID` *(optional)* — Forum topic/thread ID for supergroups with Topics enabled
5. Set the schedule (e.g., daily at 9 AM)
6. Set the task prompt to follow `program.md`

See `.env.example` for a reference of all required variables.
