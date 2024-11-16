# RoboBoat 2025 Codebase

```bash
.
├── .config/
│   ├── .bash.d
│   ├── .bashrc
│   ├── setup-development-enviornment.sh
│   └── starship.toml
├── Docker/
│   ├── Dockerfile
│   └── entrypoint.sh
├── docker-compose.yml
├── README.md
└── src/
    └── roboboat2025/
```

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
