# 🔐 Bitwarden SSH Key Fetcher

A simple shell script that allows you to retrieve an SSH private key stored in Bitwarden and save it to your `~/.ssh/` folder using its item name as the filename.

## ✅ Features

- Search Bitwarden items using a keyword
- Choose from matching results
- Automatically saves the private key with proper formatting
- Uses the original item name as the filename
- Ready for SSH access right away

---

## 🚀 Usage

### 1. Prerequisites

Install the following tools:

```bash
sudo apt install jq -y            # For parsing JSON
sudo snap install bw              # Bitwarden CLI via Snap

