ARG ROS_DISTRO="humble"

ARG USER="root"
ARG HOME="/${USER}"
ARG BOAT_WS="${HOME}/roboboat_ws"

ARG PKGS_BASE="git wget curl jq"
ARG PKGS_DEV="software-properties-common apt-utils python3-minimal python-is-python3 python3-pip python3-vcstool python3-colcon-common-extensions net-tools iputils-ping ros-dev-tools  ros-${ROS_DISTRO}-velodyne ros-${ROS_DISTRO}-rmw-cyclonedds-cpp ros-${ROS_DISTRO}-point-cloud-transport ros-${ROS_DISTRO}-robot-localization libturbojpeg"
ARG PKGS_SIM="ros-${ROS_DISTRO}-ros-gz gz-harmonic"

# ZED SDK args
ARG ZED_SDK_URL="https://download.stereolabs.com/zedsdk/5.0/cu12/ubuntu22"
ARG PKGS_ZED_SDK="zstd less cmake gnupg2 build-essential python3 python3-pip python3-dev python3-setuptools python3-wheel libusb-1.0-0-dev libgeographic-dev libdraco-dev zlib1g-dev lsb-release udev build-essential libpq-dev usbutils"
ARG PKGS_PIP_ZED_SDK="cython numpy opencv-python-headless protobuf"

###########
# BUILDER #
###########
# The goal of this image is to build the following images:
# - osrf/vrx (2.4.1)
# - sterolabs/zed-ros2-wrapper
FROM ros:${ROS_DISTRO}-ros-base AS builder
ENV DEBIAN_FRONTEND=noninteractive

# Redeclare global args
ARG PKGS_BASE 
ARG PKGS_SIM
ARG PKGS_ZED_SDK
ARG PKGS_PIP_ZED_SDK
ARG BOAT_WS
ARG ZED_SDK_URL
ARG ROS_DISTRO 

RUN apt-get update -y && apt-get install -y --no-install-recommends \
  ${PKGS_BASE} && \
  apt-get clean && rm -rf /var/lib/apt/lists/*

# Install the ZED SDK
# RUN echo "[INFO] ZED SDK link: $ZED_SDK_URL" && \
#   if [ "$(curl -L -I "${ZED_SDK_URL}" -o /dev/null -s -w '%{http_code}\n' | head -n 1)" = "200" ]; then \
#   echo "[OKAY] ZedSDK URL exists"; \
#   else \
#   echo "[ERROR] ZedSDK URL does not point to a .run file or the file does not exist."; \
#   exit 1; \
#   fi; \
#   wget -q -O ZED_SDK_Linux_Ubuntu.run ${ZED_SDK_URL} && \
#   chmod +x ZED_SDK_Linux_Ubuntu.run && \
#   ./ZED_SDK_Linux_Ubuntu.run -- silent skip_tools skip_cuda && \
#   ln -sf /lib/x86_64-linux-gnu/libusb-1.0.so.0 /usr/lib/x86_64-linux-gnu/libusb-1.0.so && \
#   rm ZED_SDK_Linux_Ubuntu.run && \
#   rm -rf /var/lib/apt/lists/*

# Install Gazebo Harmonic, dependency for osrf/vrx
RUN curl https://packages.osrfoundation.org/gazebo.gpg --output /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg && \
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] https://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null && \
  apt-get update -y && apt-get install -y --no-install-recommends ${PKGS_SIM} \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

ARG VRX_REPO='osrf/vrx'
ARG VRX_BRANCH='v3.0.4'
ARG ZED_REPO='stereolabs/zed-ros2-wrapper'
ARG ZED_BRANCH='humble-v5.0.0'
RUN /bin/bash -c "mkdir -p "${BOAT_WS}/src" && cd "${BOAT_WS}/src" && \
  apt-get update -y && \
  ls -la /opt/ros/${ROS_DISTRO} && source /opt/ros/${ROS_DISTRO}/setup.bash && \
  git clone --progress --verbose --recursive --depth 1 --branch ${VRX_BRANCH} https://github.com/${VRX_REPO}.git && \
  # git clone --progress --verbose --recursive --depth 1 --branch ${ZED_BRANCH} https://github.com/${ZED_REPO}.git && \
  cd ${BOAT_WS} && \
  rosdep update && rosdep install --from-paths src --ignore-src -r -y && \
  colcon build --parallel-workers $(nproc) --merge-install \
  --event-handlers console_direct+ --base-paths src"
# These are for ZED SDK
# --cmake-args ' -DCMAKE_BUILD_TYPE=Release' \
# ' -DCMAKE_LIBRARY_PATH=/usr/local/cuda/lib64/stubs' \
# ' -DCMAKE_CXX_FLAGS=\"-Wl,--allow-shlib-undefined\"'"

#####################
# DEVELOPMENT IMAGE #
#####################
FROM ros:${ROS_DISTRO}-ros-core AS development

RUN sed -i 's,http://[^ ]*archive\.ubuntu\.com/ubuntu,mirror://mirrors.ubuntu.com/mirrors.txt,g' /etc/apt/sources.list

# Setup Environment
ARG PKGS_BASE 
ARG PKGS_SIM
ARG PKGS_DEV
ARG BOAT_WS
ARG ROS_DISTRO 
ARG USER="root"
ARG HOME="/${USER}"

ENV USER=${USER}
ENV HOME=${HOME}
ENV BOAT_WS=${BOAT_WS}
RUN mkdir -p ${BOAT_WS}

## .bashrc
COPY .config/.bashrc ${HOME}/.bashrc
COPY .config/.bash.d ${HOME}/.bash.d

RUN curl https://packages.osrfoundation.org/gazebo.gpg --output /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg && \
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] https://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null && \
  apt-get update -y && apt-get install -y --no-install-recommends \
  ${PKGS_BASE} ${PKGS_DEV} ${PKGS_SIM} \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set the RMW implementation to CycloneDDS
ENV RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

# Copy files from the builder
COPY --from=builder ${BOAT_WS}/install ${BOAT_WS}/install
# Add ROS2-Specific configurations to `.bashrc`
RUN /bin/bash -c "\
  echo 'source /opt/ros/${ROS_DISTRO}/setup.bash' >> ${HOME}/.bashrc; \
  echo 'source ${BOAT_WS}/install/setup.bash' >> ${HOME}/.bashrc; \
  echo 'source /usr/share/colcon_cd/function/colcon_cd.sh' >> ${HOME}/.bashrc; \
  echo 'source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash' >> ${HOME}/.bashrc; \
  echo 'export _colcon_cd_root=/opt/ros/${ROS_DISTRO}/' >> ${HOME}/.bashrc; \
  echo 'cd ${BOAT_WS}' >> ${HOME}/.bashrc"

# Set Entrypoint Script
COPY ./Docker/entrypoint.sh ${HOME}
RUN chmod +x ${HOME}/entrypoint.sh
ENTRYPOINT "${HOME}/entrypoint.sh" 
