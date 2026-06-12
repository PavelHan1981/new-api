# deploy.ps1
# ==========================================
# Deploy configuration
# ==========================================
$AWS_REGION = "ap-southeast-1"
$AWS_ACCOUNT_ID = "508834441239" # Your AWS Account ID
$ECR_REPO = "junpeng/test"
$ECS_CLUSTER = "junpeng-test-cluster"
$ECS_SERVICE = "new-api-task-service-bchfjrg5"

# 1. Login to AWS ECR
Write-Host "[1/4] Logging in to Amazon ECR..." -ForegroundColor Green
$password = aws ecr get-login-password --region $AWS_REGION
docker login --username AWS --password $password "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

if ($LASTEXITCODE -ne 0) {
    Write-Error "ECR login failed. Please check network proxy or AWS credentials."
    exit
}

# 2. Build Docker image locally
Write-Host "[2/4] Building Docker image locally..." -ForegroundColor Green
docker build --no-cache -t "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/${ECR_REPO}:latest" .

if ($LASTEXITCODE -ne 0) {
    Write-Error "Docker build failed. Please check your code or Docker daemon."
    exit
}

# 3. Push image to AWS ECR
Write-Host "[3/4] Pushing image to ECR..." -ForegroundColor Green
docker push "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/${ECR_REPO}:latest"

if ($LASTEXITCODE -ne 0) {
    Write-Error "Image push failed. Please check ECR repository permissions or network."
    exit
}

# 4. Force ECS update
Write-Host "[4/4] Triggering ECS service redeployment..." -ForegroundColor Green
aws ecs update-service --cluster $ECS_CLUSTER --service $ECS_SERVICE --force-new-deployment --region $AWS_REGION

if ($LASTEXITCODE -ne 0) {
    Write-Error "ECS service update failed. Please check service name or permissions."
    exit
}

Write-Host "Deployment completed! AWS ECS is rolling restart container to pull the latest image. Please wait 1-2 minutes." -ForegroundColor Cyan
