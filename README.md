# RoboBoat Docker 2026
This is the repository that contains the dockerimage used for the 2026 roboboat competition. 

Below are instructions for how to get the image built on your computer and get ready to develop for the competition cycle!


## Get started 
1. Clone this repository

   ```git clone https://github.com/RoboSub-UTD/roboboat-docker.git```

   Since this is a private repository, github will require you to log in on the command line. Enter your username when prompted, but do not enter your password.

   Instead, you need a developer token. Go to Settings -> Developer Settings -> Personal Access Tokens -> Tokens (Classic) -> Generate New Token -> Generate New Token (Classic)

   Set a name and expiration date, check at least the first check box, then generate the token and paste that into the password field.
2. Change directory into the repository i.e. ```cd roboboat-docker```
3. Run ```docker compose pull```

   Note that you must run ```docker compose``` not ```docker-compose```. If ```docker compose``` is not working, you must install it.
4. From here, the steps vary based on development environment

## Development with Ubuntu (not a VM)
1. Run ```docker compose up -d development```
2. Run ```docker compose attach development```
3. You should now be in the container. Run ```ros2 launch vrx_gz competition.launch.py``` to make sure the simulator launches and you get a graphical window. If you don't, try running ```xhost +``` in a seperate terminal then try again.

## Development with an Ubuntu VM
1. Run ```docker compose up -d development```
2. Run ```docker compose attach development```
3. You should now be in the container. Run ```ros2 launch vrx_gz competition.launch.py``` to make sure the simulator launches and you get a graphical window. If you don't, try running ```xhost +``` in a seperate terminal inside the VM then try again.

## Development with MacOS
1. Run ```docker run --privileged --rm tonistiigi/binfmt --install all```. This installs QEMU witch allows ARM devices to emulate AMD docker conatiners.
2. Run ```docker compose up -d development```
3. Run ```docker compose attach development```
4. You should now be in the container. Run ```ros2 launch vrx_gz competition.launch.py``` to make sure the simulator launches and you get a graphical window.
5. In the likely event you don't see a window pull up, follow the below steps.

>[!CAUTION]
> None of these instructions were tested _at all_ by me! I just happened to find them from GitHub Gists ([Gist A](https://gist.github.com/cschiewek/246a244ba23da8b9f0e7b11a68bf3285) and [Gist B](https://gist.github.com/sorny/969fe55d85c9b0035b0109a31cbcb088))

1. Make sure you have [Homebrew](https://brew.sh/) (a package manager for MacOS) installed.
2. Install `xquartz` with `brew install --cask xquartz`. 
3. Open the application and on its `preferences -> security` tab, check the box that says "**Allow connections from network clients**".
4. Relaunch the application
5. On you terminal, enter `xhost +host.docker.internal` to allow connections from Docker 
6. ...you should be good to go!


# After installation
## Running Development Container in a Detached State

You would normally do this whenever you are starting the container in order to attach to it in a code editor such as VSCode:

```bash
docker compose up -d development
docker compose attach development # optional: attach to it later, or with VSCode
```

## Simulation

You can launch `docker compose up sim` to launch the simulator rather than booting into the development environment and running `ros2 launch vrx_gz competition.launch.py`. 

## ZED camera in the Unity simulator (`zed-sim`)

The Unity simulator (`crane_sim`) carries a virtual ZED 2 that streams into the real ZED SDK in
*simulation mode*. The `zed-sim` service runs `zed-ros2-wrapper` against that stream, so the usual
`/zed/zed_node/...` topics (rectified images, SDK stereo depth, point cloud, IMU) appear exactly as
on the boat. It is a separate image (`Docker/Dockerfile.zed`, ZED SDK 5.4.1 + wrapper v5.4.1 on
ROS 2 Humble); the `development` image is unchanged.

```bash
docker compose build zed-sim          # once (~15 min, downloads the stereolabs/zed base image)
# start Unity, press Play (console: "ZED streamer ready ... port 30000"), then:
docker compose up zed-sim
```

Parameter overrides for the simulated camera live in `Docker/zed/zed_sim_override.yaml`. The first
start optimizes the NEURAL depth model for the GPU (several minutes, the log sits at "90.1%" for the
final step); the result is cached in the `zed_ai_models` volume.

Notes (verified 2026-09-17 on an RTX 3050 laptop):
- The SDK identifies the virtual camera as a **ZED 2** (serial 20976320), so `camera_model:=zed2`.
- Rectified images, `camera_info` (fx 529.8 @ 1280x720), depth and point cloud publish at the rate the
  GPU can compute NEURAL_LIGHT depth (~10 Hz on a 3050 shared with Unity).
- `sensors.sensors_image_sync: true` is required: a streamed camera has no live IMU FIFO, and the
  default `TIME_REFERENCE::CURRENT` polling floods `getSensorsData error: INVALID FUNCTION PARAMETERS`.
  Even so, the wrapper's synced IMU path (`/zed/zed_node/imu/data`) published only sporadically in
  testing - open issue; the Unity-side `Imu` sensor (`/imu/raw`) remains available meanwhile.
- `Grab status degraded: CORRUPTED FRAME` / `Duplicate frame detected` warnings appear at a few per
  second on this GPU (decoder under load); images still publish. `enable_image_validity_check: 0` is
  set so calm scenes are not additionally flagged.
- `use_sim_time:=true` needs Unity in Play mode (it publishes `/clock`); the wrapper waits otherwise.
