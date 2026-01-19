#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${OPENAI_API_KEY:-}" ]]; then
  echo "Error: OPENAI_API_KEY not set" >&2
  exit 1
fi

PROMPT="${*:-}"
if [[ -z "$PROMPT" ]]; then
  echo 'Usage: brain "show git config username"' >&2
  exit 1
fi

python3 - "$PROMPT" <<'PY'
import json, os, sys, urllib.request, urllib.error

prompt = sys.argv[1]
api_key = os.environ["OPENAI_API_KEY"]

instructions = (
  "You translate natural language into a SINGLE valid shell command.\n"
  "Rules:\n"
  "- Output ONLY the command\n"
  "- No explanations\n"
  "- No markdown\n"
  "- No comments\n"
  "- Do not wrap in quotes\n"
  "- If unsure, choose the safest common command"
)

payload = {
  "model": "gpt-4.1-mini",
  "instructions": instructions,
  "input": prompt,
  "temperature": 0,
}

data = json.dumps(payload).encode("utf-8")

req = urllib.request.Request(
  "https://api.openai.com/v1/responses",
  data=data,
  headers={
    "Authorization": f"Bearer {api_key}",
    "Content-Type": "application/json",
  },
  method="POST",
)

try:
  with urllib.request.urlopen(req, timeout=60) as resp:
    body = resp.read().decode("utf-8", errors="replace")
except urllib.error.HTTPError as e:
  err_body = e.read().decode("utf-8", errors="replace")
  try:
    j = json.loads(err_body)
    msg = j.get("error", {}).get("message", err_body)
  except Exception:
    msg = err_body
  print(f"OpenAI API error (HTTP {e.code}): {msg}", file=sys.stderr)
  sys.exit(2)
except Exception as e:
  print(f"Request failed: {e}", file=sys.stderr)
  sys.exit(3)

j = json.loads(body)

# Primary: Responses API convenience field
cmd = j.get("output_text")

# Fallback: walk the output structure
if not cmd:
  out = []
  for item in j.get("output", []) or []:
    if item.get("type") == "message":
      for c in item.get("content", []) or []:
        if c.get("type") == "output_text" and "text" in c:
          out.append(c["text"])
  cmd = "\n".join(out).strip()

if not cmd:
  print("Error: Could not extract command from response JSON.", file=sys.stderr)
  print(json.dumps(j, indent=2), file=sys.stderr)
  sys.exit(4)

print(cmd.strip())
PY
