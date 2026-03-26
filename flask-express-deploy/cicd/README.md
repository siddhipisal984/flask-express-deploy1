# Assignment 9 — CI/CD Deployment with Jenkins

## GitHub Repository
https://github.com/siddhipisal984/flask-express-deploy1

---

## Architecture

```
EC2 Instance (t3.micro, Ubuntu 24.04, ap-south-1)
IP: 35.154.215.122
│
├── Flask Backend     → port 5000 (managed by PM2)
├── Express Frontend  → port 3000 (managed by PM2)
└── Jenkins CI/CD     → port 8080 (running via jenkins.war)
```

---

## Part 1 — Deploy Flask and Express on Single EC2

### EC2 Setup
- Instance: t3.micro, Ubuntu 24.04, Mumbai (ap-south-1)
- Security Group ports: 22, 3000, 5000, 8080

### Dependencies Installed
```bash
sudo apt-get install -y python3 python3-pip python3-venv nodejs npm git
sudo npm install -g pm2
```

### Application Setup
```bash
git clone https://github.com/siddhipisal984/flask-express-deploy1.git

# Flask
cd flask-express-deploy1/flask-express-deploy/backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Express
cd ../frontend
npm install --production
```

### Start with PM2
```bash
# Flask on port 5000
pm2 start "venv/bin/gunicorn --bind 0.0.0.0:5000 app:app" --name flask-backend

# Express on port 3000
FLASK_URL=http://localhost:5000 pm2 start server.js --name express-frontend
pm2 save
```

### Access URLs
- Flask Backend:   http://35.154.215.122:5000
- Express Frontend: http://35.154.215.122:3000

---

## Part 2 — CI/CD Pipeline with Jenkins

### Jenkins Installation
```bash
sudo apt-get install -y openjdk-17-jdk wget
wget https://get.jenkins.io/war-stable/latest/jenkins.war
nohup java -jar jenkins.war --httpPort=8080 > /tmp/jenkins.log 2>&1 &
```

Jenkins URL: http://35.154.215.122:8080

### Flask Pipeline (Jenkinsfile.flask)
```groovy
pipeline {
    agent any
    stages {
        stage('Pull Code') {
            steps {
                sh 'cd /home/ubuntu/flask-express-deploy1 && git pull origin main'
            }
        }
        stage('Install Dependencies') {
            steps {
                sh 'cd /home/ubuntu/flask-express-deploy1/flask-express-deploy/backend && venv/bin/pip install -r requirements.txt'
            }
        }
        stage('Deploy') {
            steps {
                sh 'pm2 restart flask-backend'
            }
        }
    }
}
```

### Express Pipeline (Jenkinsfile.express)
```groovy
pipeline {
    agent any
    stages {
        stage('Pull Code') {
            steps {
                sh 'cd /home/ubuntu/flask-express-deploy1 && git pull origin main'
            }
        }
        stage('Install Dependencies') {
            steps {
                sh 'cd /home/ubuntu/flask-express-deploy1/flask-express-deploy/frontend && npm install --production'
            }
        }
        stage('Deploy') {
            steps {
                sh 'pm2 restart express-frontend'
            }
        }
    }
}
```

### GitHub Webhook Setup
1. GitHub repo → Settings → Webhooks → Add webhook
2. Payload URL: `http://35.154.215.122:8080/github-webhook/`
3. Content type: `application/json`
4. Event: `Just the push event`

---

## Screenshots Evidence
- EC2 instance running (3/3 status checks passed)
- PM2 showing flask-backend and express-frontend online
- Jenkins flask-backend-pipeline — Build #5 SUCCESS
- Jenkins express-frontend-pipeline — Build #1 SUCCESS
- Flask app accessible at http://35.154.215.122:5000
- Express app accessible at http://35.154.215.122:3000
