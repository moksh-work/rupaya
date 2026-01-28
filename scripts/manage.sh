#!/bin/bash
# Enterprise monorepo management script

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

show_help() {
    echo -e "${BLUE}RUPAYA Monorepo Manager${NC}"
    echo ""
    echo "Usage: ./scripts/manage.sh [command] [service]"
    echo ""
    echo "Commands:"
    echo "  start [service]    - Start service(s)"
    echo "  stop [service]     - Stop service(s)"
    echo "  test [service]     - Run tests for service(s)"
    echo "  build [service]    - Build service(s)"
    echo "  clean              - Clean all build artifacts"
    echo "  status             - Show status of all services"
    echo "  logs [service]     - Show logs for service"
    echo ""
    echo "Services:"
    echo "  backend            - Node.js Express API"
    echo "  android            - Android app"
    echo "  ios                - iOS app"
    echo "  all                - All services (where applicable)"
    echo ""
}

start_backend() {
    echo -e "${GREEN}Starting backend...${NC}"
    cd "$PROJECT_ROOT/backend"
    docker-compose -f docker-compose.dev.yml up -d
    echo -e "${GREEN}✓ Backend started at http://localhost:3000${NC}"
}

stop_backend() {
    echo -e "${YELLOW}Stopping backend...${NC}"
    cd "$PROJECT_ROOT/backend"
    docker-compose -f docker-compose.dev.yml down
    echo -e "${GREEN}✓ Backend stopped${NC}"
}

test_backend() {
    echo -e "${GREEN}Testing backend...${NC}"
    cd "$PROJECT_ROOT/backend"
    docker-compose -f docker-compose.dev.yml exec -T backend npm test
}

build_android() {
    echo -e "${GREEN}Building Android app...${NC}"
    cd "$PROJECT_ROOT/android"
    ./gradlew assembleDebug
    echo -e "${GREEN}✓ Android APK: android/app/build/outputs/apk/debug/app-debug.apk${NC}"
}

build_ios() {
    echo -e "${GREEN}Building iOS app...${NC}"
    cd "$PROJECT_ROOT/ios"
    
    if [ ! -f "RUPAYA.xcworkspace" ]; then
        echo -e "${YELLOW}Running pod install...${NC}"
        export PATH="/opt/homebrew/opt/ruby/bin:/opt/homebrew/lib/ruby/gems/4.0.0/bin:$PATH"
        pod install
    fi
    
    xcodebuild -workspace RUPAYA.xcworkspace \
        -scheme RUPAYA \
        -configuration Debug \
        -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
        build
    
    echo -e "${GREEN}✓ iOS app built${NC}"
}

show_status() {
    echo -e "${BLUE}=== Service Status ===${NC}"
    echo ""
    
    # Backend
    if curl -s http://localhost:3000/health > /dev/null 2>&1; then
        echo -e "Backend:  ${GREEN}✓ Running${NC} (http://localhost:3000)"
    else
        echo -e "Backend:  ${RED}✗ Stopped${NC}"
    fi
    
    # Android
    if [ -d "$PROJECT_ROOT/android/app/build" ]; then
        echo -e "Android:  ${GREEN}✓ Built${NC}"
    else
        echo -e "Android:  ${YELLOW}○ Not built${NC}"
    fi
    
    # iOS
    if [ -d "$PROJECT_ROOT/ios/build" ] || [ -f "$PROJECT_ROOT/ios/RUPAYA.xcworkspace" ]; then
        echo -e "iOS:      ${GREEN}✓ Configured${NC}"
    else
        echo -e "iOS:      ${YELLOW}○ Not configured${NC}"
    fi
    
    echo ""
}

logs_backend() {
    cd "$PROJECT_ROOT/backend"
    docker-compose -f docker-compose.dev.yml logs -f backend
}

clean_all() {
    echo -e "${YELLOW}Cleaning all build artifacts...${NC}"
    
    # Backend
    if [ -d "$PROJECT_ROOT/backend/node_modules" ]; then
        echo "Cleaning backend node_modules..."
        rm -rf "$PROJECT_ROOT/backend/node_modules"
    fi
    
    # Android
    if [ -d "$PROJECT_ROOT/android/app/build" ]; then
        echo "Cleaning Android build..."
        cd "$PROJECT_ROOT/android"
        ./gradlew clean
    fi
    
    # iOS
    if [ -d "$PROJECT_ROOT/ios/build" ]; then
        echo "Cleaning iOS build..."
        rm -rf "$PROJECT_ROOT/ios/build"
    fi
    
    if [ -d "$PROJECT_ROOT/ios/Pods" ]; then
        echo "Cleaning iOS Pods..."
        rm -rf "$PROJECT_ROOT/ios/Pods"
        rm -f "$PROJECT_ROOT/ios/Podfile.lock"
    fi
    
    echo -e "${GREEN}✓ Clean complete${NC}"
}

# Main script logic
case "$1" in
    start)
        case "$2" in
            backend) start_backend ;;
            all) start_backend ;;
            *) echo "Unknown service: $2"; show_help ;;
        esac
        ;;
    stop)
        case "$2" in
            backend) stop_backend ;;
            all) stop_backend ;;
            *) echo "Unknown service: $2"; show_help ;;
        esac
        ;;
    test)
        case "$2" in
            backend) test_backend ;;
            *) echo "Unknown service: $2"; show_help ;;
        esac
        ;;
    build)
        case "$2" in
            android) build_android ;;
            ios) build_ios ;;
            all) build_android && build_ios ;;
            *) echo "Unknown service: $2"; show_help ;;
        esac
        ;;
    logs)
        case "$2" in
            backend) logs_backend ;;
            *) echo "Unknown service: $2"; show_help ;;
        esac
        ;;
    status)
        show_status
        ;;
    clean)
        clean_all
        ;;
    *)
        show_help
        ;;
esac
