# Auto Paper Review — Agent Instructions

Follow these steps in order.

## Step 1: Pull Papers from Overleaf

Read the environment variables `OVERLEAF_TOKEN` and `PROJECT_IDS`. `PROJECT_IDS` is a comma-separated list of Overleaf project IDs.

For each project ID:
- Clone or pull the project via git: `git clone https://git:${OVERLEAF_TOKEN}@git.overleaf.com/${project_id}` into a `papers/${project_id}` directory
- If the directory already exists, run `git pull` instead
- After cloning/pulling, strip LaTeX comments from every `.tex` file in `papers/${project_id}/` using a terminal command. Remove full-line comments (lines whose first non-whitespace character is `%`) and inline comments (from an unescaped `%` to end of line), preserving escaped `\%`. Example:

  ```bash
  find "papers/${project_id}" -name '*.tex' -type f -exec perl -i -pe 's/(?<!\\)%.*$//' {} +
  ```

  This is an in-memory scrub for review only — do **not** commit or push these changes back to Overleaf.

## Step 2: Review Each Paper

Launch one **subagent per project in parallel** using the Agent tool. Each subagent receives only its own paper directory, keeping context focused.

For each project, spawn a subagent with a prompt like:

> You are an expert academic paper reviewer. Read all `.tex` files in `papers/${project_id}/` and identify the **3 most critical errors**.
>
> **Before reviewing:** Check whether `papers/${project_id}/IGNORE.md` exists. If it does, read it and treat it as author-supplied guidance on sections, topics, or error classes to skip. Do not report anything that falls within its scope.
>
> Focus exclusively on:
> 1. **Serious logical errors** — Arguments that are internally contradictory or conclusions that do not follow from the premises.
> 2. **Seriously insufficient logical rigor** — Key claims made without adequate justification, missing steps in proofs, or hand-waving over important details.
> 3. **Serious formula/mathematical errors** — Incorrect equations, dimensional inconsistencies, wrong derivations, or misapplied theorems.
>
> **Constraints:**
> - The paper is still being written. **Ignore any problems caused by missing or incomplete content** (e.g., empty sections, TODO markers, placeholder text, missing references).
> - Focus only on what IS written, not what is absent.
> - Honor `IGNORE.md` if present — anything it excludes is out of scope.
> - Be specific: cite the exact section, equation number, or passage where each error occurs.
> - Respond in the same language that the paper is written in.
>
> **Output format:**
>
> ### Error 1: [Brief title]
> **Location**: [Section/equation/line reference]
> **Severity**: [Critical/Major]
> **Description**: [Clear explanation of the error and why it matters]
> **Suggestion**: [How to fix it]
>
> (Repeat for Error 2 and Error 3)
>
> If the paper has fewer than 3 serious errors, report only what you find and state that the paper is otherwise sound.

Collect the results from all subagents before proceeding to Step 3.

## Step 3: Send Results via Telegram

Read the environment variables `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID`, and optionally `TELEGRAM_TOPIC_ID`.

Compile all reviews into a single message using this format:

```
*Auto Paper Review — YYYY\-MM\-DD*

*— Project: ${project_id} —*

*Error 1: \[Brief title\]*
*Location*: Section/equation/line reference
*Severity*: Critical/Major
*Description*: Explanation of the error
*Suggestion*: How to fix it

*Error 2: \[Brief title\]*
\.\.\.

*— Project: ${next_project_id} —*
\.\.\.
```

Send using `parse_mode=MarkdownV2`. Escape the review text per Telegram MarkdownV2 rules before sending.

```bash
curl -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
  -d chat_id="${TELEGRAM_CHAT_ID}" \
  -d parse_mode=MarkdownV2 \
  -d text="${ESCAPED_TEXT}" \
  ${TELEGRAM_TOPIC_ID:+-d message_thread_id="${TELEGRAM_TOPIC_ID}"}
```

If `TELEGRAM_TOPIC_ID` is set, messages are sent to that specific forum topic. Otherwise, messages are sent to the group/chat normally (works for regular groups and the General topic in forum supergroups).

Telegram has a 4096 character limit per message. If the report exceeds this, split it into multiple messages (one per project).
