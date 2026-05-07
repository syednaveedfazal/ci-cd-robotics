#!/bin/bash
# Robot Provisioning Pipeline - Demo Script
#
# Demonstrates the full pipeline without real robots.
# Uses Docker Compose as the "fleet" and local Ansible connection.

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

banner() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  $1${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════╝${NC}"
}

step() { echo -e "${YELLOW}▶ STEP $1:${NC} $2"; }
ok()   { echo -e "${GREEN}✓${NC} $1"; }
info() { echo -e "  $1"; }

# ============================================================
# DEMO 1: Ansible syntax validation (works with no robots)
# ============================================================
demo_syntax_check() {
    banner "DEMO 1: Validate Ansible Playbook Syntax"
    step 1 "Check deploy playbook syntax"
    ansible-playbook ansible/playbooks/deploy-robot-simple.yml --syntax-check
    ok "Syntax valid"

    step 2 "Check provision playbook syntax"
    ansible-playbook ansible/playbooks/provision-robot.yml --syntax-check
    ok "Syntax valid"
}

# ============================================================
# DEMO 2: Ansible dry-run against local inventory (no SSH)
# ============================================================
demo_dry_run() {
    banner "DEMO 2: Dry-Run Deployment (No Real Robots Needed)"
    info "Uses ansible_connection=local — runs on this machine, simulating robot tasks"
    echo ""

    step 1 "Dry-run deploy to staging (--check shows WHAT would happen)"
    ansible-playbook -i ansible/inventory/local \
        ansible/playbooks/deploy-robot-simple.yml \
        --limit staging_robots \
        --extra-vars "image_tag=v1.2.0" \
        --check
    ok "Staging dry-run complete"

    echo ""
    step 2 "Dry-run canary deploy — batch_1 only (10% of fleet)"
    ansible-playbook -i ansible/inventory/local \
        ansible/playbooks/deploy-robot-simple.yml \
        --limit batch_1 \
        --extra-vars "image_tag=v1.2.0" \
        --check
    ok "Batch 1 canary dry-run complete"
}

# ============================================================
# DEMO 3: Actual Ansible run on local inventory
# ============================================================
demo_local_run() {
    banner "DEMO 3: Live Ansible Run (Local Connection)"
    info "Ansible actually executes tasks — just targets localhost instead of robots"
    echo ""

    step 1 "Deploy to staging robots (local simulation)"
    ansible-playbook -i ansible/inventory/local \
        ansible/playbooks/deploy-robot-simple.yml \
        --limit staging_robots \
        --extra-vars "image_tag=v1.2.0"
    ok "Staging deployment complete"

    echo ""
    step 2 "Gradual rollout: batch_1 (canary — 1 robot)"
    ansible-playbook -i ansible/inventory/local \
        ansible/playbooks/deploy-robot-simple.yml \
        --limit batch_1 \
        --extra-vars "image_tag=v1.2.0"
    ok "Batch 1 deployed"

    echo ""
    step 3 "Gradual rollout: batch_2 (2 more robots)"
    ansible-playbook -i ansible/inventory/local \
        ansible/playbooks/deploy-robot-simple.yml \
        --limit batch_2 \
        --extra-vars "image_tag=v1.2.0"
    ok "Batch 2 deployed"

    echo ""
    step 4 "Gradual rollout: batch_3 (final robots)"
    ansible-playbook -i ansible/inventory/local \
        ansible/playbooks/deploy-robot-simple.yml \
        --limit batch_3 \
        --extra-vars "image_tag=v1.2.0"
    ok "Full fleet deployed!"
}

# ============================================================
# DEMO 4: Ansible inventory inspection
# ============================================================
demo_inventory() {
    banner "DEMO 4: Fleet Inventory Overview"

    step 1 "List all robots in production inventory"
    ansible -i ansible/inventory/local all --list-hosts

    echo ""
    step 2 "Show batch groupings (gradual rollout strategy)"
    echo "  batch_1 (canary - 20%):"
    ansible -i ansible/inventory/local batch_1 --list-hosts
    echo "  batch_2 (next 40%):"
    ansible -i ansible/inventory/local batch_2 --list-hosts
    echo "  batch_3 (final 40%):"
    ansible -i ansible/inventory/local batch_3 --list-hosts

    echo ""
    step 3 "Show robots by site"
    echo "  site_alpha (Power Plant, Germany):"
    ansible -i ansible/inventory/local site_alpha --list-hosts
    echo "  site_beta (Wind Farm, Denmark):"
    ansible -i ansible/inventory/local site_beta --list-hosts
    echo "  site_gamma (Oil Rig, Norway):"
    ansible -i ansible/inventory/local site_gamma --list-hosts
}

# ============================================================
# DEMO 5: Docker Compose fleet simulation
# ============================================================
demo_fleet() {
    banner "DEMO 5: Docker Compose Fleet Simulation"
    info "Simulates 3 robots + fleet monitor running simultaneously"
    echo ""

    if ! docker images robot-fleet:latest | grep -q robot-fleet; then
        step 1 "Build robot Docker image first"
        ./docker/build.sh latest
    else
        ok "Docker image robot-fleet:latest already built"
    fi

    echo ""
    step 2 "Start 3-robot fleet + fleet monitor"
    ./fleet.sh start

    echo ""
    step 3 "Fleet status"
    sleep 3
    ./fleet.sh status

    echo ""
    step 4 "Health check (all robots running?)"
    ./fleet.sh health

    echo ""
    info "Run './fleet.sh logs robot-1' to see live ROS2 health data"
    info "Run './fleet.sh stop' when done"
}

# ============================================================
# DEMO 6: Ping all simulated robots
# ============================================================
demo_ping() {
    banner "DEMO 6: Connectivity Check (Ansible Ping)"
    info "In production this verifies SSH to each robot. Locally it tests Python/connection."
    echo ""
    ansible -i ansible/inventory/local all -m ping
}

# ============================================================
# Main menu
# ============================================================
usage() {
    echo ""
    echo -e "${GREEN}Robot Provisioning Pipeline - Demo Script${NC}"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  syntax      Validate Ansible playbook syntax (no connection needed)"
    echo "  dry-run     Show what deployment WOULD do (--check mode)"
    echo "  deploy      Run full gradual rollout via local Ansible connection"
    echo "  inventory   Show fleet structure and batch groupings"
    echo "  fleet       Start Docker Compose robot fleet simulation"
    echo "  ping        Ansible ping all simulated robots"
    echo "  all         Run syntax + inventory + dry-run (safe full demo)"
    echo ""
    echo "Examples:"
    echo "  $0 syntax          # Great starting point — no dependencies"
    echo "  $0 dry-run         # Shows deployment logic without risk"
    echo "  $0 deploy          # Runs the actual Ansible tasks locally"
    echo "  $0 inventory       # Visualize the fleet structure"
    echo "  $0 fleet           # Start Docker fleet (needs built image)"
    echo ""
}

case "$1" in
    syntax)    demo_syntax_check ;;
    dry-run)   demo_dry_run ;;
    deploy)    demo_local_run ;;
    inventory) demo_inventory ;;
    fleet)     demo_fleet ;;
    ping)      demo_ping ;;
    all)
        demo_syntax_check
        echo ""
        demo_inventory
        echo ""
        demo_dry_run
        ;;
    *)
        usage
        ;;
esac
