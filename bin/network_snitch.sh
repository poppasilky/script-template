#!/usr/bin/env bash
#
# network_snitch.sh – Detect unknown devices on your network
# Author: Ryan Hill
# Date: 2026-03-22
# License: MIT

set -euo pipefail

# --- Default configuration ------------------------------------------------
LOG_FILE="${HOME}/.network_snitch.log"
BASELINE_FILE="${HOME}/.network_snitch_baseline"
DEBUG=false
SUBNET=""   # optional manual override

# --- Usage ----------------------------------------------------------------
usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Monitors your network for unknown devices. Automatically detects your local subnet.

Options:
  -h          Show this help
  -d          Enable debug output
  -b          Create/update baseline of known devices
  -c          Check for new devices (default if no -b)
  -l FILE     Log file (default: ${LOG_FILE})
  -s SUBNET   Manually specify subnet (e.g., 192.168.1.0/24)

Examples:
  $(basename "$0") -b                # Auto-detect subnet and create baseline
  $(basename "$0") -c                # Check for intruders
  $(basename "$0") -s 172.18.240.0/20 -b   # Manual subnet override
EOF
    exit 0
}

# --- Helper: detect local subnet -------------------------------------------
get_local_subnet() {
    # If manual subnet was provided, use it
    if [[ -n "$SUBNET" ]]; then
        echo "$SUBNET"
        return 0
    fi

    # Try to get the network from default route interface
    local iface subnet
    iface=$(ip route show default | awk '/default/ {print $5}' 2>/dev/null)
    if [[ -n "$iface" ]]; then
        # Look for the network route (not the default) for that interface
        subnet=$(ip route show dev "$iface" | grep -v 'default' | grep -m1 'proto kernel' | awk '{print $1}' 2>/dev/null)
        if [[ -n "$subnet" ]]; then
            echo "$subnet"
            return 0
        fi
    fi

    # Fallback: scan all non-loopback interfaces for an IP and derive network
    for iface in $(ip -o link show | awk -F': ' '{print $2}' | grep -v lo); do
        local cidr
        cidr=$(ip -o -4 addr show dev "$iface" | awk '{print $4}' | head -1)
        if [[ -n "$cidr" ]]; then
            echo "$cidr"
            return 0
        fi
    done

    echo "Error: Could not detect subnet. Use -s to specify manually." >&2
    exit 1
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
    while getopts "hdbcl:s:" opt; do
        case "$opt" in
            h) usage ;;
            d) DEBUG=true ;;
            b) ACTION="baseline" ;;
            c) ACTION="check" ;;
            l) LOG_FILE="$OPTARG" ;;
            s) SUBNET="$OPTARG" ;;
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