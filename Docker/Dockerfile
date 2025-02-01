###############
# BUILD IMAGE #
###############
FROM ros:humble-ros-core AS builder
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

# Install some packages
RUN apt-get update && apt-get -y --no-install-recommends install \
    cmake wget curl git lsb-release \
    build-essential software-properties-common && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

## Setup Workspace
RUN mkdir -p "${BOAT_WS}/src"
WORKDIR "${BOAT_WS}/src"

#####################
# BUILD IMAGE (VRX) #
#####################
FROM builder AS builder_vrx

## Add Gazebo Repository
RUN wget https://packages.osrfoundation.org/gazebo.gpg -O /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null && \
    add-apt-repository -y universe && \
    apt-get update && apt-get -y --no-install-recommends install \
    python3-sdformat13 gz-garden \
    ros-${ROS_DISTRO}-xacro \
    ros-${ROS_DISTRO}-ros-gzgarden \
    python3-colcon-common-extensions \
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

FROM ros:humble-ros-core AS base
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
ARG DEBIAN_FRONTEND='noninteractive'
ENV RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

## .bashrc
COPY .config/.bashrc ${HOME}/.bashrc
COPY .config/.bash.d ${HOME}/.bash.d

# Install Developer Packges
RUN apt-get update && apt-get -y --no-install-recommends install \
    software-properties-common apt-utils wget curl \
    python3-minimal python-is-python3 python3-pip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Setup ROS2 Humble packages
RUN apt-get update && apt-get -y --no-install-recommends install \
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
ENTRYPOINT  ["/root/entrypoint.sh"] 

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
