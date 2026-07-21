#!/bin/sh
# NEXPEAS - Unified version: Bash-complete OR sh-lite (auto-detect)
# Detects environment and runs best available implementation

# ============================================
# SHELL DETECTION & AUTO-EXEC
# ============================================
if [ -n "$NEXPEAS_SHELL_DETECTED" ]; then
    # Already in target shell, skip detection
    :
elif [ -z "$BASH_VERSION" ] && command -v bash >/dev/null 2>&1; then
    # Not in bash, but bash is available - re-exec for full version
    export NEXPEAS_SHELL_DETECTED=1
    exec bash "$0" "$@"
fi

# If we reach here: either in bash or sh without bash available
# Use appropriate implementation

if [ -n "$BASH_VERSION" ]; then
    # ================================================
    # BASH FULL VERSION (Complete Features)
    # ================================================
    set -o pipefail
    
    # Parse arguments for bash version
    DEEP_MODE=0
    while [[ $# -gt 0 ]]; do
        case $1 in
            --deep)
                DEEP_MODE=1
                shift
                ;;
            --help|-h)
                echo "Usage: ./nexpeas.sh [OPTIONS]"
                echo ""
                echo "OPTIONS:"
                echo "  --deep    Enable deep scanning (additional network correlation, dotfiles, UDP analysis)"
                echo "  --help    Show this help message"
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    # Colores vibrantes
    RED='\033[0;91m'
    GREEN='\033[0;92m'
    YELLOW='\033[0;93m'
    BLUE='\033[0;94m'
    CYAN='\033[0;96m'
    MAGENTA='\033[0;95m'
    LIME='\033[38;5;82m'
    ORANGE='\033[38;5;208m'
    PINK='\033[38;5;213m'
    BOLD='\033[1m'
    DIM='\033[2m'
    NC='\033[0m'

    # Contadores
    CRITICAL=0
    HIGH=0
    MEDIUM=0

    # Banner
    print_banner() {
        echo -e "${PINK}"
        cat << "EOF"
    ╔════════════════════════════════════════════════╗
    ║                                                ║
    ║        🔓  N E X P E A S  🔓                  ║
    ║    Privilege Escalation Assessment Tool       ║
    ║                                                ║
    ║     ~ Detección de Vectores de Escalada ~     ║
    ║                                                ║
    ║  [BASH FULL VERSION - Complete Features]      ║
    ║                                                ║
    ╚════════════════════════════════════════════════╝
EOF
        echo ""
        echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
    }

    print_header() {
        echo -e "\n${MAGENTA}╔═══════════════════════════════════════════════════╗${NC}"
        echo -e "${MAGENTA}║${NC} ${BOLD}${PINK}$1${NC}${MAGENTA} ║${NC}"
        echo -e "${MAGENTA}╚═══════════════════════════════════════════════════╝${NC}\n"
    }

    alert_critical() {
        echo -e "${RED}⛔ [CRITICAL]${NC} $1"
        ((CRITICAL++))
    }

    alert_high() {
        echo -e "${RED}🔴 [HIGH]${NC} $1"
        ((HIGH++))
    }

    alert_medium() {
        echo -e "${YELLOW}🟡 [MEDIUM]${NC} $1"
        ((MEDIUM++))
    }

    info() {
        echo -e "${GREEN}✅ ${NC} $1"
    }

    print_banner

    # ============================================
    # INFORMACIÓN BÁSICA
    # ============================================
    print_header "📋 INFORMACIÓN BÁSICA DEL SISTEMA"

    echo -e "${BLUE}👤 Usuario Actual:${NC}"
    whoami
    id
    echo ""

    echo -e "${BLUE}🖥️  Sistema Operativo:${NC}"
    uname -a
    echo ""

    echo -e "${BLUE}🔧 Kernel Versión:${NC}"
    uname -r
    echo ""

    if [ -f /etc/os-release ]; then
        echo -e "${BLUE}🐧 Distribución:${NC}"
        grep -E "^PRETTY_NAME|^NAME|^VERSION" /etc/os-release | head -3
        echo ""
    fi

    # ============================================
    # PROCESS & CONFIG
    # ============================================
    print_header "⚙️  PROCESO ACTUAL & CONFIGURACIÓN"

    echo -e "${BLUE}Comando del proceso actual:${NC}"
    if [ -f /proc/self/cmdline ]; then
        tr '\0' ' ' < /proc/self/cmdline && echo ""
    else
        echo "N/A"
    fi
    echo ""

    echo -e "${BLUE}Hostname del sistema:${NC}"
    cat /etc/hostname 2>/dev/null || echo "N/A"
    echo ""

    echo -e "${BLUE}Resoluciones internas (/etc/hosts - principales):${NC}"
    if [ -f /etc/hosts ]; then
        grep -v "^#" /etc/hosts | grep -v "^$" | grep -v "127.0.0.1\|::1" | head -5 || info "Solo localhost"
    else
        info "No encontrado"
    fi
    echo ""

    # ============================================
    # FLAGS
    # ============================================
    print_header "🚩 FLAGS & ARCHIVOS SENSIBLES"

    echo -e "${LIME}Buscando flags y archivos interesantes...${NC}\n"

    FLAGS_FOUND=0
    for pattern in "user.txt" "root.txt" "flag.txt" "*flag*" "proof.txt" "secret.txt"; do
        FOUND=$(timeout 3 find /home /root /tmp /opt -maxdepth 3 -iname "$pattern" -type f 2>/dev/null | head -5)
        if [ ! -z "$FOUND" ]; then
            echo "$FOUND" | while read flag; do
                SIZE=$(wc -c < "$flag" 2>/dev/null)
                alert_critical "🚩 FLAG ENCONTRADA: $flag ($SIZE bytes)"
                echo -e "${RED}   Contenido:${NC}"
                head -3 "$flag" 2>/dev/null | sed 's/^/   /'
                ((FLAGS_FOUND++))
            done
        fi
    done

    if [ $FLAGS_FOUND -eq 0 ]; then
        info "No se encontraron flags (user.txt, root.txt, etc)"
    fi
    echo ""

    # ============================================
    # SUDO
    # ============================================
    print_header "🔐 SUDO - ANÁLISIS DE PERMISOS"

    echo -e "${BLUE}¿Puedo ejecutar comandos con sudo?${NC}"
    SUDO_OUTPUT=$(echo "" | sudo -l 2>&1 | grep -v "password" 2>/dev/null)
    if echo "$SUDO_OUTPUT" | grep -qE "NOPASSWD|ALL="; then
        alert_critical "Sudo sin contraseña detectado:"
        echo "$SUDO_OUTPUT" | grep -vE "^Matching|^User|Defaults|env_reset|password" | sed 's/^/  /'
    elif echo "$SUDO_OUTPUT" | grep -q "("; then
        alert_high "Sudo disponible con estos permisos:"
        echo "$SUDO_OUTPUT" | grep -vE "^Matching|^User|Defaults|env_reset|password" | sed 's/^/  /'
    else
        info "No hay permisos de sudo (o requiere contraseña)"
    fi
    echo ""

    # ============================================
    # SUID
    # ============================================
    print_header "💀 SUID BINARIES - POTENCIALES VECTORES"

    echo -e "${BLUE}SUID Binaries (buscando en /usr, /bin, /sbin, /opt):${NC}"
    SUID_LIST=$(find /usr /bin /sbin /opt -perm -4000 -type f 2>/dev/null | sort)

    SUID_CRITICAL="/usr/bin/find /usr/bin/sudo /usr/bin/su /bin/bash /bin/sh /bin/zsh /usr/bin/env /usr/bin/nmap /usr/bin/strace"
    SUID_DANGEROUS="/usr/bin/passwd /usr/bin/chsh /usr/bin/chfn /usr/bin/newgrp /usr/bin/pkexec /bin/mount /bin/umount"

    if [ -z "$SUID_LIST" ]; then
        info "No se encontraron SUID binaries"
    else
        echo "$SUID_LIST" | while IFS= read -r binary; do
            if echo "$SUID_CRITICAL" | grep -qw "$binary"; then
                alert_critical "🚨 CRITICAL SUID (GTFOBins): $binary"
            elif echo "$SUID_DANGEROUS" | grep -qw "$binary"; then
                alert_high "SUID: $binary"
            else
                echo "  $binary"
            fi
        done
    fi
    echo ""

    echo -e "${BLUE}🟢 SHELL VERSION DETECTED: BASH (Full Features Enabled)${NC}"
    echo ""

else

    # ================================================
    # SH LITE VERSION (POSIX Only)
    # ================================================
    
    # Parse arguments for sh version
    DEEP_MODE=0
    while [ $# -gt 0 ]; do
        case $1 in
            --deep)
                DEEP_MODE=1
                shift
                ;;
            --help|-h)
                echo "Usage: ./nexpeas.sh [OPTIONS]"
                echo "OPTIONS:"
                echo "  --deep    Enable deep scanning"
                echo "  --help    Show this help message"
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    RED='\033[0;91m'
    GREEN='\033[0;92m'
    YELLOW='\033[0;93m'
    BLUE='\033[0;94m'
    CYAN='\033[0;96m'
    MAGENTA='\033[0;35m'
    NC='\033[0m'
    BOLD='\033[1m'

    CRITICAL=0
    HIGH=0
    MEDIUM=0

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

    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════╗"
    echo "║      NEXPEAS LITE (SH/POSIX mode)        ║"
    echo "║    Optimized for: Alpine, busybox, etc   ║"
    echo "╚══════════════════════════════════════════╝"
    echo -e "${NC}\n"

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
    SUDO_L=$(echo "" | sudo -l 2>&1 | grep -v "password")
    if echo "$SUDO_L" | grep -qE "NOPASSWD|ALL=" 2>/dev/null; then
        alert_critical "Sudo NOPASSWD detected!"
        echo "$SUDO_L" | grep -vE "^Matching|^User|Defaults" | head -5
    elif echo "$SUDO_L" | grep -q "(" 2>/dev/null; then
        alert_high "Sudo available"
    else
        info "No sudo or requires password"
    fi
    echo ""

    # SUID
    echo -e "${BOLD}[*] SUID Binaries${NC}"
    SUID_LIST=$(find /usr /bin /sbin /opt -perm -4000 -type f 2>/dev/null)
    if [ -n "$SUID_LIST" ]; then
        echo "$SUID_LIST" | while read -r binary; do
            case "$binary" in
                */find|*/sudo|*/su|*/bash|*/sh|*/nmap|*/strace|*/less)
                    alert_critical "CRITICAL SUID: $binary"
                    ;;
                */passwd|*/chfn|*/chsh|*/mount|*/umount)
                    alert_high "HIGH SUID: $binary"
                    ;;
                *)
                    info "SUID: $binary"
                    ;;
            esac
        done
    else
        info "No SUID binaries found"
    fi
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

    # DOCKER
    echo -e "${BOLD}[*] Container Detection${NC}"
    if [ -f /.dockerenv ]; then
        alert_critical "Running inside Docker container!"

        UID_MAP=$(cat /proc/self/uid_map 2>/dev/null | awk '$1==0{print "UID 0 -> UID " $2}')
        [ -n "$UID_MAP" ] && alert_high "$UID_MAP"

        MOUNTS=$(mount 2>/dev/null | grep -E "rw.*host|/logs|/home")
        if [ -n "$MOUNTS" ]; then
            alert_high "Writable bind mounts detected:"
            echo "$MOUNTS" | head -3
        fi

        if [ -S /var/run/docker.sock 2>/dev/null ]; then
            alert_critical "Docker socket accessible!"
        fi
    else
        info "Not in container"
    fi
    echo ""

    echo -e "${BLUE}🟠 SHELL VERSION DETECTED: SH/POSIX (Lite Mode)${NC}"
    echo ""

fi

# ============================================
# SUMMARY (Both versions)
# ============================================
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${RED}CRITICAL: $CRITICAL${NC} | ${YELLOW}HIGH: $HIGH${NC} | ${CYAN}MEDIUM: $MEDIUM${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ $CRITICAL -gt 0 ]; then
    echo -e "${RED}⚠️  CRITICAL VULNERABILITIES FOUND!${NC}"
elif [ $HIGH -gt 0 ]; then
    echo -e "${YELLOW}⚠️  HIGH RISK FINDINGS!${NC}"
else
    echo -e "${GREEN}✅ No critical issues detected${NC}"
fi
