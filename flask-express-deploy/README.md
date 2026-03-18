# Flask + Express AWS Deployment

Three deployment scenarios for a Flask backend + Express frontend stack.

- GitHub Repo: https://github.com/siddhipisal984/flask-express-deploy1
- Flask Backend URL: https://flask-backend-ch7h.onrender.com
- Express Frontend URL: https://express-frontend-ntj1.onrender.com

---

## Project Structure

```
flask-express-deploy1/
├── backend/                    # Flask API (Python)
├── frontend/                   # Express web server (Node.js)
└── deployment/
    ├── single-ec2/             # Scenario 1: Both apps on one EC2
    ├── separate-ec2/           # Scenario 2: Each app on its own EC2
    └── docker-ecs/             # Scenario 3: Docker + ECR + ECS + VPC
```

---

## Apps

- Flask backend runs on port `5000`, exposes `/` and `/api/data`
- Express frontend runs on port `3000`, proxies `/api/data` to Flask
- Nginx sits in front on port `80` (EC2 scenarios)

---

## Scenario 1 — Single EC2

Both Flask and Express run on one EC2 instance behind Nginx.

**Steps:**
1. Launch EC2 (Ubuntu 22.04, t2.micro), open ports 22 and 80
2. SSH in and run:
```bash
git clone https://github.com/siddhipisal984/flask-express-deploy1.git
cd flask-express-deploy1
bash deployment/single-ec2/setup.sh
```
3. Visit `http://<EC2-PUBLIC-IP>`

---

## Scenario 2 — Separate EC2 Instances

Flask and Express each run on their own EC2 instance.

**Steps:**
1. Launch two EC2 instances (Ubuntu 22.04)
2. On the **backend** EC2:
```bash
git clone https://github.com/siddhipisal984/flask-express-deploy1.git
bash flask-express-deploy1/deployment/separate-ec2/setup-backend.sh
```
3. Note the backend EC2 public IP printed at the end
4. On the **frontend** EC2:
```bash
git clone https://github.com/siddhipisal984/flask-express-deploy1.git
FLASK_IP=<BACKEND_EC2_IP> bash flask-express-deploy1/deployment/separate-ec2/setup-frontend.sh
```
5. Visit `http://<FRONTEND-EC2-PUBLIC-IP>`

See `deployment/separate-ec2/security-groups.md` for required security group rules.

---

## Scenario 3 — Docker + ECR + ECS + VPC

Containerized deployment on AWS Fargate with a custom VPC.

**Prerequisites:** AWS CLI configured, Docker Desktop running

**Steps:**
1. Test locally first:
```bash
cd deployment/docker-ecs
docker-compose up --build
# Visit http://localhost:3000
```
2. Push images to ECR:
```bash
AWS_REGION=us-east-1 AWS_ACCOUNT_ID=<your-12-digit-account-id> bash push-to-ecr.sh
```
3. Create VPC + ECS infrastructure:
```bash
AWS_REGION=us-east-1 AWS_ACCOUNT_ID=<your-12-digit-account-id> bash create-ecs-infra.sh
```
4. Find the frontend task public IP:
   `AWS Console > ECS > Clusters > flask-express-cluster > Tasks > (frontend task) > Public IP`
5. Visit `http://<TASK-PUBLIC-IP>:3000`

**Stop to avoid charges:**
```bash
bash deployment/docker-ecs/cleanup.sh
```

---

## Scenario 4 — Kubernetes with Minikube (Assignment 7)

Run Flask + Express locally in a Kubernetes cluster using Minikube.

**Prerequisites:**
- [Minikube](https://minikube.sigs.k8s.io/docs/start/) installed
- [kubectl](https://kubernetes.io/docs/tasks/tools/) installed
- Docker Desktop running

**One-command deploy:**
```bash
cd deployment/kubernetes
bash deploy.sh
```

**Or step by step:**
```bash
# 1. Start minikube
minikube start

# 2. Point Docker to minikube's daemon
eval $(minikube docker-env)

# 3. Build images inside minikube
docker build -t flask-backend:latest ../../backend/
docker build -t express-frontend:latest ../../frontend/

# 4. Apply all manifests
kubectl apply -f backend-deployment.yaml
kubectl apply -f backend-service.yaml
kubectl apply -f frontend-deployment.yaml
kubectl apply -f frontend-service.yaml

# 5. Check everything is running
kubectl get pods
kubectl get services
kubectl get deployments

# 6. Open frontend in browser
minikube service express-frontend --url
```

**Useful commands for screenshots:**
```bash
kubectl get pods
kubectl get services
kubectl get deployments
kubectl describe pod <pod-name>
minikube dashboard
```

---

## Cost Tips

- Stop EC2 instances when not in use
- For ECS Fargate, run cleanup.sh to scale to 0
- Delete ECR images if not needed (charged per GB)
