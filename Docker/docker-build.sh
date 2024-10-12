IMAGE_NAME="roboboat"
IMAGE_TAG="devel"
DOCKERFILE_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
docker build ${DOCKERFILE_DIR} -t "${IMAGE_NAME}:${IMAGE_TAG}" -f "${DOCKERFILE_DIR}/Dockerfile"
