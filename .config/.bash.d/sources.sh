# ROS2 setup
ROS_DIR="/opt/ros/${ROS_DISTRO}"
if [ -d "$ROS_DIR" ]; then
    source ${ROS_DIR}/setup.bash
    source "/usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash"
    [ -f "${BOAT_WS}/install/setup.bash" ] && source "${BOAT_WS}/install/setup.bash"
    source "/usr/share/colcon_cd/function/colcon_cd.sh"

    eval "$(register-python-argcomplete3 ros2)"
    eval "$(register-python-argcomplete3 colcon)"
    export _colcon_cd_root="$ROS_DIR"
fi
