# RoboBoat 2025 Codebase

```bash
.
├── .config/
│   ├── nvim/
│   ├── setup-development-enviornment.sh
│   └── starship.toml
├── Docker/
│   ├── docker-build.sh # [DEPRECATED] Plan to remove
│   ├── Dockerfile
│   ├── docker-run.sh   # [DEPRECATED] Plan to remove
│   └── entrypoint.sh
├── docker-compose.yml
├── README.md
└── src/
    └── roboboat2025/
```

These files are the infrastructure for the codebase:

-   `Dockerfile`
-   `entrypoint.sh`
-   `docker-compose.yml`

## Running Development Container in a Detached State

You would normally do this whenever you are starting the container in order to attach to it in a code editor such as VSCode:

```bash
docker compose up -d development
docker compose attach development # optional: attach to it later
```

## Setting up Development Enviornment with Neovim

When running the development service, run `./.config/setup-development-enviornment.sh` and then `source ~/.bashrc` once it finishes

## Simulation

You can launch `docker compose up sim` to launch the simulator. If it doesn't appear,
just make sure to run `xhost +`, and then run `xhost -` after the simulation is closed

Make sure to build the roboboat2025 ros2 package as well in order to control that boat:

```bash shell
docker compose run development
# Inside the docker container
colcon build --merge-install
source ~/.bashrc
ros2 run roboboat2025 boat_controller
```
