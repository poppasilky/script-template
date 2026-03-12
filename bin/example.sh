#!/bin/bash
#
# example.sh - Starfleet Navigation Computer (Lab Template)
#
# DESCRIPTION:
#   Calculates interstellar travel time and arrival dates using 
#   floating-point math and precise date offsets.
#   Demonstrates tools.sh integration, 'bc' math, and 'date' manipulation.
#
# USAGE:
#   ./example.sh [-h] [-d]
#
# AUTHOR: Bill Newman & Gemini
# VERSION: 1.2.0
# DATE: 2026-03-12
#
# ----------------------------------------------------------------------

# 1. Environment & Library Setup
# Ensure REPO_ROOT is defined (usually via .bashrc)
source "$REPO_ROOT/lib/tools.sh"

#######################################
# Displays script usage information and exits.
#######################################
usage() {
    cat <<EOF
USAGE: $(basename "$0") [OPTIONS]

DESCRIPTION:
    Calculates arrival age and date based on distance and velocity.
    Demonstrates the tools.sh library and advanced shell math.

OPTIONS:
    -h, --help      Display this help message and exit.
    -d, --debug     Enable debug mode (show log and pause points).

EXAMPLES:
    ./$(basename "$0")
    DEBUG=1 ./$(basename "$0")
EOF
    exit 0
}

# 2. Flag Parsing
while getopts "hd" opt; do
    case ${opt} in
        h ) usage ;;
        d ) export DEBUG=1 ;; 
        \? ) echo "Invalid option. Use -h for help." >&2; exit 1 ;;
    esac
done

# 3. Dependency Check
if ! command -v bc &> /dev/null; then
    echo -e "\e[31mError:\e[m 'bc' is not installed. Run 'sudo apt install bc' first." >&2
    exit 1
fi

# 4. Input Phase
echo "--- STARFLEET NAVIGATION COMPUTER ---"
echo "Initializing Subspace Calculation..."
echo "------------------------------------"

echo -n "Enter Destination Star System: "
read -r DESTINATION

# Use the getNumber function from tools.sh
DIST=$(getNumber "Enter Distance in Light Years:")
AGE=$(getNumber "Enter Officer current age:")
VELOCITY=$(getNumber "Enter Velocity (percentage of c, e.g. 0.5):")

log "Inputs: Dist=$DIST, Age=$AGE, Vel=$VELOCITY"
pause 

# 5. Calculation Phase
# Time = Distance / Velocity
TRAVEL_TIME=$(echo "scale=4; $DIST / $VELOCITY" | bc -l)

# Calculate Arrival Age
RAW_ARRIVAL_AGE=$(echo "scale=4; $AGE + $TRAVEL_TIME" | bc -l)
FINAL_AGE=$(printf "%.2f" "$RAW_ARRIVAL_AGE")

# --- 6. Precise Date Manipulation ---
# 31556952 is the average seconds in a Gregorian year (including leap years)
SECONDS_PER_YEAR="31556952"

# We use 'bc' to get the total seconds, then 'printf' to ensure it's an integer
TRAVEL_SECONDS_RAW=$(echo "$TRAVEL_TIME * $SECONDS_PER_YEAR" | bc -l)
TRAVEL_SECONDS=$(printf "%.0f" "$TRAVEL_SECONDS_RAW")

# '@' tells the date command to parse Unix seconds
# We calculate the arrival by adding travel seconds to the current 'epoch' time
ARRIVAL_EPOCH=$(echo "$(date +%s) + $TRAVEL_SECONDS" | bc)
ARRIVAL_DATE=$(date -d "@$ARRIVAL_EPOCH" +"%B %d, %Y")

DAYS_INT=$(echo "$TRAVEL_SECONDS / 86400" | bc)
log "Travel Seconds: $TRAVEL_SECONDS | Days: $DAYS_INT"

# Add the calculated days to the current date
ARRIVAL_DATE=$(date -d "+$DAYS_INT days" +"%B %d, %Y")

# 7. Output Phase
echo "------------------------------------"
echo "NAVIGATION REPORT: $DESTINATION"
echo "------------------------------------"
echo "Departure Date: $(date +"%B %d, %Y")"
echo "Travel Time:    $TRAVEL_TIME years (~$DAYS_INT days)"
echo "Arrival Date:   $ARRIVAL_DATE"
echo "Officer Age:    $FINAL_AGE years"
echo "------------------------------------"

log "Navigation sequence complete."
