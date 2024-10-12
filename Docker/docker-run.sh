CONTAINER_NAME='RoboBoat'
IMAGE_NAME='utd_roboboat_2025'
IMAGE_TAG='coding'

# Local Directories
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SRC_DIR=$( cd -- "$( dirname -- "${SCRIPT_DIR}" )" &> /dev/null && pwd )/src

# Docker directories
BOAT_DIR='/root/roboboat_ws'


CONTAINER_ID=`docker ps -aqf "name=^/${CONTAINER_NAME}$"`

if [ -z "${CONTAINER_ID}" ]; then
    docker run \
        --tty \
        --detach \
        --name ${CONTAINER_NAME} \
        --device "/dev/dri:/dev/dri" \
        --privileged \
        --gpus all \
        --shm-size 16G \
        --network host \
        --env "DISPLAY=$DISPLAY" \
        --volume "/tmp/.X11-unix:/tmp/.X11-unix" \
        --volume "${SRC_DIR}:${BOAT_DIR}/src/" \
        ${IMAGE_NAME}:${IMAGE_TAG} 
        # --device "/sys/devices/pci0000:00/0000:00:0d.0/usb2/2-1"\
else
    xhost +local:`docker inspect --format='{{ .Config.Hostname }}' ${CONTAINER_ID}`

    if [ -z `docker ps -qf "name=^/${CONTAINER_NAME}$"` ]; then
        echo "${CONTAINER_NAME} container not running. Starting container..."
        docker start ${CONTAINER_ID}
    else
        echo "Attaching to running ${CONTAINER_NAME} container..."
    fi
    docker exec -it ${CONTAINER_ID} bash

    xhost -local:`docker inspect --format='{{ .Config.Hostname }}' ${CONTAINER_ID}`
fi
