#!/bin/bash
echo "Polymarket check (want 200):"
curl -s -o /dev/null -w "%{http_code}\n" "https://gamma-api.polymarket.com/events?limit=1"

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
export NVM_DIR="$HOME/.nvm"; . "$NVM_DIR/nvm.sh"
nvm install 20
npm install -g pm2

mkdir -p ~/btc-momentum-bot && cd ~/btc-momentum-bot
curl -L -o ~/bot.tar.gz "https://raw.githubusercontent.com/tganand/btcbot/main/bot20.tar.gz?t=$(date +%s)"
tar -xzf ~/bot.tar.gz
npm install
npm run build
mkdir -p data
curl -L -o ~/backup.sh "https://raw.githubusercontent.com/tganand/btcbot/main/backup.sh" && chmod +x ~/backup.sh

read -s -p "Paste your GitHub token here: " T; echo
echo -n "$T" | tr -d ' \r\n' > ~/.ghtoken; chmod 600 ~/.ghtoken
curl -s -H "Authorization: Bearer $(cat ~/.ghtoken)" -H "Accept: application/vnd.github.raw" \
  "https://api.github.com/repos/tganand/btcstate/contents/bot_state.json" -o data/bot_state.json
if grep -q '"ledger"' data/bot_state.json; then
  echo "DATA RESTORED"
else
  rm -f data/bot_state.json
  echo "NO BACKUP FOUND - starting with a fresh account"
fi

if [ ! -f ~/.dashpass ]; then
  head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \n' > ~/.dashpass
  chmod 600 ~/.dashpass
fi

curl -L -o ~/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
chmod +x ~/cloudflared

cd ~/btc-momentum-bot
DASH_USER=anand DASH_PASSWORD="$(cat ~/.dashpass)" PORT=3001 pm2 start npm --name btcbot -- start
pm2 start ~/cloudflared --name tunnel -- tunnel --no-autoupdate --url http://localhost:3001
pm2 start bash --name backup -- -c 'while true; do ~/backup.sh; sleep 600; done'
pm2 save

sleep 15
echo ""
echo "=== YOUR DASHBOARD ADDRESS ==="
pm2 logs tunnel --lines 60 --nostream | grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' | tail -n 1
echo "Username: anand"
echo "Password: run  cat ~/.dashpass"
