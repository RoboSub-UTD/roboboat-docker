###############
# BUILD IMAGE #
###############
FROM nvidia/cuda:12.1.1-devel-ubuntu22.04 AS builder
SHELL ["/bin/bash", "-c"]

# Use Faster Mirrors
##  INFO: Found using apt-select --country US -t 10 
ARG MIRROR='http://dal.mirrors.clouvider.net' 
RUN sed -r -i "s,http://(.*).ubuntu.com,${MIRROR}," /etc/apt/sources.list

# Setup Environment

## ROS2
ARG ROS_DISTRO='humble'
ARG DEBIAN_FRONTEND='noninteractive'

ENV USER='root'
ENV HOME="/${USER}"
ENV BOAT_WS='/root/roboboat_ws'

## ZED SDK
ARG UBUNTU_MAJOR='22'
ARG CUDA_MAJOR='12'
ARG CUDA_MINOR='1'
ARG CUDA_PATCH='1'
ARG ZED_SDK_MAJOR='4'
ARG ZED_SDK_MINOR='2'
ARG ZED_SDK_PATCH='0'

ARG ZED_SDK_URL="https://stereolabs.sfo2.cdn.digitaloceanspaces.com/zedsdk/${ZED_SDK_MAJOR}.${ZED_SDK_MINOR}/ZED_SDK_Ubuntu${UBUNTU_MAJOR}_cuda${CUDA_MAJOR}.${CUDA_MINOR}_v${ZED_SDK_MAJOR}.${ZED_SDK_MINOR}.${ZED_SDK_PATCH}.zstd.run"

ENV NVIDIA_DRIVER_CAPABILITIES=${NVIDIA_DRIVER_CAPABILITIES:+$NVIDIA_DRIVER_CAPABILITIES,}compute,video,utility

# Install Dependencies
RUN apt-get update && apt-get -y --no-install-recommends install \
    cmake wget curl git zstd python3-dev python3-pip lsb-release \
    locales build-essential software-properties-common && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Setup ROS2 Repositories and Build Dependencies

## Add ROS2 Repository
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null

## Install necessary ROS2 packages
RUN locale-gen en_US en_US.UTF-8 && \
    update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 && \
    LANG=en_US.UTF-8 && \
    add-apt-repository -y universe && \
    apt-get update && apt-get -y --no-install-recommends install \
    python3-vcstool ros-dev-tools \
    python3-colcon-common-extensions \
    ros-${ROS_DISTRO}-ros-base && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install ZED SDK

## Verify the ZED SDK URL and then install
RUN if [ "$(curl -I "${ZED_SDK_URL}" -o /dev/null -s -w '%{http_code}\n' | head -n 1)" = "200" ]; then \
    echo "The URL points to something."; \
    else \
    echo "The URL does not point to a .run file or the file does not exist."; \
    exit 1; \
    fi && \
    echo "CUDA Version $CUDA_VERSION" > /usr/local/cuda/version.txt && \
    wget -q -O ZED_SDK_Linux_Ubuntu.run ${ZED_SDK_URL} && \
    chmod +x ZED_SDK_Linux_Ubuntu.run && \
    ./ZED_SDK_Linux_Ubuntu.run -- silent skip_tools skip_cuda && \
    ln -sf /lib/x86_64-linux-gnu/libusb-1.0.so.0 /usr/lib/x86_64-linux-gnu/libusb-1.0.so && \
    rm ZED_SDK_Linux_Ubuntu.run && \
    rm -rf /var/lib/apt/lists/* && \
    python3 /usr/local/zed/get_python_api.py

# Build Colcon Packages

## Setup Workspace
RUN mkdir -p "${BOAT_WS}/src"
WORKDIR "${BOAT_WS}/src"

## Download ZED ROS2 Wrapper
WORKDIR ${BOAT_WS}/src
RUN git clone --progress --verbose --recursive --depth 1 --branch humble-v4.1.4 https://github.com/stereolabs/zed-ros2-wrapper.git

## Install Colcon Packages
WORKDIR ${BOAT_WS}
RUN source /opt/ros/${ROS_DISTRO}/setup.bash && \
    apt-get update -y && \
    rosdep init && rosdep update && \
    rosdep install --from-paths src --ignore-src -r --rosdistro ${ROS_DISTRO} -y && \
    colcon build --parallel-workers $(nproc) --merge-install \
    --event-handlers console_direct+ --base-paths src \
    --cmake-args '-DCMAKE_BUILD_TYPE=Release' \
    '-DCMAKE_LIBRARY_PATH=/usr/local/cuda/lib64/stubs' \
    '-DCMAKE_CXX_FLAGS="-Wl,--allow-shlib-undefined"' && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

#####################
# BUILD IMAGE (VRX) #
#####################
FROM builder AS builder_vrx

## Add Gazebo Repository
RUN wget https://packages.osrfoundation.org/gazebo.gpg -O /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null

RUN add-apt-repository -y universe && \
    apt-get update && apt-get -y --no-install-recommends install \
    python3-sdformat13 gz-garden \
    ros-${ROS_DISTRO}-xacro \
    ros-${ROS_DISTRO}-ros-gzgarden \
    ros-${ROS_DISTRO}-image-transport && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR ${BOAT_WS}/src
RUN git clone --progress --verbose --recursive --depth 1 --branch 2.4.1 https://github.com/osrf/vrx.git && \
    cd ${BOAT_WS} && source /opt/ros/${ROS_DISTRO}/setup.bash && \
    colcon build --parallel-workers $(nproc) --base-paths src --merge-install && \
    apt-get clean && rm -rf /var/lib/apt/lists/*


##############
# BASE IMAGE #
##############

FROM nvidia/cuda:12.1.1-base-ubuntu22.04 AS base
SHELL ["/bin/bash", "-c"]

# Use Faster Mirrors
ARG MIRROR='http://dal.mirrors.clouvider.net' # INFO: Found using apt-select --country US -t 10 
RUN sed -r -i "s,http://(.*).ubuntu.com,${MIRROR}," /etc/apt/sources.list

# Setup Environment
ENV USER='root'
ENV HOME="/${USER}"

ENV BOAT_WS='/root/roboboat_ws'
RUN mkdir -p ${BOAT_WS}

## ROS2
ARG ROS_DISTRO='humble'
ARG DEBIAN_FRONTEND='noninteractive'
ENV RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

## ZED
ARG ZED_API_FILENAME='pyzed-4.2-cp310-cp310-linux_x86_64.whl'

# Copy Files
## Builder Files
COPY --from=builder ${BOAT_WS}/install ${BOAT_WS}/install
COPY --from=builder /usr/local/zed /usr/local/zed
COPY --from=builder /${ZED_API_FILENAME} /${ZED_API_FILENAME}

## .bashrc
COPY .config/.bashrc ${HOME}/.bashrc
COPY .config/.bash.d ${HOME}/.bash.d

# Install Developer Packges

RUN apt-get update && apt-get -y --no-install-recommends install \
    software-properties-common apt-utils wget curl locales \
    python3-minimal python-is-python3 python3-pip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Setup ROS2 Humble
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null && \
    locale-gen en_US en_US.UTF-8 && \
    update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 && \
    LANG=en_US.UTF-8 && \
    add-apt-repository -y universe && \
    apt-get update && apt-get -y --no-install-recommends install \
    python3-vcstool ros-dev-tools \
    python3-colcon-common-extensions \
    ros-${ROS_DISTRO}-ros-base \
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

# Install ZED Python API
RUN python -m pip install --ignore-installed /${ZED_API_FILENAME} && \
    rm /${ZED_API_FILENAME}

# Set Entrypoint Script
COPY ./Docker/entrypoint.sh ${HOME}
RUN chmod +x ${HOME}/entrypoint.sh
ENTRYPOINT  ["/root/entrypoint.sh"] 

#####################
# DEVELOPMENT IMAGE #
#####################
FROM base AS development

# Copy files from the builder
COPY --from=builder_vrx ${BOAT_WS}/install ${BOAT_WS}/install
COPY --from=builder_vrx /usr/local/zed /usr/local/zed

# Install Dependencies
RUN apt-get update && apt-get -y --no-install-recommends install \
    net-tools iputils-ping \ 
    libturbojpeg && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Gazebo Garden

## Add Gazebo Repository
RUN wget https://packages.osrfoundation.org/gazebo.gpg -O /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null
RUN apt-get update && apt-get -y --no-install-recommends install \
    python3-sdformat13 gz-garden \
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
