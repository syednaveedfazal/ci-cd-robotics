#!/bin/bash
# Fleet Management Script
#
# Quick commands for managing the robot fleet during development and testing.
# In production, this would be integrated with Ansible or Kubernetes.

set -e

COMPOSE_FILE="docker-compose.yml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}=========================================${NC}"
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to start the fleet
start_fleet() {
    print_header "Starting Robot Fleet"
    docker compose -f "${COMPOSE_FILE}" up -d
    print_info "Fleet started in detached mode"
    print_info "Run './fleet.sh status' to check robot status"
}

# Function to stop the fleet
stop_fleet() {
    print_header "Stopping Robot Fleet"
    docker compose -f "${COMPOSE_FILE}" down
    print_info "Fleet stopped and containers removed"
}

# Function to show fleet status
show_status() {
    print_header "Robot Fleet Status"
    docker compose -f "${COMPOSE_FILE}" ps
}

# Function to show robot logs
show_logs() {
    ROBOT="${1:-all}"
    if [ "$ROBOT" == "all" ]; then
        print_header "All Robot Logs (last 50 lines)"
        docker compose -f "${COMPOSE_FILE}" logs --tail=50
    else
        print_header "Logs for ${ROBOT}"
        docker compose -f "${COMPOSE_FILE}" logs --tail=100 -f "${ROBOT}"
    fi
}

# Function to restart a specific robot (simulates robot reboot)
restart_robot() {
    ROBOT="$1"
    if [ -z "$ROBOT" ]; then
        print_error "Please specify robot name (robot-1, robot-2, robot-3)"
        exit 1
    fi
    print_header "Restarting ${ROBOT}"
    docker compose -f "${COMPOSE_FILE}" restart "${ROBOT}"
    print_info "${ROBOT} restarted"
}

# Function to exec into a robot (like SSH into actual robot)
exec_into_robot() {
    ROBOT="$1"
    if [ -z "$ROBOT" ]; then
        print_error "Please specify robot name (robot-1, robot-2, robot-3)"
        exit 1
    fi
    print_header "Connecting to ${ROBOT}"
    docker exec -it "${ROBOT}" /bin/bash
}

# Function to run health check on all robots
health_check() {
    print_header "Running Fleet Health Check"
    for robot in robot-1 robot-2 robot-3; do
        if docker ps | grep -q "$robot"; then
            echo -e "${GREEN}✓${NC} ${robot} is running"
        else
            echo -e "${RED}✗${NC} ${robot} is NOT running"
        fi
    done
}

# Function to deploy update (simulate software update)
deploy_update() {
    print_header "Deploying Software Update to Fleet"
    print_info "Step 1: Building new image..."
    ./docker/build.sh latest
    
    print_info "Step 2: Stopping fleet..."
    docker compose -f "${COMPOSE_FILE}" down
    
    print_info "Step 3: Starting fleet with new image..."
    docker compose -f "${COMPOSE_FILE}" up -d
    
    print_info "Step 4: Verifying deployment..."
    sleep 5
    health_check
    
    print_header "Deployment Complete"
}

# Main script logic
case "$1" in
    start)
        start_fleet
        ;;
    stop)
        stop_fleet
        ;;
    restart)
        restart_robot "$2"
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs "$2"
        ;;
    exec)
        exec_into_robot "$2"
        ;;
    health)
        health_check
        ;;
    deploy)
        deploy_update
        ;;
    *)
        echo "Robot Fleet Management Script"
        echo ""
        echo "Usage: $0 {command} [options]"
        echo ""
        echo "Commands:"
        echo "  start              - Start the robot fleet"
        echo "  stop               - Stop the robot fleet"
        echo "  status             - Show fleet status"
        echo "  logs [robot]       - Show logs (all or specific robot)"
        echo "  restart [robot]    - Restart a specific robot"
        echo "  exec [robot]       - Open shell in robot container"
        echo "  health             - Run health check on all robots"
        echo "  deploy             - Deploy software update to fleet"
        echo ""
        echo "Examples:"
        echo "  $0 start"
        echo "  $0 logs robot-1"
        echo "  $0 restart robot-2"
        echo "  $0 exec robot-1"
        echo "  $0 deploy"
        echo ""
        exit 1
        ;;
esac
