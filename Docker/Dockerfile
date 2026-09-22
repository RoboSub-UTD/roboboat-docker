ARG ROS_DISTRO="humble"

ARG USER="root"
ARG HOME="/${USER}"
ARG BOAT_WS="${HOME}/roboboat_ws"

ARG PKGS_BASE="git wget curl jq gnupg"
ARG PKGS_DEV="software-properties-common apt-utils python3-minimal python-is-python3 python3-pip python3-vcstool python3-colcon-common-extensions net-tools iputils-ping ros-dev-tools ros-${ROS_DISTRO}-velodyne ros-${ROS_DISTRO}-rmw-cyclonedds-cpp ros-${ROS_DISTRO}-point-cloud-transport ros-${ROS_DISTRO}-robot-localization libturbojpeg vim ros-${ROS_DISTRO}-vision-msgs-rviz-plugins"
# GUI tooling (rqt_graph & co., rviz2). Explicit: nothing else in the image depends on them.
ARG PKGS_GUI="ros-${ROS_DISTRO}-rqt-common-plugins ros-${ROS_DISTRO}-rqt-tf-tree ros-${ROS_DISTRO}-rviz2"

#####################
# DEVELOPMENT IMAGE #
#####################
FROM ros:${ROS_DISTRO}-ros-core AS development
# Build-time only (ARG, not ENV): must not leak into the running container.
ARG DEBIAN_FRONTEND=noninteractive

RUN sed -i 's,http://[^ ]*archive\.ubuntu\.com/ubuntu,mirror://mirrors.ubuntu.com/mirrors.txt,g' /etc/apt/sources.list

# Setup Environment
ARG PKGS_BASE
ARG PKGS_DEV
ARG PKGS_GUI
ARG BOAT_WS
ARG ROS_DISTRO
ARG USER="root"
ARG HOME="/${USER}"

ENV USER=${USER}
ENV HOME=${HOME}
ENV BOAT_WS=${BOAT_WS}
RUN mkdir -p ${BOAT_WS}/src

## .bashrc
COPY .config/.bashrc ${HOME}/.bashrc
COPY .config/.bash.d ${HOME}/.bash.d

RUN apt-get update -y && apt-get install -y --no-install-recommends \
  ${PKGS_BASE} ${PKGS_DEV} ${PKGS_GUI} \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set the RMW implementation to CycloneDDS
ENV RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

# Workspace sources
ARG GALAXSEA_REPO="RoboSub-UTD/galaxsea"
ARG ROS_TCP_ENDPOINT_REPO="Unity-Technologies/ROS-TCP-Endpoint"
ARG ROS_TCP_ENDPOINT_BRANCH="main-ros2"
RUN cd ${BOAT_WS}/src && \
  git clone --depth 1 https://github.com/${GALAXSEA_REPO}.git && \
  git clone --depth 1 --branch ${ROS_TCP_ENDPOINT_BRANCH} https://github.com/${ROS_TCP_ENDPOINT_REPO}.git

# Add ROS2-Specific configurations to `.bashrc`
RUN /bin/bash -c "\
  echo 'source /opt/ros/${ROS_DISTRO}/setup.bash' >> ${HOME}/.bashrc; \
  echo '[ -f ${BOAT_WS}/install/setup.bash ] && source ${BOAT_WS}/install/setup.bash' >> ${HOME}/.bashrc; \
  echo 'source /usr/share/colcon_cd/function/colcon_cd.sh' >> ${HOME}/.bashrc; \
  echo 'source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash' >> ${HOME}/.bashrc; \
  echo 'export _colcon_cd_root=/opt/ros/${ROS_DISTRO}/' >> ${HOME}/.bashrc; \
  echo 'cd ${BOAT_WS}' >> ${HOME}/.bashrc"

# Set Entrypoint Script
COPY ./Docker/entrypoint.sh ${HOME}
RUN chmod +x ${HOME}/entrypoint.sh
ENTRYPOINT "${HOME}/entrypoint.sh"
