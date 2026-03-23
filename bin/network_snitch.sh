#!/usr/bin/env bash
#
# network_snitch.sh – Detect unknown devices on your network
# Author: Ryan Hill
# Date: 2026-03-22
# License: MIT

set -euo pipefail

# Defaults
LOG_FILE="$HOME/.network_snitch.log"
BASELINE_FILE="$HOME/.network_snitch_baseline"
DEBUG=false
SUBNET=""

# Help
usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Scan network and alert on new devices.

Options:
  -h          Show help
  -d          Debug mode
  -b          Create baseline
  -c          Check for new devices
  -s SUBNET   Subnet (e.g., 192.168.1.0/24)
  -l FILE     Log file (default: $LOG_FILE)
EOF
    exit 0
}

# Detect local subnet automatically
get_local_subnet() {
    if [[ -n "$SUBNET" ]]; then
        echo "$SUBNET"
        return 0
    fi

    local iface subnet
    iface=$(ip route show default | awk '/default/ {print $5}' 2>/dev/null)
    if [[ -n "$iface" ]]; then
        subnet=$(ip route show dev "$iface" | grep -v 'default' | grep -m1 'proto kernel' | awk '{print $1}' 2>/dev/null)
        if [[ -n "$subnet" ]]; then
            echo "$subnet"
            return 0
        fi
    fi

    for iface in $(ip -o link show | awk -F': ' '{print $2}' | grep -v lo); do
        local cidr
        cidr=$(ip -o -4 addr show dev "$iface" | awk '{print $4}' | head -1)
        if [[ -n "$cidr" ]]; then
            echo "$cidr"
            return 0
        fi
    done

    echo "Error: Could not detect subnet. Use -s." >&2
    exit 1
}

# Scan network and return IPs
scan_network() {
    if ! command -v nmap &>/dev/null; then
        echo "Error: nmap not installed (sudo apt install nmap)." >&2
        exit 1
    fi
    local subnet
    subnet=$(get_local_subnet)
    $DEBUG && echo "DEBUG: Scanning $subnet" >&2
    nmap -sn "$subnet" | grep 'Nmap scan report' | awk '{print $NF}' | tr -d '()'
}

# Alert: print red and log
alert() {
    echo -e "\033[31m[!] $1\033[0m" >&2
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" >> "$LOG_FILE"
}

# Create baseline
create_baseline() {
    echo "Creating baseline of known devices..."
    if ! scan_network | sort > "$BASELINE_FILE"; then
        echo "Failed." >&2
        exit 1
    fi
    local count
    count=$(wc -l < "$BASELINE_FILE")
    echo "Baseline created with $count device(s)."
    $DEBUG && echo "DEBUG: Baseline saved to $BASELINE_FILE"
}

# Check for intruders
check_for_intruders() {
    if [[ ! -f "$BASELINE_FILE" ]]; then
        echo "No baseline. Run '$0 -b' first." >&2
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

# Main
main() {
    while getopts "hdbcs:l:" opt; do
        case "$opt" in
            h) usage ;;
            d) DEBUG=true ;;
            b) ACTION="baseline" ;;
            c) ACTION="check" ;;
            s) SUBNET="$OPTARG" ;;
            l) LOG_FILE="$OPTARG" ;;
            *) usage ;;
        esac
    done
    shift $((OPTIND-1))

    if [[ -z "${ACTION:-}" ]]; then
        ACTION="check"
    fi

    case "$ACTION" in
        baseline) create_baseline ;;
        check)    check_for_intruders ;;
        *)        usage ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi