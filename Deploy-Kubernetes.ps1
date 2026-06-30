# Kubernetes Deployment Script (PowerShell)
# Deploy MelodieSpark to Kubernetes cluster
# Run: powershell -ExecutionPolicy Bypass -File Deploy-Kubernetes.ps1

param(
    [string]$KubeContext = "docker-desktop",
    [string]$Namespace = "melodiespark",
    [string]$ImageTag = "latest",
    [string]$DockerRegistry = "docker.io"
)

function Write-Log {
    param([string]$Message, [string]$Type = 'Info')
    $colors = @{ 
        'Info' = 'Cyan'
        'Success' = 'Green'
        'Error' = 'Red'
        'Warn' = 'Yellow'
        'Step' = 'Magenta'
    }
    $symbol = @{
        'Info' = 'ℹ️'
        'Success' = '✅'
        'Error' = '❌'
        'Warn' = '⚠️'
        'Step' = '▶▶▶'
    }
    Write-Host "$($symbol[$Type]) $Message" -ForegroundColor $colors[$Type]
}

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Blue
Write-Host "║  ☸️  KUBERNETES DEPLOYMENT — Multi-Region Scale          ║" -ForegroundColor Blue
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Blue
Write-Host ""

Write-Log "Kubernetes Deployment Configuration" Step
Write-Log "Context: $KubeContext"
Write-Log "Namespace: $Namespace"
Write-Log "Image Tag: $ImageTag"
Write-Log "Registry: $DockerRegistry"
Write-Host ""

# Check kubectl
Write-Log "Checking kubectl" Step

if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Log "kubectl not found. Install from: https://kubernetes.io/docs/tasks/tools/" Error
    exit 1
}

Write-Log "kubectl version: $(kubectl version --client --short)" Success

# Switch context
Write-Log "Switching Kubernetes context to: $KubeContext" Step

try {
    kubectl config use-context $KubeContext
    Write-Log "Context switched successfully" Success
} catch {
    Write-Log "Failed to switch context: $_" Error
    Write-Log "Available contexts:"
    kubectl config get-contexts
    exit 1
}

# Create namespace
Write-Log "Creating Namespace" Step

kubectl create namespace $Namespace --dry-run=client -o yaml | kubectl apply -f -
Write-Log "Namespace '$Namespace' ready" Success

# Create ConfigMap for environment
Write-Log "Creating ConfigMap" Step

$env_config = @"
DATABASE_URL=postgresql://postgres:password@postgres:5432/melodiespark
REDIS_URL=redis://redis:6379
JWT_SECRET=your-secret-key-here
NODE_ENV=production
"@

kubectl create configmap melodiespark-config --from-literal=app-config="$env_config" -n $Namespace --dry-run=client -o yaml | kubectl apply -f -
Write-Log "ConfigMap created" Success

# Deploy PostgreSQL
Write-Log "Deploying PostgreSQL" Step

$postgresYaml = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  namespace: $Namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:16-alpine
        env:
        - name: POSTGRES_PASSWORD
          value: password
        - name: POSTGRES_DB
          value: melodiespark
        ports:
        - containerPort: 5432
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: postgres-storage
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: postgres
  namespace: $Namespace
spec:
  selector:
    app: postgres
  ports:
  - protocol: TCP
    port: 5432
    targetPort: 5432
"@

$postgresYaml | kubectl apply -f -
Write-Log "PostgreSQL deployed" Success

# Deploy Redis
Write-Log "Deploying Redis" Step

$redisYaml = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  namespace: $Namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        ports:
        - containerPort: 6379
---
apiVersion: v1
kind: Service
metadata:
  name: redis
  namespace: $Namespace
spec:
  selector:
    app: redis
  ports:
  - protocol: TCP
    port: 6379
    targetPort: 6379
"@

$redisYaml | kubectl apply -f -
Write-Log "Redis deployed" Success

# Deploy Application
Write-Log "Deploying Application" Step

$appYaml = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: melodiespark-api
  namespace: $Namespace
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: melodiespark-api
  template:
    metadata:
      labels:
        app: melodiespark-api
    spec:
      containers:
      - name: api
        image: $DockerRegistry/melodiespark-api:$ImageTag
        ports:
        - containerPort: 3001
        env:
        - name: DATABASE_URL
          valueFrom:
            configMapKeyRef:
              name: melodiespark-config
              key: database-url
        - name: REDIS_URL
          valueFrom:
            configMapKeyRef:
              name: melodiespark-config
              key: redis-url
        - name: JWT_SECRET
          valueFrom:
            configMapKeyRef:
              name: melodiespark-config
              key: jwt-secret
        livenessProbe:
          httpGet:
            path: /health
            port: 3001
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 3001
          initialDelaySeconds: 5
          periodSeconds: 5
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: melodiespark-api
  namespace: $Namespace
spec:
  selector:
    app: melodiespark-api
  type: LoadBalancer
  ports:
  - protocol: TCP
    port: 80
    targetPort: 3001
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: melodiespark-api-hpa
  namespace: $Namespace
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: melodiespark-api
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 80
"@

$appYaml | kubectl apply -f -
Write-Log "Application deployed" Success

# Wait for deployments
Write-Log "Waiting for deployments to be ready" Step
Write-Log "This may take 1-2 minutes..." Warn

kubectl rollout status deployment/postgres -n $Namespace --timeout=5m
kubectl rollout status deployment/redis -n $Namespace --timeout=5m
kubectl rollout status deployment/melodiespark-api -n $Namespace --timeout=5m

Write-Log "All deployments ready" Success

# Get Service Info
Write-Log "Deployment Summary" Step

Write-Host ""
Write-Host "Services:" -ForegroundColor Cyan
kubectl get svc -n $Namespace

Write-Host ""
Write-Host "Pods:" -ForegroundColor Cyan
kubectl get pods -n $Namespace

# Port Forward
Write-Host ""
Write-Host "To access locally:" -ForegroundColor Cyan
Write-Host "  kubectl port-forward -n $Namespace svc/melodiespark-api 8080:80" -ForegroundColor Gray
Write-Host "  Then visit: http://localhost:8080"

# Summary
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  ✅ KUBERNETES DEPLOYMENT COMPLETE!                      ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

Write-Log "Namespace: $Namespace" Success
Write-Log "API Replicas: 3"
Write-Log "Auto-scaling: Enabled (3-10 replicas)"
Write-Log "Database: PostgreSQL"
Write-Log "Cache: Redis"
Write-Log ""
Write-Log "Monitor pods:" Step
Write-Log "  kubectl get pods -n $Namespace --watch"

exit 0
