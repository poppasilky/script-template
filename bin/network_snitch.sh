#!/usr/bin/env bash
#
# network_snitch.sh – Detect unknown devices on your network
# Author: Your Name
# Date: 2026-03-22
# License: MIT
#
# Automatically finds your local subnet, scans with nmap,
# creates a baseline, and alerts when new devices appear.

set -euo pipefail

# --- Default configuration ------------------------------------------------
LOG_FILE="${HOME}/.network_snitch.log"
BASELINE_FILE="${HOME}/.network_snitch_baseline"
DEBUG=false

# --- Usage ----------------------------------------------------------------
usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Monitors your network for unknown devices. Detects your local subnet automatically.

Options:
  -h          Show this help
  -d          Enable debug output
  -b          Create/update baseline of known devices
  -c          Check for new devices (default if no -b)
  -l FILE     Log file (default: ${LOG_FILE})

Examples:
  $(basename "$0") -b          # Create baseline
  $(basename "$0") -c          # Check for intruders (needs baseline)
EOF
    exit 0
}

# --- Helper: detect local subnet -------------------------------------------
get_local_subnet() {
    local iface subnet
    iface=$(ip route show default | awk '/default/ {print $5}' 2>/dev/null)
    if [[ -z "$iface" ]]; then
        echo "Error: No default network interface found." >&2
        exit 1
    fi
    subnet=$(ip route show dev "$iface" | grep -m1 'proto kernel' | awk '{print $1}' 2>/dev/null)
    if [[ -z "$subnet" ]]; then
        echo "Error: Could not determine subnet for interface $iface." >&2
        exit 1
    fi
    echo "$subnet"
}

# --- Network scan ---------------------------------------------------------
scan_network() {
    if ! command -v nmap &>/dev/null; then
        echo "Error: nmap is not installed. Install it (sudo apt install nmap)." >&2
        exit 1
    fi
    local subnet
    subnet=$(get_local_subnet)
    $DEBUG && echo "DEBUG: Scanning subnet $subnet" >&2
    nmap -sn "$subnet" | grep 'Nmap scan report' | awk '{print $NF}' | tr -d '()'
}

# --- Alert ----------------------------------------------------------------
alert() {
    local message="[!] $1"
    echo -e "\033[31m$message\033[0m" >&2
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" >> "$LOG_FILE"
}

# --- Create baseline ------------------------------------------------------
create_baseline() {
    echo "Creating baseline of known devices..."
    if ! scan_network | sort > "$BASELINE_FILE"; then
        echo "Failed to create baseline." >&2
        exit 1
    fi
    local count
    count=$(wc -l < "$BASELINE_FILE")
    echo "Baseline created with $count device(s)."
    $DEBUG && echo "DEBUG: Baseline saved to $BASELINE_FILE" >&2
}

# --- Check for intruders --------------------------------------------------
check_for_intruders() {
    if [[ ! -f "$BASELINE_FILE" ]]; then
        echo "No baseline found. Run '$0 -b' first." >&2
        exit 1
    fi

    echo "Checking for new devices..."
    local current new_devices
    current=$(scan_network | sort) || exit 1
    new_devices=$(comm -23 <(echo "$current") <(cat "$BASELINE_FILE"))

    if [[ -z "$new_devices" ]]; then
        echo "All devices are known."
    else
        echo "$new_devices" | while read -r ip; do
            alert "New device detected: $ip"
        done
    fi
}

# --- Main ----------------------------------------------------------------
main() {
    # Parse options
    while getopts "hdbcl:" opt; do
        case "$opt" in
            h) usage ;;
            d) DEBUG=true ;;
            b) ACTION="baseline" ;;
            c) ACTION="check" ;;
            l) LOG_FILE="$OPTARG" ;;
            *) usage ;;
        esac
    done
    shift $((OPTIND-1))

    # Default action is check if none given
    if [[ -z "${ACTION:-}" ]]; then
        ACTION="check"
    fi

    case "$ACTION" in
        baseline) create_baseline ;;
        check)    check_for_intruders ;;
        *)        usage ;;
    esac
}

# --- Run ------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi