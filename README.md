# RoboBoat 2025 Codebase

```text
.
├── .config/
│   ├── nvim/
│   ├── setup-development-enviornment.sh
│   └── starship.toml
├── Docker/
│   ├── docker-build.sh
│   ├── Dockerfile
│   ├── docker-run.sh
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
