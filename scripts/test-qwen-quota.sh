#!/bin/bash
# Test Qwen quota - Envía 100 requests para probar rotación
# Uso: ./test-qwen-quota.sh [cantidad]

API_KEY="sk-3c5f52adb00816cfaa8341157ad26cf0ffc1a379d0412b7ac06f4cc8d74a525a"
PROXY_URL="http://127.0.0.1:8317"
MODEL="coder-model"
COUNT=${1:-100}

echo "=== QWEN QUOTA TEST ==="
echo "Sending $COUNT requests to $MODEL"
echo "Press Ctrl+C to stop"
echo ""

success=0
errors=0

for i in $(seq 1 $COUNT); do
  response=$(curl -s -w "\n%{http_code}" -X POST "$PROXY_URL/v1/chat/completions" \
    -H "Authorization: Bearer $API_KEY" \
    -H "Content-Type: application/json" \
    -d "{
      \"model\": \"$MODEL\",
      \"messages\": [{\"role\": \"user\", \"content\": \"Test $i\"}],
      \"max_tokens\": 5
    }")

  http_code=$(echo "$response" | tail -1)
  body=$(echo "$response" | head -n -1)

  if [ "$http_code" = "200" ]; then
    success=$((success + 1))
    model=$(echo "$body" | grep -o '"model":"[^"]*"' | cut -d'"' -f4)
    echo "[$i] OK - model: $model"
  else
    errors=$((errors + 1))
    error_msg=$(echo "$body" | grep -o '"message":"[^"]*"' | cut -d'"' -f4)
    echo "[$i] ERROR $http_code - $error_msg"
  fi

  # Pequeña pausa para no saturar (10 requests por segundo)
  sleep 0.1
done

echo ""
echo "=== RESULTS ==="
echo "Success: $success"
echo "Errors: $errors"
echo "Total: $COUNT"
