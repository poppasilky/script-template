```markdown
# 🕵️ Network Snitch – Unauthorized Device Detector

[![Bash](https://img.shields.io/badge/Bash-5.0+-4EAA25?logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**Network Snitch** automatically scans your local network, learns which devices are normal, and alerts you when a new, unknown device appears. It’s a simple but powerful tool for anyone who wants to keep an eye on their network security.

---

## 📖 Case Study

**The Problem**  
As a system administrator (or even a home user), you can’t monitor every device that connects to your network. Unauthorized devices can be a security risk, but checking manually is impractical.

**The Solution**  
This script automates network surveillance:
1. **Learn** – It scans your network and saves a baseline of known devices.
2. **Watch** – When run again, it compares the current scan to the baseline.
3. **Alert** – If a new IP appears, you get a bright red alert in your terminal, and the event is logged with a timestamp.

Now you can be notified the moment an intruder joins your network.

---

## ✨ Features

- 🔍 **Automatic subnet detection** – finds your local network without configuration.
- 📋 **Baseline creation** – run once to record known devices.
- 🚨 **Real‑time alerts** – colored terminal messages and detailed logs.
- 🛠 **Manual override** – specify a subnet if auto‑detection fails.
- 🐞 **Debug mode** – see what’s happening under the hood.
- 📦 **Lightweight** – only requires `nmap` and standard Linux tools.

---

## 📦 Requirements

- **Linux** (or WSL on Windows)
- **nmap** – install with:
  ```bash
  sudo apt update && sudo apt install nmap -y
  ```
- **Bash** 4.0 or later 

---

## 🚀 Usage

Clone the repository and make the script executable:

```bash
git clone https://github.com/yourusername/script-template.git
cd script-template/bin
chmod +x network_snitch.sh
```

### 1. Create a baseline (run once)
```bash
./network_snitch.sh -b
```
This scans your network and saves the list of live IPs to `~/.network_snitch_baseline`.

### 2. Check for new devices
```bash
./network_snitch.sh -c
```
If a new device is found, you’ll see a red alert:
```
[!] New device detected: <IP address>
```
All alerts are logged to `~/.network_snitch.log`.

### 3. Manual subnet (if needed)
If auto‑detection doesn’t work, specify the subnet directly:
```bash
./network_snitch.sh -s 192.168.1.0/24 -b
```

### 4. Debug mode
```bash
./network_snitch.sh -d -c
```

---

## 🧪 Testing in GitHub Codespace

Because Codespaces have limited network access, you can test the script’s logic using mock data.  
Open a Codespace from your repository and run:

```bash
# Create a fake baseline
echo -e "192.168.1.1\n192.168.1.42" > ~/.network_snitch_baseline

# Simulate a scan with a new IP
echo -e "192.168.1.1\n192.168.1.42\n192.168.1.100" | sort > /tmp/mock_scan
comm -23 /tmp/mock_scan ~/.network_snitch_baseline
```

You’ll see the new IP – exactly the logic the script uses.  
(For a full demo, you can also install `nmap` in the Codespace, but the network will be limited.)

---

## 📜 License

This project is licensed under the **MIT License** – see the [LICENSE](LICENSE) file for details.

---

## 🙏 Attribution

- Built as a final project for **IT135 – Introduction to Linux** at North Seattle College.
- Inspired by the **Script Template Repo** provided by the instructor.
- Assistance from **Gemini** for brainstorming and templates.

---

## 👤 Author

**Ryan Hill** – IT135 Student, North Seattle College  
GitHub: [@poppasilky](https://github.com/poppasilky)

---

*If you find this tool useful, feel free to share it or adapt it for your own network monitoring needs!*
```
