#!/bin/bash
# Incident Runbook

set -e

echo "🚨 MelodieSpark Incident Runbook"
echo "=================================="

# Color codes
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Issue tracker
INCIDENT_LOG="/var/log/melodiespark-incident.log"

log_incident() {
    echo "[$(date)] $1" >> $INCIDENT_LOG
}

# Get environment
read -p "Environment? (local/vps/k8s): " ENV

case $ENV in
  local)
    echo -e "${BLUE}Local Docker Issues${NC}\n"
    
    # Check if containers are running
    echo "Checking container status..."
    RUNNING=$(docker-compose ps | grep -c "Up" || true)
    TOTAL=$(docker-compose ps | grep -c "melodiespark" || true)
    
    if [ $RUNNING -eq 0 ]; then
        echo -e "${RED}❌ No containers running!${NC}"
        echo "Attempting restart..."
        docker-compose down
        docker-compose up -d
        log_incident "Container crash detected, restarted"
    fi
    
    # Check logs for errors
    echo -e "\n${BLUE}Checking for errors...${NC}"
    ERROR_COUNT=$(docker-compose logs | grep -i "error" | wc -l)
    if [ $ERROR_COUNT -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Found $ERROR_COUNT errors${NC}"
        docker-compose logs | grep -i "error" | tail -10
    fi
    
    # Check disk space
    echo -e "\n${BLUE}Disk space:${NC}"
    docker system df
    
    ;;
    
  vps)
    echo -e "${BLUE}VPS Issues${NC}\n"
    
    read -p "VPS IP: " VPS_IP
    read -p "VPS user (default: root): " VPS_USER
    VPS_USER=${VPS_USER:-root}
    
    # Check SSH
    if ! ssh -o ConnectTimeout=5 $VPS_USER@$VPS_IP "echo" &>/dev/null; then
        echo -e "${RED}❌ Cannot SSH to VPS${NC}"
        exit 1
    fi
    
    # Check services
    echo "Checking services..."
    RUNNING=$(ssh $VPS_USER@$VPS_IP "docker ps | grep melodiespark | wc -l" || true)
    
    if [ $RUNNING -eq 0 ]; then
        echo -e "${RED}❌ Services not running${NC}"
        echo "Restarting..."
        ssh $VPS_USER@$VPS_IP "cd melodiespark/MelodieSpark && docker-compose restart"
        log_incident "Services restarted on $VPS_IP"
    fi
    
    # Check disk
    echo -e "\n${BLUE}Disk usage:${NC}"
    ssh $VPS_USER@$VPS_IP "df -h"
    
    DISK_USED=$(ssh $VPS_USER@$VPS_IP "df / | tail -1 | awk '{print \$5}' | sed 's/%//'")
    if [ $DISK_USED -gt 90 ]; then
        echo -e "${RED}⚠️  Disk usage: $DISK_USED%${NC}"
        echo "Cleaning up..."
        ssh $VPS_USER@$VPS_IP "docker system prune -a -f"
        log_incident "Disk cleanup performed"
    fi
    
    # Check SSL
    echo -e "\n${BLUE}SSL Certificate:${NC}"
    EXPIRE_DATE=$(ssh $VPS_USER@$VPS_IP "sudo certbot certificates 2>/dev/null | grep 'Expiry' | head -1" || echo "Unknown")
    echo "$EXPIRE_DATE"
    
    ;;
    
  k8s)
    echo -e "${BLUE}Kubernetes Issues${NC}\n"
    
    NAMESPACE=${KUBE_NAMESPACE:-production}
    
    # Check pod status
    echo "Checking pod status..."
    FAILING=$(kubectl get pods -n $NAMESPACE --field-selector=status.phase!=Running --field-selector=status.phase!=Succeeded | wc -l)
    
    if [ $FAILING -gt 0 ]; then
        echo -e "${RED}❌ Found failing pods${NC}"
        kubectl get pods -n $NAMESPACE --field-selector=status.phase!=Running
        
        # Describe failing pods
        FAILED_POD=$(kubectl get pods -n $NAMESPACE --field-selector=status.phase!=Running -o jsonpath='{.items[0].metadata.name}' || true)
        if [ ! -z "$FAILED_POD" ]; then
            echo -e "\n${BLUE}Pod details:${NC}"
            kubectl describe pod -n $NAMESPACE $FAILED_POD
            
            echo -e "\n${BLUE}Pod logs:${NC}"
            kubectl logs -n $NAMESPACE $FAILED_POD || true
        fi
    fi
    
    # Check resource availability
    echo -e "\n${BLUE}Node resources:${NC}"
    kubectl top nodes
    
    # Check for pending pods
    PENDING=$(kubectl get pods -n $NAMESPACE --field-selector=status.phase=Pending | wc -l)
    if [ $PENDING -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Found $PENDING pending pods (may need more resources)${NC}"
        kubectl describe nodes | grep -A 5 "Allocated resources"
    fi
    
    ;;
esac

echo -e "\n${GREEN}✅ Incident Assessment Complete${NC}"
echo "Check $INCIDENT_LOG for history"
