#!/bin/bash
TOKEN=$(cat ~/.ghtoken)
REPO=tganand/btcstate
F=~/btc-momentum-bot/data/bot_state.json
[ -f "$F" ] || exit 0
CONTENT=$(base64 -w0 "$F")
SHA=$(curl -s -H "Authorization: Bearer $TOKEN" https://api.github.com/repos/$REPO/contents/bot_state.json | grep -o '"sha": *"[a-f0-9]*"' | head -n1 | grep -o '[a-f0-9]\{40\}')
BODY="{\"message\":\"backup\",\"content\":\"$CONTENT\""
[ -n "$SHA" ] && BODY="$BODY,\"sha\":\"$SHA\""
BODY="$BODY}"
echo "$BODY" | curl -s -X PUT -H "Authorization: Bearer $TOKEN" -d @- https://api.github.com/repos/$REPO/contents/bot_state.json -o /dev/null -w "backup: %{http_code}\n"
