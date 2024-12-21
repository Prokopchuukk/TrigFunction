#!/usr/bin/env bash

# -------------------------------------------------------------------
# Configuration
# -------------------------------------------------------------------
IMAGE_NAME="prokopchukm/optimaserver:latest"
CONTAINER_NAMES=("srv1" "srv2" "srv3")
CPU_CORES=("0" "1" "2")  # CPU core pinning for each container

# Time in seconds to consider "consecutive" busy or idle intervals
CHECK_INTERVAL=25        # How often we check container usage
CONSECUTIVE_THRESH=2     # Number of consecutive intervals
BUSY_THRESHOLD="50"      # (example) CPU% threshold for "busy"
IDLE_THRESHOLD="15"      # (example) CPU% threshold for "idle"

# -------------------------------------------------------------------
# Helper Functions
# -------------------------------------------------------------------

# A function to check if a container is running
is_container_running() {
  local container="$1"
  docker ps --filter "name=${container}" --filter "status=running" --format '{{.Names}}' | grep -q "^${container}$"
}

# A function to get CPU usage (or some usage metric) for a container
get_container_cpu_usage() {
  local container="$1"
  # Example with docker stats for CPU%, no-stream
  # Output might look like "0.12%", so we remove '%' with sed
  local cpu_usage
  cpu_usage="$(docker stats --no-stream --format "{{.CPUPerc}}" "${container}" 2>/dev/null | sed 's/%//g')"
  echo "${cpu_usage:-0}"
}

# Evaluate if container is "busy" or "idle" based on CPU usage
# Returns 0 if normal, 1 if busy, -1 if idle
check_usage_state() {
  local usage="$1"
  local busy_threshold="$2"
  local idle_threshold="$3"

  # Convert usage to integer by truncating decimals
  local usage_int
  usage_int="${usage%.*}"

  # If usage is a floating-point number and has a decimal part, handle rounding
  if (( $(echo "$usage > 0" | bc -l) )); then
    if (( $(echo "$usage - $usage_int >= 0.5" | bc -l) )); then
      (( usage_int++ ))
    fi
  fi

  if (( usage_int > busy_threshold )); then
    echo "1"    # busy
  elif (( usage_int < idle_threshold )); then
    echo "-1"   # idle
  else
    echo "0"    # normal
  fi
}


# Launch a new container with name $1 pinned to CPU core $2
launch_container() {
  local name="$1"
  local cpu_core="$2"

  echo "Launching container ${name} on CPU core ${cpu_core}..."
  docker run -d \
    --name "${name}" \
    --cpuset-cpus="${cpu_core}" \
    -p 0.0.0.0:0:8081 \
    "${IMAGE_NAME}" 
}

# Stop and remove a container if it is running
stop_container() {
  local name="$1"
  if is_container_running "${name}"; then
    echo "Stopping container ${name}..."
    docker stop "${name}" >/dev/null && docker rm "${name}" >/dev/null
  fi
}

# -------------------------------------------------------------------
# Scale logic: Busy => Start next container, Idle => Stop container
# -------------------------------------------------------------------

# We store "consecutive busy" or "consecutive idle" counters
declare -A busyCount
declare -A idleCount

# Initialize arrays
for c in "${CONTAINER_NAMES[@]}"; do
  busyCount["$c"]=0
  idleCount["$c"]=0
done

# Make sure at least srv1 is started
if ! is_container_running "srv1"; then
  launch_container "srv1" "0"
fi

# -------------------------------------------------------------------
# Rolling Update Logic
# -------------------------------------------------------------------

# 1) Pull the latest version of the image
# 2) Update each container one by one, leaving at least one container always up

perform_rolling_update() {
  echo "Performing rolling update for image ${IMAGE_NAME}..."
  docker pull "${IMAGE_NAME}"

  # Sort containers in some order (e.g. srv2, srv3, then srv1),
  # so you always have at least one container up
  # OR do a pattern that keeps at least one container running.
  # For example: update srv2, then srv3, then srv1.

  local order=("srv2" "srv3" "srv1")

  for container in "${order[@]}"; do
    if is_container_running "${container}"; then
      echo "Updating container ${container}..."
      # Step 1: Start a temporary container with the new image
      local tmp_name="${container}_tmp"
      local idx
      # find which CPU core we pinned originally:
      for i in "${!CONTAINER_NAMES[@]}"; do
        if [[ "${CONTAINER_NAMES[$i]}" == "${container}" ]]; then
          idx=$i
          break
        fi
      done

      # Launch temporary container on the same CPU core
      launch_container "${tmp_name}" "${CPU_CORES[$idx]}"

      # (Optional) Wait for healthcheck or readiness, e.g. sleep 5
      sleep 5

      # Step 2: Stop the old container
      stop_container "${container}"

      # Step 3: Rename the temporary container to the original name
      docker rename "${tmp_name}" "${container}"
      echo "Container ${container} has been updated."
    fi
  done
  echo "Rolling update complete."
}

# -------------------------------------------------------------------
# Main Loop
# -------------------------------------------------------------------
# The loop:
# 1) Periodically checks usage of containers
# 2) Decides to start/stop containers based on busy/idle counters
# 3) (As an example) triggers an update check every N iterations

iteration=0
while true; do
  iteration=$((iteration+1))

  for i in "${!CONTAINER_NAMES[@]}"; do
    container="${CONTAINER_NAMES[$i]}"
    core="${CPU_CORES[$i]}"

    # Skip if container not running yet
    if ! is_container_running "${container}"; then
      continue
    fi

    # -- 1. Check usage --
    usage="$(get_container_cpu_usage "${container}")"
    state="$(check_usage_state "${usage}" "${BUSY_THRESHOLD}" "${IDLE_THRESHOLD}")"

    if [[ "$state" == "1" ]]; then
      # busy => increment busy counter
      busyCount["$container"]=$(( busyCount["$container"] + 1 ))
      idleCount["$container"]=0
    elif [[ "$state" == "-1" ]]; then
      # idle => increment idle counter
      idleCount["$container"]=$(( idleCount["$container"] + 1 ))
      busyCount["$container"]=0
    else
      # normal => reset both
      busyCount["$container"]=0
      idleCount["$container"]=0
    fi

    # -- 2. Scaling logic --
    # If container is busy for N consecutive intervals => start next container
    if [[ ${busyCount["$container"]} -ge ${CONSECUTIVE_THRESH} ]]; then
      # Attempt to launch the *next* container in the sequence
      if [[ "$container" == "srv1" ]] && ! is_container_running "srv2"; then
        launch_container "srv2" "1"
      elif [[ "$container" == "srv2" ]] && ! is_container_running "srv3"; then
        launch_container "srv3" "2"
      fi
      # reset busy count to avoid repeated spawns
      busyCount["$container"]=0
    fi

    # If container is idle for N consecutive intervals => stop it (but keep at least srv1 up)
    if [[ ${idleCount["$container"]} -ge ${CONSECUTIVE_THRESH} ]]; then
    # We don't want to kill srv1 if it's the only one running
      if [[ "$container" != "srv1" ]]; then
        echo "Container ${container} has been idle for too long. Stopping..."
        stop_container "${container}"
    fi
  # reset idle count
  idleCount["$container"]=0
fi

  done

  # -- 3. Check for new image updates every X iterations (example: every 10 checks) --
  if (( iteration % 10 == 0 )); then
    # Real production code might:
    #  - check a Docker Registry or version API
    #  - or unconditionally try a pull and compare layers
    # For simplicity, we'll do a rolling update to ensure we have the latest
    perform_rolling_update
  fi

  sleep "${CHECK_INTERVAL}"
done

