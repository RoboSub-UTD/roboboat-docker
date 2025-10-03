# UTD RoboBoat Codebase

```bash
.
├── .config/
├── Docker/
│   ├── Dockerfile
│   └── entrypoint.sh
├── docker-compose.yml
├── flake.nix
├── flake.lock
├── README.md
└── src/
    └── roboboat2025/
```

## Development with MacOS
The images _should_ work on MacOS, seeing as the docker images also build for `linux/arm64`. The only issue that _could_ happen is through display forwarding (i.e. graphical applications not showing on MacOS), in which `xquartz` would be required:

>[!CAUTION]
> None of these instructions were tested _at all_ by me! I just happened to find them from GitHub Gists ([Gist A](https://gist.github.com/cschiewek/246a244ba23da8b9f0e7b11a68bf3285) and [Gist B](https://gist.github.com/sorny/969fe55d85c9b0035b0109a31cbcb088))

1. Make sure you have [Homebrew](https://brew.sh/) (a package manager for MacOS) installed.
2. Install `xquartz` with `brew install --cask xquartz`. 
3. Open the application and on its `preferences -> security` tab, check the box that says "**Allow connections from network clients**".
4. Relaunch the application
5. On you terminal, enter `xhost +host.docker.internal` to allow connections from Docker 
6. ...you should be good to go!


## Running Development Container in a Detached State

You would normally do this whenever you are starting the container in order to attach to it in a code editor such as VSCode:

```bash
docker compose up -d development
docker compose attach development # optional: attach to it later, or with VSCode
```

## Simulation

You can launch `docker compose up sim` to launch the simulator. If it doesn't appear,
just make sure to run `xhost +`, and then run `xhost -` after the simulation is closed

Make sure to build the `roboboat2025` ROS2 package as well in order to control that boat:

```bash shell
docker compose run development
# Inside the docker container
colcon build --merge-install
source ~/.bashrc
ros2 run roboboat2025 boat_controller
```
