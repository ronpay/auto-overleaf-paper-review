#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# --- Load environment ---
if [ ! -f .env ]; then
  echo "ERROR: .env file not found. Copy .env.example to .env and fill in values."
  exit 1
fi
set -a
source .env
set +a

# --- Validate required vars ---
for var in OVERLEAF_TOKEN PROJECT_IDS TELEGRAM_BOT_TOKEN TELEGRAM_CHAT_ID; do
  if [ -z "${!var:-}" ]; then
    echo "ERROR: $var is not set in .env"
    exit 1
  fi
done

# --- Prepare directories ---
mkdir -p papers reviews

# --- Parse project IDs (comma/space/newline separated) ---
PROJECT_IDS_CLEAN=$(echo "$PROJECT_IDS" | tr '\n' ' ')
IFS=$', ' read -ra PROJECTS <<< "$PROJECT_IDS_CLEAN"

# --- Clone/pull each project ---
for project_id in "${PROJECTS[@]}"; do
  project_id=$(echo "$project_id" | xargs)
  [ -z "$project_id" ] && continue

  echo "=== Pulling project: $project_id ==="

  target_dir="papers/$project_id"

  if [ -d "$target_dir/.git" ]; then
    echo "Pulling latest changes..."
    git -C "$target_dir" pull origin master 2>/dev/null || git -C "$target_dir" pull origin main 2>/dev/null || echo "WARNING: pull failed for $project_id"
  else
    echo "Cloning project..."
    rm -rf "$target_dir"
    git clone "https://git:${OVERLEAF_TOKEN}@git.overleaf.com/${project_id}" "$target_dir"
  fi
done

# --- Review each paper with Claude subagent ---
REVIEW_PROMPT=$(cat program.md)
FULL_REPORT=""

for project_id in "${PROJECTS[@]}"; do
  project_id=$(echo "$project_id" | xargs)
  [ -z "$project_id" ] && continue

  target_dir="papers/$project_id"
  review_file="reviews/${project_id}.md"

  if [ ! -d "$target_dir" ]; then
    echo "WARNING: $target_dir not found, skipping review"
    continue
  fi

  echo "=== Reviewing project: $project_id ==="

  review_output=$(claude -p \
    --system-prompt "$REVIEW_PROMPT" \
    --add-dir "$target_dir" \
    --allowed-tools "Read,Glob,Grep" \
    --model sonnet \
    "Review the LaTeX paper in the directory: ${SCRIPT_DIR}/${target_dir}" \
    2>/dev/null) || {
      echo "WARNING: Review failed for $project_id"
      review_output="Review failed for this project."
    }

  echo "$review_output" > "$review_file"
  echo "Review saved to $review_file"

  FULL_REPORT="${FULL_REPORT}

--- Project: ${project_id} ---
${review_output}
"
done

# --- Send via Telegram ---
if [ -n "$FULL_REPORT" ]; then
  HEADER="Auto Paper Review - $(date '+%Y-%m-%d')"
  MESSAGE="${HEADER}
${FULL_REPORT}"

  # Telegram has a 4096 character limit per message, truncate if needed
  if [ ${#MESSAGE} -gt 4000 ]; then
    MESSAGE="${MESSAGE:0:3997}..."
  fi

  response=$(curl -s -X POST \
    "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d chat_id="${TELEGRAM_CHAT_ID}" \
    -d text="${MESSAGE}" \
    2>&1)

  if echo "$response" | grep -q '"ok":true'; then
    echo "=== Review sent to Telegram ==="
  else
    echo "WARNING: Telegram send failed: $response"
  fi
else
  echo "=== No reviews to send ==="
fi
