# Changelog

All notable changes to NEXPEAS will be documented in this file.

## [1.0.0] - 2026-07-18

### Added
- Initial release of NEXPEAS
- Complete privilege escalation enumeration
- Flag detection (user.txt, root.txt, flag.txt, proof.txt)
- SUID binaries analysis with GTFOBins integration
- Capabilities and special permissions detection
- Network and port analysis
- Sensitive file discovery
- Database and configuration file hunting
- SSH key detection
- Git repository secrets scanning
- Comprehensive post-exploitation guide (post_exploit.md)
- HTTP server for remote deployment with auto IP detection
- Beautiful color-coded output with severity levels
- User and group enumeration
- Cron jobs and scheduled tasks analysis
- Process enumeration with root process identification
- Kernel version and vulnerability assessment
- Anti-forensics and cleanup recommendations
- Support for multiple Linux distributions
- Optimized with timeouts to prevent hanging
- No false positives with smart detection
- Professional banner and styled headers

### Features
- **Flag Hunting**: Automatic detection of CTF flags
- **SUID Analysis**: CRITICAL and HIGH risk classification
- **HTTP Server**: Built-in deployment mechanism
- **Performance**: Typical scan in <2 minutes
- **Aesthetics**: Vibrant colors and professional UI
- **Educational**: Included post-exploitation guide
- **Safe**: Non-destructive scanning

### Performance Improvements
- Implemented timeouts on all searches (2-10 seconds)
- Limited search depth to relevant directories
- Optimized find commands with maxdepth
- Efficient grep patterns

### Bug Fixes
- Fixed SSH key detection syntax error
- Fixed sudo password hanging issue
- Corrected SUID detection logic
- Improved error handling for missing files

---

## [1.1.0] - Unreleased

### Added
- **Deep Scanning Mode** (`--deep` flag)
  - UDP port listening detection
  - Process-to-port correlation mapping
  - /proc/self analysis (command line, working directory)
  - Configuration file detection in current directory
  - /etc/hosts enumeration
  - Dotfiles analysis (~/.bashrc, ~/.profile, ~/.ssh/config, ~/.bash_history)

- **Exhaustive Configuration File Discovery**
  - Docker containers detection (.dockerenv)
  - Cloud credentials scanning (.aws, .gcloud, .azure)
  - Environment variable files (.env, .env.local, etc)
  - Application configuration files (package.json, requirements.txt, Dockerfile)
  - Database configs (wp-config.php, database.yml)
  - SSH keys and authorized_keys
  - Backup and dump files
  - Hypervisor and container technology detection

- **Docker Container Escape Analysis**
  - Container detection and alerts
  - Docker daemon accessibility checks
  - Available images listing (with escape vector suggestions)
  - Volume analysis for breakout opportunities
  - Docker socket permissions analysis
  - Container mount point inspection
  - Critical escape vectors identification (docker run -v /:/host/)
  - Docker credentials extraction from config files

- **Additional Features**
  - Command-line argument parsing (--deep, --help)
  - Terminal history preservation (removed clear on banner)
  - Environment variable discovery in dotfiles
  - Alias analysis for privilege escalation

### Improved
- Enhanced network reconnaissance with TCP and UDP analysis
- Better shell configuration analysis for credential discovery
- Process correlation for better service identification
- Comprehensive file discovery across system
- Container-aware privilege escalation detection

---

## [Unreleased - Future]

### Planned Features
- [ ] JSON output format
- [ ] CSV export capabilities
- [ ] Web-based report viewer
- [ ] Automated GTFOBins exploit suggestions
- [ ] Integration with Metasploit
- [ ] Support for other Unix systems (BSD, macOS)
- [ ] Advanced kernel exploit detection
- [ ] Docker container detection and analysis
- [ ] Kubernetes cluster enumeration
- [ ] Windows Subsystem for Linux (WSL) detection
- [ ] Custom scanning profiles
- [ ] Real-time monitoring mode
- [ ] Database of known misconfigurations
- [ ] Automated remediation suggestions
- [ ] Multi-threaded scanning
- [ ] API endpoint for integration

### Improvements in Progress
- [ ] Reduce output verbosity option
- [ ] Custom color schemes
- [ ] Logging capabilities
- [ ] Performance benchmarking
- [ ] Extended GTFOBins database
- [ ] Better privilege escalation path detection

---

## Version History

### v0.9 (Beta)
- Internal testing and validation
- Community feedback gathering
- Documentation refinement

### v1.0 (Release)
- Public release
- GitHub publishing
- Community contribution opening

---

## How to Report Bugs

Found a bug? Please report it by creating an [Issue](https://github.com/yourusername/nexpeas/issues).

Include:
- Description of the issue
- Steps to reproduce
- Expected behavior
- Actual behavior
- System information (OS, Bash version)
- Output screenshot or log

---

## How to Request Features

Have an idea? Create a [Discussion](https://github.com/yourusername/nexpeas/discussions) or [Issue](https://github.com/yourusername/nexpeas/issues) with label `enhancement`.

---

## Compatibility

- Bash 5.0+
- Linux (Ubuntu, Debian, CentOS, Kali, Fedora, etc.)
- Standard Unix tools (find, grep, awk, sed)

---

## License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file.

---

Last Updated: July 18, 2026
