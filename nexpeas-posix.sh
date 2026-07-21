#!/bin/sh
# NEXPEAS POSIX - 100% compatible with any sh (bash, dash, ash/Alpine, etc)
# Lightweight version for penetration testing environments

CRITICAL=0
HIGH=0
MEDIUM=0

# Colors
RED='\033[0;91m'
GREEN='\033[0;92m'
YELLOW='\033[0;93m'
BLUE='\033[0;94m'
CYAN='\033[0;96m'
MAGENTA='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

alert_critical() {
    echo -e "${RED}[CRITICAL]${NC} $1"
    CRITICAL=$((CRITICAL+1))
}

alert_high() {
    echo -e "${YELLOW}[HIGH]${NC} $1"
    HIGH=$((HIGH+1))
}

alert_medium() {
    echo -e "${CYAN}[MEDIUM]${NC} $1"
    MEDIUM=$((MEDIUM+1))
}

info() {
    echo -e "${GREEN}[+]${NC} $1"
}

banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════╗"
    echo "║      NEXPEAS POSIX - Priv Esc Check      ║"
    echo "║    Works on: bash, sh, dash, ash (etc)   ║"
    echo "╚══════════════════════════════════════════╝"
    echo -e "${NC}\n"
}

# ==========================================
# MAIN SCAN
# ==========================================
banner

echo -e "${BOLD}[*] System Information${NC}"
echo "User: $(whoami) | UID: $(id -u)"
echo "Hostname: $(hostname 2>/dev/null || cat /etc/hostname 2>/dev/null)"
echo "Kernel: $(uname -r)"
echo ""

# FLAGS
echo -e "${BOLD}[*] Searching for flags...${NC}"
FOUND_FLAGS=0
for pattern in "user.txt" "root.txt" "flag.txt" "proof.txt"; do
    FOUND=$(find /home /root /tmp /opt -maxdepth 3 -name "$pattern" -type f 2>/dev/null | head -3)
    if [ -n "$FOUND" ]; then
        echo "$FOUND" | while read -r f; do
            alert_critical "FLAG: $f"
            head -1 "$f" 2>/dev/null
            FOUND_FLAGS=$((FOUND_FLAGS+1))
        done
    fi
done
[ $FOUND_FLAGS -eq 0 ] && info "No flags found"
echo ""

# SUDO
echo -e "${BOLD}[*] SUDO Permissions${NC}"
SUDO_L=$(sudo -l 2>&1 | grep -v "password")
if echo "$SUDO_L" | grep -qE "NOPASSWD|ALL=" 2>/dev/null; then
    alert_critical "Sudo NOPASSWD detected!"
    echo "$SUDO_L" | grep -vE "^Matching|^User|Defaults" | head -5
elif echo "$SUDO_L" | grep -q "(" 2>/dev/null; then
    alert_high "Sudo available"
else
    info "No sudo or requires password"
fi
echo ""

# SUID BINARIES
echo -e "${BOLD}[*] SUID Binaries${NC}"
SUID_LIST=$(find /usr /bin /sbin /opt -perm -4000 -type f 2>/dev/null)
SUID_COUNT=0
if [ -n "$SUID_LIST" ]; then
    echo "$SUID_LIST" | while read -r binary; do
        case "$binary" in
            */find|*/sudo|*/su|*/bash|*/sh|*/nmap|*/less)
                alert_critical "CRITICAL SUID: $binary"
                ;;
            */passwd|*/chfn|*/chsh|*/mount|*/umount)
                alert_high "HIGH SUID: $binary"
                ;;
            *)
                info "SUID: $binary"
                ;;
        esac
        SUID_COUNT=$((SUID_COUNT+1))
    done
else
    info "No SUID binaries found"
fi
[ $SUID_COUNT -gt 0 ] && echo "Total SUID: $SUID_COUNT"
echo ""

# CAPABILITIES
echo -e "${BOLD}[*] Capabilities${NC}"
CAP_LIST=$(getcap -r /usr /bin /sbin /opt 2>/dev/null | grep -v "cap_net_bind_service")
if [ -n "$CAP_LIST" ]; then
    echo "$CAP_LIST" | while read -r cap; do
        alert_medium "CAP: $cap"
    done
else
    info "No dangerous capabilities"
fi
echo ""

# DOCKER/CONTAINER
echo -e "${BOLD}[*] Container Detection${NC}"
if [ -f /.dockerenv ]; then
    alert_critical "Running inside Docker container!"
    echo ""

    # Check UID mapping
    UID_MAP=$(cat /proc/self/uid_map 2>/dev/null | awk '$1==0{print "UID 0 -> UID " $2}')
    [ -n "$UID_MAP" ] && alert_high "$UID_MAP"

    # Check bind mounts
    MOUNTS=$(mount 2>/dev/null | grep -E "rw.*host|/logs|/home")
    if [ -n "$MOUNTS" ]; then
        alert_high "Writable bind mounts detected:"
        echo "$MOUNTS" | while read -r m; do
            echo "  $m"
        done
    fi

    # Docker socket
    if [ -S /var/run/docker.sock 2>/dev/null ]; then
        alert_critical "Docker socket accessible!"
    fi
else
    info "Not in container"
fi
echo ""

# CRON
echo -e "${BOLD}[*] Cron Jobs${NC}"
CRON=$(crontab -l 2>&1 | grep -v "^#" | grep -v "^$")
if [ -n "$CRON" ]; then
    alert_medium "User cron jobs found:"
    echo "$CRON"
else
    info "No cron jobs"
fi
echo ""

# SUMMARY
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${RED}CRITICAL: $CRITICAL${NC} | ${YELLOW}HIGH: $HIGH${NC} | ${CYAN}MEDIUM: $MEDIUM${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ $CRITICAL -gt 0 ]; then
    echo -e "${RED}⚠️  CRITICAL VULNERABILITIES FOUND!${NC}"
elif [ $HIGH -gt 0 ]; then
    echo -e "${YELLOW}⚠️  HIGH RISK FINDINGS!${NC}"
else
    echo -e "${GREEN}✅ No critical issues${NC}"
fi
