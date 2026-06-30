#!/bin/bash
# Master Automation Entry Point
# One command to deploy everything

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

clear

# Display banner
cat << 'EOF'
╔════════════════════════════════════════════════════════════════════════════╗
║                                                                            ║
║             🚀 MelodieSpark Complete Automation System 🚀                 ║
║                                                                            ║
║              Deploy to Vercel + Railway in ONE Command                     ║
║                                                                            ║
║              ✅ Fully Automated                                            ║
║              ✅ Multi-Stage Deployment                                     ║
║              ✅ Health Monitoring Included                                 ║
║              ✅ Auto-Rollback Ready                                        ║
║              ✅ GitHub Actions Integration                                 ║
║                                                                            ║
╚════════════════════════════════════════════════════════════════════════════╝

EOF

echo -e "${CYAN}Welcome to the Complete Automation System!${NC}\n"

# Menu
show_menu() {
    echo -e "${BOLD}What would you like to do?${NC}\n"
    echo "1) Full Automated Deployment (Recommended) ⭐"
    echo "2) Generate Configurations Only"
    echo "3) Deploy Frontend Only (Vercel)"
    echo "4) Deploy Backend Only (Railway)"
    echo "5) Run Health Checks"
    echo "6) View Deployment Logs"
    echo "7) Setup Emergency Rollback"
    echo "8) View Help & Documentation"
    echo ""
    read -p "Enter choice (1-8): " choice
}

# Execution functions
full_deployment() {
    echo -e "\n${CYAN}Starting Full Automated Deployment...${NC}\n"
    
    # Step 1: Generate configs
    echo "Step 1/2: Generating configurations..."
    bash "$PROJECT_ROOT/generate-automation-configs.sh"
    
    # Step 2: Run orchestrator
    echo -e "\nStep 2/2: Running automation orchestrator..."
    bash "$PROJECT_ROOT/automation-orchestrator.sh"
    
    echo -e "\n${GREEN}✅ Full automated deployment complete!${NC}"
}

generate_configs_only() {
    echo -e "\n${CYAN}Generating configurations only...${NC}\n"
    bash "$PROJECT_ROOT/generate-automation-configs.sh"
    echo -e "\n${GREEN}✅ Configurations generated in: .automations/configs/${NC}"
}

deploy_vercel() {
    echo -e "\n${CYAN}Deploying frontend to Vercel...${NC}\n"
    
    if ! command -v vercel &> /dev/null; then
        echo "Installing Vercel CLI..."
        npm install -g vercel
    fi
    
    cd "$PROJECT_ROOT/MelodieSpark/apps/web"
    vercel --prod
    echo -e "\n${GREEN}✅ Vercel deployment complete!${NC}"
}

deploy_railway() {
    echo -e "\n${CYAN}Deploying backend to Railway...${NC}\n"
    
    if ! command -v railway &> /dev/null; then
        echo "Installing Railway CLI..."
        npm install -g @railway/cli
    fi
    
    cd "$PROJECT_ROOT"
    railway login --force
    railway init
    railway up
    echo -e "\n${GREEN}✅ Railway deployment complete!${NC}"
}

health_checks() {
    echo -e "\n${CYAN}Running Health Checks...${NC}\n"
    
    if [ ! -d ".automations/state" ]; then
        echo -e "${RED}No deployment state found. Run full deployment first.${NC}"
        return 1
    fi
    
    # Load URLs from state
    local vercel_url=$(cat .automations/state/vercel_url 2>/dev/null || echo "unknown")
    local railway_url=$(cat .automations/state/railway_url 2>/dev/null || echo "unknown")
    
    echo "Frontend URL: $vercel_url"
    echo "API URL: $railway_url"
    echo ""
    
    echo "Checking frontend..."
    curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" "$vercel_url"
    
    echo "Checking API..."
    curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" "$railway_url/health"
    
    echo -e "\n${GREEN}✅ Health checks complete!${NC}"
}

view_logs() {
    echo -e "\n${CYAN}Viewing Deployment Logs...${NC}\n"
    
    if [ -f ".automations/logs/deployment-report.md" ]; then
        cat ".automations/logs/deployment-report.md"
    else
        echo -e "${YELLOW}No deployment report found yet.${NC}"
    fi
    
    echo -e "\n${CYAN}Recent log entries:${NC}"
    if [ -f ".automations/logs/automation.log" ]; then
        tail -20 ".automations/logs/automation.log"
    fi
}

setup_rollback() {
    echo -e "\n${CYAN}Setting up Emergency Rollback...${NC}\n"
    
    if [ ! -f ".automations/rollback.sh" ]; then
        echo "Creating rollback script..."
        mkdir -p ".automations"
        bash "$PROJECT_ROOT/generate-automation-configs.sh" > /dev/null
    fi
    
    echo -e "${YELLOW}Rollback is ready!${NC}"
    echo ""
    echo "To rollback to previous version:"
    echo "  bash .automations/rollback.sh"
    echo ""
    echo -e "${GREEN}✅ Rollback setup complete!${NC}"
}

show_help() {
    echo -e "\n${CYAN}MelodieSpark Complete Automation System${NC}\n"
    echo "📚 Documentation:"
    echo "  • COMPLETE_AUTOMATION_GUIDE.md - Full guide"
    echo "  • VERCEL_RAILWAY_DEPLOYMENT.md - Manual steps"
    echo "  • TOTAL_DEPLOYMENT_GUIDE.md - All options"
    echo ""
    echo "🚀 Quick Commands:"
    echo "  • Full deploy: bash automation-orchestrator.sh"
    echo "  • Generate configs: bash generate-automation-configs.sh"
    echo "  • Monitor: bash .automations/monitor.sh"
    echo "  • Rollback: bash .automations/rollback.sh"
    echo ""
    echo "📊 Deployment Folders:"
    echo "  • .automations/configs/ - Configuration files"
    echo "  • .automations/logs/ - Deployment logs"
    echo "  • .automations/state/ - Current state"
    echo ""
}

# Main loop
while true; do
    show_menu
    
    case $choice in
        1)
            full_deployment
            break
            ;;
        2)
            generate_configs_only
            break
            ;;
        3)
            deploy_vercel
            break
            ;;
        4)
            deploy_railway
            break
            ;;
        5)
            health_checks
            ;;
        6)
            view_logs
            ;;
        7)
            setup_rollback
            ;;
        8)
            show_help
            ;;
        *)
            echo -e "${RED}Invalid choice. Please try again.${NC}\n"
            continue
            ;;
    esac
done

# Final message
echo -e "\n${BOLD}${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}${GREEN}Automation System Ready!${NC}"
echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════════════════════${NC}\n"

echo -e "${CYAN}📌 Important Next Steps:${NC}"
echo "   1. Monitor deployments: tail -f .automations/logs/automation.log"
echo "   2. Check health: bash .automations/monitor.sh &"
echo "   3. Review dashboards: Vercel & Railway"
echo ""
echo -e "${GREEN}🎉 Your application is now fully automated!${NC}\n"
