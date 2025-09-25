# [TODO] Find faster mirrors again, and uncomment this and `sed` lines
# ARG MIRROR='http://dal.mirrors.clouvider.net' # [INFO] Found using apt-select --country US -t 10 
ARG ROS_DISTRO='humble'
ARG DEBIAN_FRONTEND='noninteractive'

###############
# BUILD IMAGE #
###############
FROM ros:${ROS_DISTRO}-ros-core AS builder
SHELL ["/bin/bash", "-c"]

# Use Faster Mirrors
# RUN sed -r -i "s,http://(.*).ubuntu.com,${MIRROR}," /etc/apt/sources.list

# Setup Environment
ENV USER='root'
ENV HOME="/${USER}"

# Setup Workspace
ENV BOAT_WS="${HOME}/roboboat_ws"
RUN mkdir -p "${BOAT_WS}/src"

# [INFO] Install the default Gazebo pairing with the ROS2 distribution
RUN wget https://packages.osrfoundation.org/gazebo.gpg -O /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg && \
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null && \
  add-apt-repository -y universe && \
  apt-get update && apt-get -y --no-install-recommends install \
  cmake wget curl git lsb-release build-essential \
  software-properties-common python3-sdformat13  \
  # ROS2 Gazebo Packages
  gz-fortress \
  ros-${ROS_DISTRO}-ros-gzfortress \
  ros-${ROS_DISTRO}-xacro \
  python3-colcon-common-extensions \
  ros-${ROS_DISTRO}-image-transport && \
  apt-get clean && rm -rf /var/lib/apt/lists/*

# [TODO] Add ZED SDK support
# [INFO] Build the VRX simulation and ZED ROS2 Wrapper packages
ARG VRX_REPO='osrf/vrx'
ARG VRX_BRANCH='v3.0.4'
# ARG ZED_REPO='stereolabs/zed-ros2-wrapper'
# ARG ZED_BRANCH='humble-v5.0.0'
WORKDIR ${BOAT_WS}/src
RUN git clone --progress --verbose --recursive --depth 1 --branch ${VRX_BRANCH} https://github.com/${VRX_REPO}.git && \
  # git clone --progress --verbose --recursive --depth 1 --branch ${ZED_BRANCH} https://github.com/${ZED_REPO}.git && \
  cd ${BOAT_WS} && source /opt/ros/${ROS_DISTRO}/setup.bash && \
  colcon build --symlink-install --parallel-workers $(nproc) --cmake-args=-DCMAKE_BUILD_TYPE=Release --base-paths src && \
  apt-get clean && rm -rf /var/lib/apt/lists/*

##############
# BASE IMAGE #
##############
FROM ros:humble-ros-core AS base
SHELL ["/bin/bash", "-c"]

# RUN sed -r -i "s,http://(.*).ubuntu.com,${MIRROR}," /etc/apt/sources.list

# Setup Environment
ENV USER='root'
ENV HOME="/${USER}"
ENV BOAT_WS="${HOME}/roboboat_ws"
RUN mkdir -p ${BOAT_WS}

## ROS2
ENV RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

## .bashrc
COPY .config/.bashrc ${HOME}/.bashrc
COPY .config/.bash.d ${HOME}/.bash.d

# Install common packges
RUN apt-get update && apt-get -y --no-install-recommends install \
  software-properties-common apt-utils wget curl \
  python3-minimal python-is-python3 python3-pip \
  python3-vcstool ros-dev-tools \
  python3-colcon-common-extensions \
  ros-${ROS_DISTRO}-point-cloud-transport \
  ros-${ROS_DISTRO}-robot-localization \
  ros-${ROS_DISTRO}-velodyne \
  ros-${ROS_DISTRO}-rmw-cyclonedds-cpp && \
  apt-get clean && rm -rf /var/lib/apt/lists/*

# Add ROS2-Specific configurations to `.bashrc`
RUN echo "source ${BOAT_WS}/install/setup.bash" >> ${HOME}/.bashrc && \
  echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> ${HOME}/.bashrc && \
  echo "source /usr/share/colcon_cd/function/colcon_cd.sh" >> ${HOME}/.bashrc && \
  echo "source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash" >> ${HOME}/.bashrc && \
  echo "export _colcon_cd_root=/opt/ros/${ROS_DISTRO}/" >> ${HOME}/.bashrc && \
  echo "cd ${BOAT_WS}" >> ${HOME}/.bashrc

# Set Entrypoint Script
COPY ./Docker/entrypoint.sh ${HOME}
RUN chmod +x ${HOME}/entrypoint.sh
ENTRYPOINT "${HOME}/entrypoint.sh" 

#####################
# DEVELOPMENT IMAGE #
#####################
FROM base AS development

# Copy files from the builder
COPY --from=builder_vrx ${BOAT_WS}/install ${BOAT_WS}/install

# Install Dependencies
RUN apt-get update && apt-get -y --no-install-recommends install \
  net-tools iputils-ping \ 
  libturbojpeg && \
  apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Gazebo Garden
RUN wget https://packages.osrfoundation.org/gazebo.gpg -O /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg && \
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null && \
  apt-get update && apt-get -y --no-install-recommends install \
  python3-sdformat13 gz-fortress \
  python3-colcon-common-extensions \
  ros-${ROS_DISTRO}-xacro \
  ros-${ROS_DISTRO}-ros-gzgarden \
  ros-${ROS_DISTRO}-image-transport \
  ros-${ROS_DISTRO}-rmw-cyclonedds-cpp && \
  apt-get clean && rm -rf /var/lib/apt/lists/*

#################
# RELEASE IMAGE #
#################
FROM base AS release

WORKDIR ${BOAT_WS}/src
COPY ./src/roboboat2025_ros2 .
RUN source /opt/ros/${ROS_DISTRO}/setup.bash && \
  colcon build --parallel-workers $(nproc) --merge-install --base-paths src && \
  apt-get clean && rm -rf /var/lib/apt/lists/*
