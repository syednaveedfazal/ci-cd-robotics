# Robot Provisioning Pipeline

A complete CI/CD pipeline for provisioning and deploying ROS2 software to a fleet of inspection robots. Covers the full workflow from code commit to production rollout with automatic rollback.

## Pipeline Flow

```
Code Push → Build & Test → Docker Image → Staging (canary) → Production (batched) → Rollback on failure
```

## Architecture

| Component | Purpose |
|-----------|---------|
| **ROS2 package** (`robot_health`) | Health publisher + monitor nodes with unit tests |
| **Docker** | Multi-stage build; tests run at build time |
| **GitHub Actions** | CI/CD: build → test → push image → deploy |
| **Ansible** | Robot provisioning, software deployment, rollback |
| **Docker Compose** | Local fleet simulation (3 robots + fleet monitor) |

## Quick Start

```bash
# Build the robot image
./docker/build.sh latest

# Start a 3-robot fleet locally
./fleet.sh start
./fleet.sh status
./fleet.sh logs robot-1
./fleet.sh health
./fleet.sh stop
```

## Demo (no real robots needed)

```bash
# Validate playbook syntax
./demo.sh syntax

# Show fleet inventory and batch groupings
./demo.sh inventory

# Dry-run: show what a deployment would do
./demo.sh dry-run

# Live run: Ansible deploys across all simulated robots
./demo.sh deploy
```

## Deployment (real robots)

```bash
# Initial provisioning
ansible-playbook -i ansible/inventory/staging \
    ansible/playbooks/provision-robot.yml \
    --limit staging-robot-1

# Deploy a software update
ansible-playbook -i ansible/inventory/staging \
    ansible/playbooks/deploy-robot.yml \
    --extra-vars "image_tag=v1.2.0"

# Gradual production rollout - canary first
ansible-playbook -i ansible/inventory/production \
    ansible/playbooks/deploy-robot.yml \
    --limit batch_1 --extra-vars "image_tag=v1.2.0"
```

## Project Structure

```
robot-provisioning-pipeline/
├── ros2_ws/src/robot_health/     # ROS2 health monitoring package
│   ├── robot_health/
│   │   ├── health_publisher.py   # Publishes battery, sensors, mission state
│   │   └── health_monitor.py     # Watches for threshold violations
│   └── test/test_health_nodes.py
├── docker/
│   ├── Dockerfile                # Multi-stage build
│   └── build.sh
├── .github/workflows/
│   └── robot-provisioning.yml   # Full CI/CD pipeline
├── ansible/
│   ├── inventory/staging         # Staging fleet
│   ├── inventory/production      # Production fleet (batched by site)
│   └── playbooks/
│       ├── provision-robot.yml   # First-time robot setup
│       └── deploy-robot.yml      # Rolling software update + rollback
├── docker-compose.yml            # 3-robot fleet simulation
├── fleet.sh                      # Fleet management commands
└── demo.sh                       # Demo script (local Ansible)
```

## Technologies

- **ROS2 Humble** — robot nodes, pub/sub health data
- **Docker** — containerized runtime, multi-stage builds
- **GitHub Actions** — automated CI/CD
- **Ansible** — configuration management, idempotent deployments
- **pytest** — unit tests gating deployment
