# Project Structure

```
robot-provisioning-pipeline/
│
├── README.md
├── USAGE_GUIDE.md
├── .gitignore
│
├── docker-compose.yml            # 3-robot fleet simulation
├── fleet.sh                      # Fleet management commands
├── demo.sh                       # Ansible demo script (local, no real robots)
│
├── docker/
│   ├── Dockerfile                # Multi-stage ROS2 image
│   └── build.sh                  # Build + validation script
│
├── ros2_ws/
│   └── src/
│       └── robot_health/
│           ├── package.xml
│           ├── setup.py
│           ├── robot_health/
│           │   ├── __init__.py
│           │   ├── health_publisher.py   # Publishes battery, sensors, mission state
│           │   └── health_monitor.py     # Monitors for threshold violations
│           └── test/
│               └── test_health_nodes.py
│
├── .github/
│   └── workflows/
│       └── robot-provisioning.yml        # CI/CD pipeline
│
└── ansible/
    ├── inventory/
    │   ├── staging                        # Staging robot IPs + vars
    │   └── production                     # Production fleet, grouped by site and batch
    └── playbooks/
        ├── provision-robot.yml            # First-time robot setup
        ├── deploy-robot.yml               # Production deployment + rollback
        └── deploy-robot-simple.yml        # Simplified version for local demo
```

---

## Technology Stack

| Layer | Tool |
|-------|------|
| Robot software | ROS2 Humble (Python nodes) |
| Containerisation | Docker (multi-stage builds) |
| CI/CD | GitHub Actions |
| Configuration management | Ansible |
| Local fleet simulation | Docker Compose |
| Testing | pytest via colcon |
| Image registry | GitHub Container Registry (GHCR) |
| Vulnerability scanning | Trivy |

---

## Key Design Decisions

**Multi-stage Docker build** — build tools stay out of the runtime image, keeping it lean. Tests run inside the builder stage so a failing test blocks the image from being created.

**Batched Ansible inventory** — production robots are grouped into `batch_1`, `batch_2`, `batch_3` so rollouts are done progressively with a monitoring window between each batch.

**Local inventory** — `ansible/inventory/local` uses `ansible_connection=local` to let you run and test playbooks without SSH access to real robots.

**Rescue block in deploy playbook** — any task failure in the deploy sequence triggers the rescue block, which stops the bad containers and restarts from the last known-good image.
