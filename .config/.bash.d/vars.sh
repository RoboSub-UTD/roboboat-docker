export PATH="${PATH}:${HOME}/.local/bin"

ROBOBOAT2025_SIM_DIR="${BOAT_WS}/src/roboboat2025_ros2/custom_simulations"
export GZ_SIM_RESOURCE_PATH="${ROBOBOAT2025_SIM_DIR}/worlds:${ROBOBOAT2025_SIM_DIR}/models:${GZ_SIM_RESOURCE_PATH}"
