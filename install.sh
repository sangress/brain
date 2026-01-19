#!/usr/bin/env bash
set -e

REPO_RAW_BASE="https://raw.githubusercontent.com/sangress/brain/main"

BIN_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/brain"
BASHRC="$HOME/.bashrc"

echo "🔧 Installing brain (AI Bash helper)..."

# --- sanity checks ---
if ! command -v bash >/dev/null; then
  echo "❌ Bash not found"
  exit 1
fi

if ! command -v python3 >/dev/null; then
  echo "❌ python3 is required"
  exit 1
fi

# --- create dirs ---
mkdir -p "$BIN_DIR"
mkdir -p "$CONFIG_DIR"

# --- download files ---
echo "⬇️  Downloading brain-gen..."
curl -fsSL "$REPO_RAW_BASE/brain-gen" -o "$BIN_DIR/brain-gen"
chmod +x "$BIN_DIR/brain-gen"

echo "⬇️  Downloading brain.sh..."
curl -fsSL "$REPO_RAW_BASE/brain.sh" -o "$CONFIG_DIR/brain.sh"

# --- ensure ~/.local/bin in PATH ---
if ! grep -q 'export PATH=.*\.local/bin' "$BASHRC"; then
  echo "➕ Adding ~/.local/bin to PATH in ~/.bashrc"
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$BASHRC"
fi

# --- source brain.sh ---
if ! grep -q 'source .*brain.sh' "$BASHRC"; then
  echo "➕ Sourcing brain.sh in ~/.bashrc"
  cat >> "$BASHRC" <<'EOF'

# brain — AI-powered Bash command helper
if [[ -f "$HOME/.config/brain/brain.sh" ]]; then
  source "$HOME/.config/brain/brain.sh"
fi
EOF
fi

# --- bind key ---
if ! grep -q 'bind -x .*brain' "$BASHRC"; then
  echo "➕ Binding Ctrl+G to brain"
  echo 'bind -x '"'"'"\C-g": brain'"'"'' >> "$BASHRC"
fi

echo
echo "✅ brain installed successfully!"
echo
echo "Next steps:"
echo "1) Restart your terminal OR run: source ~/.bashrc"
echo "2) Set your API key:"
echo '   export OPENAI_API_KEY="sk-..."'
echo
echo "Usage:"
echo "• Type a sentence, press Ctrl+G → command appears"
echo "• Or: brain \"show git config username\""
echo
echo "Enjoy 🧠✨"
