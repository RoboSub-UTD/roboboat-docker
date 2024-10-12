#!/usr/bin/bash

BOAT_WS=/root/roboboat_ws

source /opt/ros/humble/setup.bash
if [ -f "${BOAT_WS}/install/setup.bash" ] 
then
    source "${BOAT_WS}/install/setup.bash"
fi

cd "${BOAT_WS}"

if [[ $# -eq 0 ]]; then
  exec "/bin/bash"
else
  # Optionally, add a specific check for ROS-related commands if needed.
  exec "$@"
fi
