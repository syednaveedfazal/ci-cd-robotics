# Usage Guide

## Prerequisites

- Ubuntu 22.04
- Docker & Docker Compose
- Ansible (`pip install ansible`)
- Git

---

## Local Fleet Simulation

### Build the image

```bash
./docker/build.sh latest
docker images robot-fleet:latest
```

### Start / stop the fleet

```bash
./fleet.sh start           # Start 3 robots + fleet monitor
./fleet.sh status          # Show container status
./fleet.sh logs robot-1    # Tail logs for a specific robot
./fleet.sh health          # Check all robots are running
./fleet.sh stop            # Tear down the fleet
```

### Connect to a running robot

```bash
./fleet.sh exec robot-1    # Opens a shell inside the container
ros2 node list
ros2 topic echo /robot_health
```

---

## Ansible Demo (no real robots)

The `ansible/inventory/local` inventory uses `ansible_connection=local` so all tasks run on your machine — useful for demos and offline development.

```bash
# Validate playbook syntax
./demo.sh syntax

# Show fleet structure and batch groups
./demo.sh inventory

# Dry-run: see what a deploy would do (--check mode)
./demo.sh dry-run

# Live run: Ansible executes tasks across all simulated robots
./demo.sh deploy

# All of the above in sequence
./demo.sh all
```

Or run Ansible directly:

```bash
ansible -i ansible/inventory/local all -m ping

ansible-playbook -i ansible/inventory/local \
    ansible/playbooks/deploy-robot-simple.yml \
    --limit batch_1 --extra-vars "image_tag=v1.2.0" --check

ansible-playbook -i ansible/inventory/local \
    ansible/playbooks/deploy-robot-simple.yml \
    --extra-vars "image_tag=v1.2.0"
```

---

## Real Robot Deployment

### First-time provisioning

```bash
ansible-playbook -i ansible/inventory/staging \
    ansible/playbooks/provision-robot.yml \
    --limit staging-robot-1
```

### Software update — gradual rollout

```bash
# Staging
ansible-playbook -i ansible/inventory/staging \
    ansible/playbooks/deploy-robot.yml \
    --extra-vars "image_tag=v1.2.0"

# Production batch 1 (canary)
ansible-playbook -i ansible/inventory/production \
    ansible/playbooks/deploy-robot.yml \
    --limit batch_1 --extra-vars "image_tag=v1.2.0"

# batch_2, then batch_3 after monitoring
ansible-playbook -i ansible/inventory/production \
    ansible/playbooks/deploy-robot.yml \
    --limit batch_2 --extra-vars "image_tag=v1.2.0"
```

### Dry-run (no changes applied)

```bash
ansible-playbook ansible/playbooks/deploy-robot.yml --syntax-check

ansible-playbook -i ansible/inventory/staging \
    ansible/playbooks/deploy-robot.yml \
    --check --diff
```

---

## CI/CD Pipeline

The GitHub Actions workflow (`.github/workflows/robot-provisioning.yml`) triggers on push to `main` or `develop`:

| Job | Condition | What it does |
|-----|-----------|-------------|
| `build-and-test` | always | Builds ROS2 workspace, runs pytest |
| `build-docker` | tests pass | Multi-stage Docker build, Trivy scan, push to GHCR |
| `deploy-staging` | push to `main` | Deploys to staging, health check |
| `deploy-production` | staging passes | Gradual rollout in 3 batches |
| `rollback` | any job fails | Reverts fleet to previous image |

---

## Debugging

### Docker fleet

```bash
docker ps
docker exec -it robot-1 bash
docker logs robot-1 --tail 50
```

### Ansible (real robots)

```bash
ansible -i ansible/inventory/production all -m shell -a "docker ps"

ansible -i ansible/inventory/production robot-alpha-001 \
    -m shell -a "docker logs robot-health-publisher --tail 100"

ansible -i ansible/inventory/production robot-alpha-001 \
    -m shell -a "docker exec robot-health-publisher ros2 node list"
```

### ROS2

```bash
source /opt/ros/humble/setup.bash
cd ros2_ws && colcon test && colcon test-result --verbose
```

---

## Updating Robot IPs

Edit `ansible/inventory/staging` or `ansible/inventory/production` and replace the placeholder IPs with your actual robot addresses.
The `ansible/inventory/local` inventory is for local demo use and is excluded from version control via `.gitignore`.
