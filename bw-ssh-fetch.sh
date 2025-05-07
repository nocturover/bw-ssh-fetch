#!/bin/bash

# 🔐 Automatically fetch an SSH private key from Bitwarden and save it to ~/.ssh
# Usage: ./bw-ssh-fetch.sh "search_keyword"

SEARCH_TERM="$1"

# ✅ 0. Check if Bitwarden CLI is installed
if ! command -v bw &>/dev/null; then
  echo "❌ Bitwarden CLI (bw) is not installed."
  echo "🔍 Download: https://bitwarden.com/download/?app=cli&platform=linux"
  echo "🚧 Install via Snap (if available): sudo snap install bw"
  exit 1
fi

# ✅ 1. Check search keyword
if [ -z "$SEARCH_TERM" ]; then
  echo "❌ Please provide a search keyword. Example: ./bw-ssh-fetch.sh aws"
  exit 1
fi

# ✅ 2. Check if jq is installed
if ! command -v jq &>/dev/null; then
  echo "❌ 'jq' is required."
  echo "🔧 Install it: sudo apt install jq -y"
  exit 1
fi

# ✅ 3. Check Bitwarden status and unlock session if needed
AUTH_STATUS=$(bw status 2>/dev/null | jq -r '.status')

if [ "$AUTH_STATUS" == "unauthenticated" ]; then
  echo "🔑 Bitwarden 로그인이 필요합니다. 로그인 절차를 시작합니다..."
  bw login || {
    echo "❌ 로그인 실패"
    exit 1
  }
  echo "🔓 로그인 후 vault unlock 중... 마스터 비밀번호를 입력하세요."
  export BW_SESSION=$(bw unlock --raw)
elif [ "$AUTH_STATUS" == "locked" ]; then
  echo "🔓 Bitwarden vault가 잠겨 있습니다. 마스터 비밀번호를 입력하세요."
  export BW_SESSION=$(bw unlock --raw)
elif [ "$AUTH_STATUS" == "unlocked" ]; then
  export BW_SESSION=$(bw unlock --raw)
else
  echo "❌ Bitwarden 상태 확인 실패. CLI 버전 문제일 수 있습니다."
  exit 1
fi

# ✅ 4. Sync vault
echo "🔄 Bitwarden vault를 동기화합니다..."
bw sync --session "$BW_SESSION" >/dev/null || {
  echo "❌ sync 실패"
  exit 1
}

# ✅ 5. Search for items
echo "🔍 Searching items with keyword '$SEARCH_TERM'..."
ITEMS_JSON=$(bw list items --search "$SEARCH_TERM" --session "$BW_SESSION" 2>/dev/null)

# Validate JSON
if ! echo "$ITEMS_JSON" | jq empty &>/dev/null; then
  echo "❌ Invalid JSON received from Bitwarden or session expired."
  exit 1
fi

ITEM_COUNT=$(echo "$ITEMS_JSON" | jq length)
if [ "$ITEM_COUNT" -eq 0 ]; then
  echo "❌ No matching items found."
  exit 1
fi

# ✅ 6. Print results
echo ""
echo "🔎 Search results:"
echo "$ITEMS_JSON" | jq -r 'to_entries[] | "\(.key)) \(.value.name) [ID: \(.value.id)]"' | nl -v 0

echo ""
read -p "➡ Enter the index of the item to use: " ITEM_INDEX

SELECTED_ID=$(echo "$ITEMS_JSON" | jq -r ".[$ITEM_INDEX].id")
SELECTED_NAME=$(echo "$ITEMS_JSON" | jq -r ".[$ITEM_INDEX].name")

if [ -z "$SELECTED_ID" ] || [ "$SELECTED_ID" == "null" ]; then
  echo "❌ Invalid selection."
  exit 1
fi

OUTFILE="$SELECTED_NAME"

# ✅ 7. Fetch and save SSH key
echo "📅 Fetching SSH private key for '$SELECTED_NAME'..."
mkdir -p ~/.ssh
bw get item "$SELECTED_ID" --session "$BW_SESSION" | jq -r '.sshKey.privateKey' | sed 's/\\n/\n/g' > "$HOME/.ssh/$OUTFILE"
chmod 400 "$HOME/.ssh/$OUTFILE"

# ✅ 8. Done
echo ""
echo "✅ SSH private key saved to: ~/.ssh/$OUTFILE"
echo "📖 Connect example:"
echo "  ssh -i ~/.ssh/$OUTFILE <username>@<host>"
echo "  # Replace <username> with your login user and <host> with the server IP or domain name"

