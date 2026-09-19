#!/usr/bin/env bash
# Entrypoint for the zed-sim image: source ROS 2 and the wrapper overlay, then exec the command.
set -e
source "/opt/ros/${ROS_DISTRO}/setup.bash"
source "${ZED_WS}/install/local_setup.bash"
exec "$@"
