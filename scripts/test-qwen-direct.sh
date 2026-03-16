#!/bin/bash
# Test Qwen quota directo - Envía peticiones hasta agotar una cuenta
# Uso: ./test-qwen-direct.sh [cantidad]
# URL: https://portal.qwen.ai/v1/chat/completions

# Token de la cuenta 3 (qwen-1772920958714) - estaba activa en el último test
TOKEN="AfSBrUyX2y9XXD6Gc_D9gNU7sn2H3YG1F4NZjk-K9OG1wIIUeuuAU5Vzpc0fcPvSqBeaKXo3Ke72w6-5CAeV2g"
MODEL="coder-model"
COUNT=${1:-1000}

echo "=== QWEN DIRECT QUOTA TEST ==="
echo "Sending $COUNT requests to $MODEL"
echo "Endpoint: https://portal.qwen.ai/v1/chat/completions"
echo "Press Ctrl+C to stop"
echo ""

success=0
errors=0
quota_exhausted=0

for i in $(seq 1 $COUNT); do
  response=$(curl -s -w "\n%{http_code}" -X POST "https://portal.qwen.ai/v1/chat/completions" \
    -H "Authorization: Bearer $TOKEN" \
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
    id=$(echo "$body" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
    echo "[$i] OK - ${id:0:30}..."
  else
    errors=$((errors + 1))
    error_msg=$(echo "$body" | grep -o '"message":"[^"]*"' | cut -d'"' -f4)
    echo "[$i] ERROR $http_code - $error_msg"

    # Check if quota exhausted
    if echo "$error_msg" | grep -q "exceeded your current quota"; then
      quota_exhausted=$((quota_exhausted + 1))
      echo ">>> QUOTA EXHAUSTED! ($quota_exhausted/3 attempts)"
      if [ $quota_exhausted -ge 3 ]; then
        echo ""
        echo "Account fully exhausted. Stopping."
        break
      fi
    fi
  fi

  # Pequeña pausa para no saturar (10 requests por segundo)
  sleep 0.1
done

echo ""
echo "=== RESULTS ==="
echo "Success: $success"
echo "Errors: $errors"
echo "Quota exhausted errors: $quota_exhausted"
echo "Total: $((success + errors))"
