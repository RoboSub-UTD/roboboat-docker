# RoboBoat Docker 2026

Docker images for the UTD RoboBoat 2026 competition cycle. Two images live here:

| Service / image | What it is | Needs an NVIDIA GPU? |
|---|---|---|
| `development` (`Docker/Dockerfile`) | ROS 2 Humble dev environment with the `galaxsea` and `ROS-TCP-Endpoint` sources in `/root/roboboat_ws/src`, plus `rqt`/`rviz2`. This is where you write and run code. | **No** |
| `zed-sim` (`Docker/Dockerfile.zed`) | ZED SDK + `zed-ros2-wrapper` running against the virtual ZED camera in the Unity simulator. | **Yes** |

> [!IMPORTANT]
> **The `zed-sim` image requires an NVIDIA GPU** (plus the NVIDIA driver and the
> [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)
> on the host). The ZED SDK is CUDA-only; there is no CPU fallback, and it will not work inside a VM
> or on a Mac. **A workaround that does not use the ZED SDK is being worked on for laptops without a
> GPU** — until then, the `development` image works everywhere and you just won't have the
> `/zed/...` topics locally.

## Requirements

- Docker with the Compose v2 plugin. Commands below use `docker compose` (with a space); the old
  `docker-compose` binary is not supported.
- ~15 GB of free disk for the `development` image, ~25 GB more if you build `zed-sim`.
- For `zed-sim` only: an NVIDIA GPU, the proprietary driver, and the NVIDIA Container Toolkit.

## Get the repository

```bash
git clone https://github.com/RoboSub-UTD/roboboat-docker.git
cd roboboat-docker
```

Then follow the section for your operating system.

## Ubuntu

Tested on Ubuntu 22.04 / 24.04 with Docker Engine installed from Docker's own apt repository.

1. Install Docker Engine + Compose plugin: <https://docs.docker.com/engine/install/ubuntu/>, and
   add yourself to the `docker` group (`sudo usermod -aG docker $USER`, then log out and back in).
2. Pull the prebuilt image (or build it, see [Building](#building-the-images)):
   ```bash
   docker compose pull development
   ```
3. Start the container in the background and attach a shell to it:
   ```bash
   docker compose up -d development
   docker compose attach development
   ```
4. Inside the container, check that ROS 2 is healthy:
   ```bash
   ros2 doctor
   ```
5. Graphical tools (`rqt_graph`, `rviz2`) open on your desktop through the X11 socket the compose
   file mounts. If a window does not appear, run `xhost +local:docker` in a terminal **on the host**
   and try again.

**If you have an NVIDIA GPU** and want the simulated ZED camera, also install the NVIDIA Container
Toolkit and see [ZED camera in the Unity simulator](#zed-camera-in-the-unity-simulator-zed-sim).

## Windows (Ubuntu VM)

Run Ubuntu in a virtual machine (VirtualBox, VMware, or Hyper-V) and do everything inside the VM.
Docker Desktop for Windows / WSL2 is not a supported path for this repo because of the host
networking and `/dev` access the containers need.

1. Create an Ubuntu 22.04 or 24.04 VM. Give it as much RAM/CPU as you can spare and at least
   60 GB of disk — the images are large.
2. Inside the VM, follow the [Ubuntu](#ubuntu) steps exactly as written.
3. Graphical tools open inside the VM's desktop; if they don't, run `xhost +local:docker` in a
   terminal inside the VM.

> [!NOTE]
> A VM does not get access to the host's NVIDIA GPU, so **`zed-sim` cannot run in a VM** even if
> the Windows machine has an NVIDIA card. Use the `development` image only, and wait for the
> no-SDK workaround for the camera.

## macOS (untested)

> [!CAUTION]
> Nobody on the team has verified these steps on a Mac yet. If you get it working (or hit a wall),
> please update this section.

Macs have no NVIDIA GPU, so only the `development` image applies. The image is built for
`linux/amd64`; on Apple Silicon Docker Desktop runs it under emulation, which works but is slow.

1. Install [Docker Desktop for Mac](https://docs.docker.com/desktop/setup/install/mac-install/).
   On Apple Silicon, open *Settings → General* and enable **Use Rosetta for x86_64/amd64 emulation
   on Apple Silicon** — it is much faster than the default QEMU emulation. No extra `binfmt` setup
   is needed; Docker Desktop handles `linux/amd64` images itself.
2. Install XQuartz for graphical tools: `brew install --cask xquartz`, then log out and back in
   (XQuartz needs a fresh session to become your X server). Open XQuartz, go to
   *Settings → Security*, tick **Allow connections from network clients**, and restart XQuartz.
3. In a terminal, allow the container to talk to XQuartz and point `DISPLAY` at it. Docker Desktop
   runs containers in a Linux VM, so `DISPLAY` must go over the network to the Mac rather than
   through the `/tmp/.X11-unix` socket:
   ```bash
   xhost +localhost
   export DISPLAY=host.docker.internal:0
   ```
   Do this in the same terminal you run `docker compose` from, every session (or put the `export`
   in your shell profile).
4. Pull, start and attach:
   ```bash
   docker compose pull development
   docker compose up -d development
   docker compose attach development
   ros2 doctor
   ```

Known caveats: the compose file mounts `/dev`, uses `network_mode: host` and `privileged` — these
apply to Docker Desktop's Linux VM, not to macOS itself, so USB devices plugged into the Mac are not
visible in the container and ROS 2 discovery won't see nodes running natively on the Mac.

## Everyday use

```bash
docker compose up -d development     # start (or restart) the container in the background
docker compose attach development    # open a shell in it (Ctrl-P Ctrl-Q detaches without stopping)
```

### Opening more terminals

`docker compose attach` connects to the container's *one* main shell, so a second `attach` just
mirrors the first. To get an extra, independent terminal in the same running container (e.g. one for
`ros2 launch`, another for `ros2 topic echo`), open a new terminal on the host and run:

```bash
docker exec -it roboboat-docker-development-1 /bin/bash
```

You'll land in the workspace with ROS 2 already sourced:

```
root@hostname:~/roboboat_ws#
```

Repeat in as many terminals as you need; `exit` closes just that shell and leaves the container
running. (`roboboat-docker-development-1` is the container name compose generates from the folder
name and service; if you cloned into a different folder, check `docker ps` for the actual name.)

The container is also a good target for VS Code's *Dev Containers: Attach to Running Container*.

### The workspace

`/root/roboboat_ws/src` in the image holds a fresh clone of:

- `galaxsea` — <https://github.com/RoboSub-UTD/galaxsea> (`main`)
- `ROS-TCP-Endpoint` — <https://github.com/Unity-Technologies/ROS-TCP-Endpoint> (`main-ros2`),
  the ROS side of the Unity ↔ ROS bridge

The image ships the sources only; build them once inside the container:

```bash
cd /root/roboboat_ws
rosdep update && rosdep install --from-paths src --ignore-src -r -y
colcon build --symlink-install
source install/setup.bash            # new shells pick this up automatically
```

Anything you change inside the container lives only in that container. `docker compose up` after
a rebuild, or `docker compose down`, throws it away — push your work to git.

### Building the images

The `development` image is built and pushed to Docker Hub by CI whenever `Docker/Dockerfile`
changes on `main`, so `docker compose pull` is usually enough. To build locally:

```bash
docker compose build development     # ~10 min
docker compose build zed-sim         # ~15 min, NVIDIA GPU machines only
```

## ZED camera in the Unity simulator (`zed-sim`)

> [!IMPORTANT]
> Requires an NVIDIA GPU, the NVIDIA driver and the NVIDIA Container Toolkit on a bare-metal Linux
> host. It will not start on a machine without them (`docker compose up zed-sim` fails with an
> `nvidia` runtime error). A ZED-SDK-free workaround for GPU-less laptops is in progress.

The Unity simulator (`crane_sim`) carries a virtual ZED 2 that streams into the real ZED SDK in
*simulation mode*. The `zed-sim` service runs `zed-ros2-wrapper` against that stream, so the usual
`/zed/zed_node/...` topics (rectified images, SDK stereo depth, point cloud, IMU) appear exactly as
on the boat. It is a separate image (`Docker/Dockerfile.zed`, ZED SDK 5.4.1 + wrapper v5.4.1 on
ROS 2 Humble); the `development` image does not contain any ZED software.

```bash
docker compose build zed-sim          # once (~15 min, downloads the stereolabs/zed base image)
# start Unity, press Play (console: "ZED streamer ready ... port 30000"), then:
docker compose up zed-sim
```

## Troubleshooting

- **`docker compose: 'compose' is not a docker command`** — you have the old standalone
  `docker-compose`. Install the Compose v2 plugin (`docker-compose-plugin` on Ubuntu).
- **`permission denied while trying to connect to the Docker daemon socket`** — add yourself to the
  `docker` group and log out/in.
- **No window appears for `rqt_graph` / `rviz2`** — run `xhost +local:docker` on the host (or in the
  VM), then retry. On macOS make sure XQuartz is running and `DISPLAY` points at it.
- **`could not select device driver "nvidia"`** when starting `zed-sim` — the NVIDIA Container
  Toolkit isn't installed or `nvidia-ctk runtime configure --runtime=docker` hasn't been run, or the
  machine simply has no NVIDIA GPU (see the note at the top).
- **Root-owned files appear in `.config/`** — tools in the container write their state through the
  `/root/.config` bind mount. They're gitignored; `sudo rm -rf .config/<dir>` if they bother you.
