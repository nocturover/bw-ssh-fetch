#!/bin/bash

# 🔐 Automatically fetch an SSH private key from Bitwarden and save it to ~/.ssh
# Usage: ./bw-ssh-fetch.sh "search_keyword"

SEARCH_TERM="$1"

# ✅ 0. Check if Bitwarden CLI is installed
if ! command -v bw &>/dev/null; then
  echo "❌ Bitwarden CLI (bw) is not installed."
  echo "🔍 Download: https://bitwarden.com/download/?app=cli&platform=linux"
  echo "📅 Or GitHub Releases: https://github.com/bitwarden/cli/releases"
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

# ✅ 3. Check BW_SESSION
if [ -z "$BW_SESSION" ]; then
  echo "🔐 Bitwarden session not found."
  echo "🔑 Login first: bw login"
  echo "📆 Then unlock: export BW_SESSION=$(bw unlock --raw)"
  exit 1
fi

# ✅ 4. Search for items
echo "🔍 Searching items with keyword '$SEARCH_TERM'..."
ITEMS_JSON=$(bw list items --search "$SEARCH_TERM" 2>/dev/null)

# Handle not logged in
if [[ -z "$ITEMS_JSON" || "$ITEMS_JSON" == *"You are not logged in"* ]]; then
  echo "❌ You are not logged in to Bitwarden or your session has expired."
  echo "🔑 Run: bw login"
  echo "📆 Then: export BW_SESSION=$(bw unlock --raw)"
  exit 1
fi

# Validate JSON
if ! echo "$ITEMS_JSON" | jq empty &>/dev/null; then
  echo "❌ Invalid JSON received from Bitwarden."
  exit 1
fi

ITEM_COUNT=$(echo "$ITEMS_JSON" | jq length)
if [ "$ITEM_COUNT" -eq 0 ]; then
  echo "❌ No matching items found."
  exit 1
fi

# ✅ 5. Print results
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

# ✅ 6. Fetch and save SSH key
echo "📅 Fetching SSH private key for '$SELECTED_NAME'..."
mkdir -p ~/.ssh
bw get item "$SELECTED_ID" | jq -r '.sshKey.privateKey' | sed 's/\\n/\n/g' > "$HOME/.ssh/$OUTFILE"
chmod 400 "$HOME/.ssh/$OUTFILE"

# ✅ 7. Done
echo ""
echo "✅ SSH private key saved to: ~/.ssh/$OUTFILE"
echo "📖 Connect example:"
echo "  ssh -i ~/.ssh/$OUTFILE <username>@<host>"
echo "  # Replace <username> with your login user and <host> with the server IP or domain name"

