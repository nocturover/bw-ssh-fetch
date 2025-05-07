# 🔐 Bitwarden SSH Key Fetcher

Securely fetch SSH private keys stored in your Bitwarden vault and save them to `~/.ssh` using a simple interactive shell script.

Ideal for developers, sysadmins, and DevOps engineers who want to automate key provisioning on new servers without manually copying private keys.

---

## ✨ Features

* 🔍 Search SSH keys by keyword
* 🗌 Interactive selection if multiple items match
* 📀 Saves private key as `~/.ssh/<BitwardenItemName>`
* 🔐 Automatically sets correct permissions (`chmod 400`)
* 💻 Works on any system with `bash`, `jq`, and Bitwarden CLI

---

## 🚀 Usage

### 1. 📦 Install Requirements

```bash
sudo apt update
sudo apt install jq -y               # For JSON parsing
sudo snap install bw                 # Bitwarden CLI (or download manually)
```

Or manually download from [https://bitwarden.com/download/?app=cli\&platform=linux](https://bitwarden.com/download/?app=cli&platform=linux)

---

### 2. 🔐 Authenticate with Bitwarden

Login and unlock your vault:

```bash
bw login
export BW_SESSION=$(bw unlock --raw)
```

You must export `BW_SESSION` for the script to work.

---

### 3. 🧠 Run the Script

```bash
./bw-ssh-fetch.sh <search_keyword>
```

Example:

```bash
./bw-ssh-fetch.sh aws
```

The script will:

* Search your Bitwarden items with the keyword
* Let you choose the right item
* Fetch the private key
* Save it to `~/.ssh/aws` (or whatever the item name is)
* Set `chmod 400 ~/.ssh/aws` automatically

---

### 4. 🔗 Connect to Your Server

Use your key like this:

```bash
ssh -i ~/.ssh/aws ubuntu@ec2-xx-xx-xx-xx.compute.amazonaws.com
```

Generic example:

```bash
ssh -i ~/.ssh/my-key user@my-server.com
```

---

## 🔐 Security Notes

* SSH keys are never logged or printed
* File is saved directly to `~/.ssh/` with secure permissions
* Only private key is extracted from your vault (not the full item)

---

## 💠 Example Output

```bash
🔍 Searching items with keyword 'aws'...
🔎 Search results:
0) aws-key-prod [ID: 123abc...]
1) aws-backup-key [ID: 456def...]

➡ Enter the index of the item to use: 0
📅 Fetching SSH private key for 'aws-key-prod'...

✅ SSH private key saved to: ~/.ssh/aws-key-prod
📖 Connect example:
  ssh -i ~/.ssh/aws-key-prod ubuntu@ec2-xx-xx-xx-xx.compute.amazonaws.com
```

---

## 🧪 Developer Tips

* Works well as part of a CI/CD or cloud-init flow
* Ideal for secure workstation/server setup with GitHub, AWS, etc.

---

## 📄 License

MIT License © 2025 nocturover

Feel free to fork, contribute, or improve.

