#!/bin/bash
# Production Monitoring & Operations

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "📊 MelodieSpark Production Monitoring"
echo "====================================="

# Get target
TARGET=${1:-local}  # local, vps, or k8s

case $TARGET in
  local)
    echo -e "${BLUE}📍 Monitoring Local Docker Stack${NC}\n"
    
    # Overall status
    echo -e "${BLUE}Service Status:${NC}"
    docker-compose ps
    
    echo -e "\n${BLUE}System Resources:${NC}"
    docker stats --no-stream
    
    echo -e "\n${BLUE}Recent Logs (API):${NC}"
    docker-compose logs --tail=20 api
    
    echo -e "\n${BLUE}Recent Logs (Web):${NC}"
    docker-compose logs --tail=20 web
    
    echo -e "\n${BLUE}Database Connection:${NC}"
    docker-compose exec -T postgres psql -U melodiespark -d melodiespark -c "SELECT version();"
    
    echo -e "\n${BLUE}Redis Connection:${NC}"
    docker-compose exec -T redis redis-cli ping
    
    ;;
    
  vps)
    echo -e "${BLUE}📍 Monitoring VPS Deployment${NC}\n"
    
    read -p "Enter VPS IP: " VPS_IP
    read -p "Enter VPS user (default: root): " VPS_USER
    VPS_USER=${VPS_USER:-root}
    
    echo -e "\n${BLUE}Docker Services:${NC}"
    ssh $VPS_USER@$VPS_IP "docker-compose -f /home/$VPS_USER/melodiespark/MelodieSpark/docker-compose.yml ps"
    
    echo -e "\n${BLUE}System Resources:${NC}"
    ssh $VPS_USER@$VPS_IP "free -h && df -h"
    
    echo -e "\n${BLUE}Recent Service Logs:${NC}"
    ssh $VPS_USER@$VPS_IP "docker-compose -f /home/$VPS_USER/melodiespark/MelodieSpark/docker-compose.yml logs --tail=50 api"
    
    echo -e "\n${BLUE}Nginx Status:${NC}"
    ssh $VPS_USER@$VPS_IP "sudo systemctl status nginx"
    
    echo -e "\n${BLUE}SSL Certificate Expiry:${NC}"
    ssh $VPS_USER@$VPS_IP "sudo certbot certificates"
    
    ;;
    
  k8s)
    echo -e "${BLUE}📍 Monitoring Kubernetes Deployment${NC}\n"
    
    NAMESPACE=${2:-production}
    
    echo -e "${BLUE}Pod Status:${NC}"
    kubectl get pods -n $NAMESPACE
    
    echo -e "\n${BLUE}Pod Details:${NC}"
    kubectl describe pods -n $NAMESPACE
    
    echo -e "\n${BLUE}Service Status:${NC}"
    kubectl get svc -n $NAMESPACE
    
    echo -e "\n${BLUE}Ingress Status:${NC}"
    kubectl get ingress -n $NAMESPACE
    
    echo -e "\n${BLUE}Resource Usage:${NC}"
    kubectl top pods -n $NAMESPACE
    kubectl top nodes
    
    echo -e "\n${BLUE}Recent Events:${NC}"
    kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp'
    
    echo -e "\n${BLUE}Pod Logs (API):${NC}"
    kubectl logs -n $NAMESPACE -l app=melodiespark-api --tail=50
    
    ;;
    
  *)
    echo "Usage: $0 {local|vps|k8s}"
    exit 1
esac

echo -e "\n${GREEN}✅ Monitoring Report Complete${NC}"
