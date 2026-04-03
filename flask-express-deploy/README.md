# Flask + Express AWS Deployment

Three deployment scenarios for a Flask backend + Express frontend stack.

- **GitHub Repo:** https://github.com/siddhipisal984/flask-express-deploy1
- **Scenario 1 (Single EC2):** http://13.201.68.148
- **Scenario 2 (Separate EC2s):** http://13.201.120.113 (frontend) | http://13.201.41.86:5000 (backend)
- **Scenario 3 (ECS + ECR + VPC):** http://65.0.26.32:3000

> Note: Stop/terminate EC2 instances and scale ECS services to 0 when not demoing to avoid charges.

---

## Project Structure

```
flask-express-deploy/
├── backend/                    # Flask API (Python, port 5000)
│   ├── app.py
│   ├── Dockerfile
│   └── requirements.txt
├── frontend/                   # Express web server (Node.js, port 3000)
│   ├── server.js
│   ├── Dockerfile
│   ├── package.json
│   └── public/index.html
├── deployment/
│   ├── single-ec2/             # Scenario 1: Both apps on one EC2
│   ├── separate-ec2/           # Scenario 2: Each app on its own EC2
│   └── docker-ecs/             # Scenario 3: Docker + ECR + ECS + VPC
├── terraform/
│   ├── part1-single-ec2/       # Terraform for Scenario 1
│   ├── part2-separate-ec2/     # Terraform for Scenario 2
│   └── part3-ecs-docker/       # Terraform for Scenario 3
└── cicd/                       # Jenkins CI/CD pipelines
```

---

## Apps

- Flask backend: port `5000`, routes `/` and `/api/data`
- Express frontend: port `3000`, proxies `/api/data` to Flask
- Nginx reverse proxy on port `80` (EC2 scenarios)

---

## Scenario 1 — Single EC2

Both Flask and Express run on one EC2 instance behind Nginx.

**Security group ports:** 22 (SSH), 80 (HTTP)

**Steps:**
1. Launch EC2 (Ubuntu 22.04, t2.micro), open ports 22 and 80
2. SSH in and run:
```bash
git clone https://github.com/siddhipisal984/flask-express-deploy1.git
cd flask-express-deploy1/flask-express-deploy
bash deployment/single-ec2/setup.sh
```
3. Visit `http://<EC2-PUBLIC-IP>`

**Or with Terraform:**
```bash
cd terraform/part1-single-ec2
terraform init
terraform apply -var="key_name=your-key-pair"
```

---

## Scenario 2 — Separate EC2 Instances

Flask and Express each run on their own EC2 instance.

**Security groups:** See `deployment/separate-ec2/security-groups.md`

**Steps:**
1. Launch two EC2 instances (Ubuntu 22.04, t2.micro)
2. On the **backend** EC2:
```bash
git clone https://github.com/siddhipisal984/flask-express-deploy1.git
bash flask-express-deploy1/flask-express-deploy/deployment/separate-ec2/setup-backend.sh
# Note the public IP printed at the end
```
3. On the **frontend** EC2:
```bash
git clone https://github.com/siddhipisal984/flask-express-deploy1.git
FLASK_IP=<BACKEND_EC2_IP> bash flask-express-deploy1/flask-express-deploy/deployment/separate-ec2/setup-frontend.sh
```
4. Visit `http://<FRONTEND-EC2-PUBLIC-IP>`

**Or with Terraform:**
```bash
cd terraform/part2-separate-ec2
terraform init
terraform apply -var="key_name=your-key-pair"
```

---

## Scenario 3 — Docker + ECR + ECS + VPC

Containerized deployment on AWS Fargate with a custom VPC and Application Load Balancer.

**Prerequisites:** AWS CLI configured, Docker Desktop running

**Steps:**

1. Test locally:
```bash
cd deployment/docker-ecs
docker-compose up --build
# Visit http://localhost:3000
```

2. Push images to ECR:
```bash
AWS_REGION=us-east-1 AWS_ACCOUNT_ID=<your-12-digit-id> bash push-to-ecr.sh
```

3. Create VPC + ECS infrastructure:
```bash
AWS_REGION=us-east-1 AWS_ACCOUNT_ID=<your-12-digit-id> bash create-ecs-infra.sh
```

4. Find the frontend task public IP:
   `AWS Console > ECS > Clusters > flask-express-cluster > Tasks > (frontend task) > Public IP`

5. Visit `http://<TASK-PUBLIC-IP>:3000`

**Or with Terraform (recommended):**
```bash
cd terraform/part3-ecs-docker
terraform init
terraform apply -var="aws_account_id=<your-12-digit-id>"
# Output: alb_dns_name — open that URL in browser
```

**Stop to avoid charges:**
```bash
bash deployment/docker-ecs/cleanup.sh
```

---

## Cost Tips

- Stop EC2 instances when not in use (AWS Console > EC2 > Stop Instance)
- For ECS Fargate, run `cleanup.sh` to scale services to 0
- Delete ECR images if not needed (charged per GB stored)
- Use `terraform destroy` to tear down all Terraform-managed resources
