#!/bin/bash
set -euo pipefail

# Source environment variables from envs.sh
if [ -f /etc/nestri/envs.sh ]; then
    echo "Sourcing environment variables from envs.sh..."
    source /etc/nestri/envs.sh
else
    echo "envs.sh not found! Ensure it exists at /etc/nestri/envs.sh."
    exit 1
fi

# Configuration
MAX_RETRIES=3

# Helper function to restart the chain
restart_chain() {
    echo "Restarting nestri-server, compositor..."

    # Start nestri-server
    start_nestri_server
    RETRY_COUNT=0
}

# Function to start nestri-server
start_nestri_server() {
    if [[ -n "${NESTRI_PID:-}" ]] && kill -0 "${NESTRI_PID}" 2 >/dev/null; then
        echo "Killing existing nestri-server process..."
        kill "${NESTRI_PID}"
    fi

    echo "Starting nestri-server..."
    nestri-server $(echo $NESTRI_PARAMS) &
    NESTRI_PID=$!

    # Wait for Wayland display (wayland-1) to be ready
    echo "Waiting for Wayland display 'wayland-1' to be ready..."
    WAYLAND_SOCKET="/run/user/${UID}/wayland-1"
    for _ in {1..15}; do # Wait up to 15 seconds
        if [ -e "$WAYLAND_SOCKET" ]; then
            echo "Wayland display 'wayland-1' is ready."
            sleep 1  # necessary sleep - reduces chance that non-ready socket is used
            start_compositor
            return
        fi
        sleep 1
    done

    echo "Error: Wayland display 'wayland-1' did not appear. Incrementing retry count..."
    ((RETRY_COUNT++))
    if [ "$RETRY_COUNT" -ge "$MAX_RETRIES" ]; then
        echo "Max retries reached for nestri-server. Exiting."
        exit 1
    fi
    restart_chain
}

# Function to start compositor (labwc)
start_compositor() {
    if [[ -n "${COMPOSITOR_PID:-}" ]] && kill -0 "${COMPOSITOR_PID}" 2 >/dev/null; then
        echo "Killing existing compositor process..."
        kill "${COMPOSITOR_PID}"
    fi

    echo "Starting compositor..."
    rm -rf /tmp/.X11-unix && mkdir -p /tmp/.X11-unix && chown nestri:nestri /tmp/.X11-unix
    WAYLAND_DISPLAY=wayland-1 WLR_BACKENDS=wayland labwc &
    COMPOSITOR_PID=$!

    # Wait for compositor to initialize
    echo "Waiting for compositor to initialize..."
    COMPOSITOR_SOCKET="/run/user/${UID}/wayland-0"
    for _ in {1..15}; do
        if [ -e "$COMPOSITOR_SOCKET" ]; then
            echo "compositor is initialized, wayland-0 output ready."
            sleep 1  # necessary sleep - reduces chance that non-ready socket is used
            start_wlr_randr
            return
        fi
        sleep 1
    done

    echo "Error: compositor did not initialize correctly. Incrementing retry count..."
    ((RETRY_COUNT++))
    if [ "$RETRY_COUNT" -ge "$MAX_RETRIES" ]; then
        echo "Max retries reached for compositor. Exiting."
        exit 1
    fi
    start_compositor
}

# Function to run wlr-randr
start_wlr_randr() {
    echo "Configuring resolution with wlr-randr..."
    OUTPUT_NAME=$(WAYLAND_DISPLAY=wayland-0 wlr-randr --json | jq -r '.[] | select(.enabled == true) | .name' | head -n 1)
    if [ -z "$OUTPUT_NAME" ]; then
        echo "Error: No enabled outputs detected. Skipping wlr-randr."
        return
    fi

    # Retry logic for wlr-randr
    local WLR_RETRIES=0
    while ! WAYLAND_DISPLAY=wayland-0 wlr-randr --output "$OUTPUT_NAME" --custom-mode "$RESOLUTION"; do
        echo "Error: Failed to configure wlr-randr. Retrying..."
        ((WLR_RETRIES++))
        if [ "$WLR_RETRIES" -ge "$MAX_RETRIES" ]; then
            echo "Max retries reached for wlr-randr. Moving on without resolution setup."
            return
        fi
        sleep 2
    done
    echo "wlr-randr configuration successful."
}

# Main loop to monitor processes
main_loop() {
    trap 'echo "Terminating...";
if [[ -n "${NESTRI_PID:-}" ]] && kill -0 "${NESTRI_PID}" 2>/dev/null; then
kill "${NESTRI_PID}"
fi
if [[ -n "${COMPOSITOR_PID:-}" ]] && kill -0 "${COMPOSITOR_PID}" 2>/dev/null; then
kill "${COMPOSITOR_PID}"
fi
    exit 0' SIGINT SIGTERM

    while true; do
        # Wait for any child process to exit
        wait -n

        # Check which process exited
        if ! kill -0 ${NESTRI_PID:-} 2 >/dev/null; then
            echo "nestri-server crashed. Restarting chain..."
            ((RETRY_COUNT++))
            if [ "$RETRY_COUNT" -ge "$MAX_RETRIES" ]; then
                echo "Max retries reached for nestri-server. Exiting."
                exit 1
            fi
            restart_chain
        elif ! kill -0 ${COMPOSITOR_PID:-} 2 >/dev/null; then
            echo "compositor crashed. Restarting compositor..."
            ((RETRY_COUNT++))
            if [ "$RETRY_COUNT" -ge "$MAX_RETRIES" ]; then
                echo "Max retries reached for compositor. Exiting."
                exit 1
            fi
            start_compositor
        fi
    done
}

# Initialize retry counter
RETRY_COUNT=0

# Start the initial chain
restart_chain

# Enter monitoring loop
main_loop
