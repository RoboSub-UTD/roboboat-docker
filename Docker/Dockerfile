# Inspiration from https://github.com/sea-bass/turtlebot3_behavior_demos

FROM nvidia/cuda:12.1.1-devel-ubuntu22.04 AS base

# Using Dallas local mirror for faster speeds
SHELL ["/bin/bash", "-c"]
RUN sed -r -i 's,http://(.*).ubuntu.com,http://mirror.us-tx.kamatera.com,' /etc/apt/sources.list

# Setup Environment

## Get Ubuntu Version Information for ARGs

ARG DEBIAN_FRONTEND='noninteractive'
ARG ROS_DISTRO='humble'
ARG UBUNTU_MAJOR='22'
ARG CUDA_MAJOR='12'
ARG CUDA_MINOR='1'
ARG CUDA_PATCH='1'
ARG ZED_SDK_MAJOR='4'
ARG ZED_SDK_MINOR='2'
ARG ZED_SDK_PATCH='0'
ENV USER='root'
ENV HOME='/root'
ENV PATH="${PATH}:${HOME}/.local/bin"

##############
# BASE IMAGE #
##############

# Install Dependencies

RUN apt-get update && apt-get -y --no-install-recommends install \
    cmake dialog bash-completion wget curl git lsb-release less locales \
    udev zstd apt-utils libgomp1 sudo software-properties-common \
    build-essential libpng-dev jq libopencv-dev libpq-dev usbutils \
    python3 python3-dev python3-pip python3-argcomplete python-is-python3 \
    python3-flake8-docstrings python3-wheel python3-pytest-cov \
    python3-numpy python3-empy python3-lark python3-opencv && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ROS2 SETUP START

## Setup Locales
RUN locale-gen en_US en_US.UTF-8 && \
    update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 && \
    LANG=en_US.UTF-8

## Setup Sources & Install ROS2 Packages
RUN add-apt-repository -y universe && \
    curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null && \
    apt-get update && apt-get -y --no-install-recommends install \
    python3-vcstool ros-dev-tools \
    ros-${ROS_DISTRO}-ros-base \
    ros-${ROS_DISTRO}-velodyne \
    ros-${ROS_DISTRO}-rmw-cyclonedds-cpp && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

## Use Cyclone DDS as middleware
ENV RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

## Source the ROS2 Setup Script and save it in .bashrc
RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> ${HOME}/.bashrc

# ROS2 SETUP END

# Install ZED SDK START

ENV NVIDIA_DRIVER_CAPABILITIES=${NVIDIA_DRIVER_CAPABILITIES:+$NVIDIA_DRIVER_CAPABILITIES,}compute,video,utility

## ZED SDK link
ENV ZED_SDK_URL="https://stereolabs.sfo2.cdn.digitaloceanspaces.com/zedsdk/${ZED_SDK_MAJOR}.${ZED_SDK_MINOR}/ZED_SDK_Ubuntu${UBUNTU_MAJOR}_cuda${CUDA_MAJOR}.${CUDA_MINOR}_v${ZED_SDK_MAJOR}.${ZED_SDK_MINOR}.${ZED_SDK_PATCH}.zstd.run"

## Check that this SDK exists
RUN if [ "$(curl -I "${ZED_SDK_URL}" -o /dev/null -s -w '%{http_code}\n' | head -n 1)" = "200" ]; then \
    echo "The URL points to something."; \
    else \
    echo "The URL does not point to a .run file or the file does not exist."; \
    exit 1; \
    fi

## Install the SDK & Python API
RUN echo "CUDA Version $CUDA_VERSION" > /usr/local/cuda/version.txt && \
    wget -q -O ZED_SDK_Linux_Ubuntu.run ${ZED_SDK_URL} && \
    chmod +x ZED_SDK_Linux_Ubuntu.run && \
    ./ZED_SDK_Linux_Ubuntu.run -- silent skip_tools skip_cuda && \
    ln -sf /lib/x86_64-linux-gnu/libusb-1.0.so.0 /usr/lib/x86_64-linux-gnu/libusb-1.0.so && \
    rm ZED_SDK_Linux_Ubuntu.run && \
    rm -rf /var/lib/apt/lists/* && \
    python3 /usr/local/zed/get_python_api.py

# Install ZED SDK END

#####################
# DEVELOPMENT IMAGE #
#####################

FROM base AS development

# Setup ROS2 & Simulation Tools

## Additional Environment Variables
ENV BOAT_WS='/root/roboboat_ws'

RUN echo "source /usr/share/colcon_cd/function/colcon_cd.sh" >> ${HOME}/.bashrc && \
    echo "source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash" >> ${HOME}/.bashrc && \
    echo "export _colcon_cd_root=/opt/ros/humble/" >> ${HOME}/.bashrc && \
    wget https://packages.osrfoundation.org/gazebo.gpg -O /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null && \
    apt-get update && apt-get -y --no-install-recommends install \
    ros-${ROS_DISTRO}-xacro \
    ros-${ROS_DISTRO}-ros-gzgarden \
    ros-${ROS_DISTRO}-image-transport \
    python3-sdformat13 gz-garden \
    python3-colcon-common-extensions && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

## Setup Workspace
RUN mkdir -p "${BOAT_WS}/src"
WORKDIR "${BOAT_WS}/src"
RUN echo "source ${BOAT_WS}/install/setup.bash" >> ${HOME}/.bashrc && \
    echo "cd ${BOAT_WS}" >> ${HOME}/.bashrc

## Download ZED ROS2 Wrapper & VRX Simulation
WORKDIR ${BOAT_WS}/src
### QUESTION is --depth 1 fine? It clones much faster but idk about its other implications
RUN git clone --progress --verbose --recursive --depth 1 https://github.com/stereolabs/zed-ros2-wrapper.git && \
    git clone --progress --verbose --recursive --depth 1 https://github.com/osrf/vrx.git

## Install ALL Colcon packages
WORKDIR ${BOAT_WS}
RUN source /opt/ros/${ROS_DISTRO}/setup.bash && \
    apt-get update -y && \
    rosdep init && rosdep update && \
    rosdep install --from-paths src --ignore-src --rosdistro ${ROS_DISTRO} -y && \
    colcon build --parallel-workers $(nproc) --merge-install \
    --event-handlers console_direct+ --base-paths src \
    --cmake-args '-DCMAKE_BUILD_TYPE=Release' \
    '-DCMAKE_LIBRARY_PATH=/usr/local/cuda/lib64/stubs' \
    '-DCMAKE_CXX_FLAGS="-Wl,--allow-shlib-undefined"' && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy Entrypoint Script
WORKDIR ${HOME}
COPY ./Docker/entrypoint.sh ${HOME}
RUN chmod +x ${HOME}/entrypoint.sh
ENTRYPOINT  ["/root/entrypoint.sh"] 
