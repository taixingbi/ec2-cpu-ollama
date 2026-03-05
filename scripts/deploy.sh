#!/bin/bash
set -e

echo "=== Install dependencies ==="
sudo apt-get update -y
sudo apt-get install -y curl

echo "=== Install Ollama (ARM64 auto-detect) ==="
if ! command -v ollama >/dev/null 2>&1; then
  curl -fsSL https://ollama.com/install.sh | sh
fi

echo "=== Configure public API ==="
sudo mkdir -p /etc/systemd/system/ollama.service.d
printf '%s\n' '[Service]' 'Environment="OLLAMA_HOST=0.0.0.0:11434"' | sudo tee /etc/systemd/system/ollama.service.d/override.conf > /dev/null

sudo systemctl daemon-reload
sudo systemctl enable ollama
sudo systemctl restart ollama

echo "=== Waiting for Ollama API ==="
sleep 5
for i in $(seq 1 45); do
  curl -sf http://127.0.0.1:11434/api/version >/dev/null && break
  if [ $i -eq 45 ]; then
    echo "Ollama failed to start after 90s. Service status:"
    sudo systemctl status ollama || true
    echo "Recent logs:"
    sudo journalctl -u ollama --no-pager -n 50 || true
    exit 1
  fi
  sleep 2
done

echo "=== Pull embedding model ==="
ollama pull qllama/bge-small-en-v1.5

echo "=== (Optional tiny inference model for testing) ==="
ollama pull tinyllama || true

echo "=== Done ==="
curl http://127.0.0.1:11434
