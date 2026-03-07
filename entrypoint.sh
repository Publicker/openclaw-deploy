#!/bin/bash
set -e

CONFIG_DIR="/home/node/.openclaw"
CONFIG_FILE="$CONFIG_DIR/openclaw.json"
WORKSPACE_DIR="$CONFIG_DIR/workspace"

# Fix permissions on volume (runs as root, then drops to node)
mkdir -p "$WORKSPACE_DIR"
chown -R node:node "$CONFIG_DIR"

# Setup SSH for node user
mkdir -p /home/node/.ssh
if [ -n "$SSH_AUTHORIZED_KEYS" ]; then
  echo "$SSH_AUTHORIZED_KEYS" > /home/node/.ssh/authorized_keys
  chmod 600 /home/node/.ssh/authorized_keys
fi
chown -R node:node /home/node/.ssh
chmod 700 /home/node/.ssh

# Generate host keys if missing and start sshd
ssh-keygen -A 2>/dev/null
/usr/sbin/sshd -e
echo "SSH server started on port 22"

# Start Tailscale daemon and connect (non-blocking)
tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock &
sleep 2
if [ -n "$TAILSCALE_AUTHKEY" ]; then
  tailscale up --authkey="$TAILSCALE_AUTHKEY" --hostname="${TAILSCALE_HOSTNAME:-manny-openclaw}" --ssh --accept-routes &
else
  tailscale up --hostname="${TAILSCALE_HOSTNAME:-manny-openclaw}" --ssh --accept-routes &
fi
echo "Tailscale daemon started (connecting in background)"

# Only write config if it doesn't exist yet (OpenClaw modifies it at runtime)
if [ ! -f "$CONFIG_FILE" ]; then
  cat > "$CONFIG_FILE" <<EOFCONFIG
{
  "gateway": {
    "bind": "lan",
    "port": 18789
  },
  "models": {
    "providers": {
      "custom": {
        "apiKey": "${API_KEY}",
        "baseUrl": "${LLM_BASE_URL}",
        "api": "openai-completions",
        "models": [
          {"id": "claude-sonnet-4", "name": "Claude Sonnet 4", "api": "openai-completions", "reasoning": false, "input": ["text"], "contextWindow": 200000, "maxTokens": 8192},
          {"id": "claude-sonnet-4.5", "name": "Claude Sonnet 4.5", "api": "openai-completions", "reasoning": false, "input": ["text"], "contextWindow": 200000, "maxTokens": 8192},
          {"id": "claude-sonnet-4.6", "name": "Claude Sonnet 4.6", "api": "openai-completions", "reasoning": false, "input": ["text"], "contextWindow": 200000, "maxTokens": 8192},
          {"id": "claude-opus-4.5", "name": "Claude Opus 4.5", "api": "openai-completions", "reasoning": false, "input": ["text"], "contextWindow": 200000, "maxTokens": 32000},
          {"id": "claude-opus-4.6", "name": "Claude Opus 4.6", "api": "openai-completions", "reasoning": false, "input": ["text"], "contextWindow": 200000, "maxTokens": 32000},
          {"id": "claude-haiku-4.5", "name": "Claude Haiku 4.5", "api": "openai-completions", "reasoning": false, "input": ["text"], "contextWindow": 200000, "maxTokens": 8192},
          {"id": "claude-3.7-sonnet", "name": "Claude 3.7 Sonnet", "api": "openai-completions", "reasoning": false, "input": ["text"], "contextWindow": 200000, "maxTokens": 8192}
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": "custom/${LLM_MODEL}",
      "workspace": "${WORKSPACE_DIR}",
      "timeoutSeconds": 600
    }
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "${TELEGRAM_BOT_TOKEN}",
      "dmPolicy": "allowlist",
      "allowFrom": ["${TELEGRAM_USER_ID}"]
    }
  }
}
EOFCONFIG
  chown node:node "$CONFIG_FILE"
  echo "Config written to $CONFIG_FILE"
else
  echo "Config already exists, skipping write"
fi

exec gosu node node dist/index.js gateway --allow-unconfigured "$@"
