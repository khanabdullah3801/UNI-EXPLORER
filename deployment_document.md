# 🚀 UNI-EXPLORER Deployment Guide

This document outlines the professional deployment process for the **Global Universities Explorer** platform, utilizing **AWS EC2**, **Docker containerization**, and **GitHub Actions**.

---

## 🏗️ 1. Architecture Overview

The system architecture is designed for reliability and ease of maintenance using a containerized approach.

*   **Host Platform**: Amazon Web Services (AWS) EC2
*   **Operating System**: Ubuntu 22.04 LTS
*   **Application Server**: Gunicorn WSGI
*   **Database**: PostgreSQL (Dockerized)
*   **Containerization**: Docker Engine
*   **CI/CD**: GitHub Actions

---

## 🛡️ 2. Infrastructure Setup (AWS EC2)

### 2.1 Instance Configuration
1.  Launch an **EC2 Ubuntu** instance.
2.  Configure **Security Groups** with the following inbound rules:
    *   `SSH (Port 22)`: For administrative access.
    *   `HTTP (Port 80)`: For public web access.
    *   `PostgreSQL (Port 5432)`: For database connectivity.

### 2.2 Server Preparation
Install Docker on the EC2 instance to enable containerized hosting:
```bash
sudo apt update
sudo apt install docker.io -y
sudo usermod -aG docker $USER
# Log out and back in to apply changes
```

---

## 🐳 3. Container Deployment

The application and database are deployed as separate Docker containers, communicating over a shared virtual network.

### 3.1 Database Container (PostgreSQL)
Run the database container using the official Postgres image:
```bash
docker run -d \
  --name uni-db \
  -p 5432:5432 \
  -e POSTGRES_DB=universities_db \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=[YOUR_DB_PASSWORD] \
  --restart always \
  postgres
```

### 3.2 Application Container (Flask)
Build the production image and run the web server:

**Build Command:**
```bash
docker build -t uni-explorer:v1 .
```

**Run Command:**
```bash
docker run -d \
  --name uni-app \
  -p 80:5000 \
  --link uni-db:db \
  -e DB_HOST=db \
  -e DB_NAME=universities_db \
  -e DB_USER=postgres \
  -e DB_PASSWORD=[YOUR_DB_PASSWORD] \
  -e SECRET_KEY=[YOUR_PRODUCTION_SECRET] \
  --restart always \
  uni-explorer:v1
```

> [!TIP]
> **Security Best Practice**: Instead of passing secrets via the `-e` flag, it is highly recommended to use an `--env-file .env` flag. Create a `.env` file on your server and ensure it is included in your `.gitignore`.

---

## 🌐 4. Application Access

The application is exposed on port **80** and is publicly accessible via the AWS Elastic IP:

*   **Production URL**: [http://13.206.120.56/](http://13.206.120.56/)
*   **WSGI Server**: Gunicorn (binding 0.0.0.0:5000) mapped to host port 80.

---

## ⚙️ 5. CI/CD Pipeline

**GitHub Actions** is utilized for automated testing and deployment validation. This ensures that every code push meets quality standards before reaching the production environment.

*   **Automated Testing**: Runs unit tests on every pull request.
*   **Deployment Workflow**: (Optional) Automated pull and restart on the EC2 instance.

---

## 📊 6. Logs and Monitoring

To monitor the health of the system and troubleshoot runtime issues:

```bash
# View real-time application logs
docker logs -f uni-app

# View database container logs
docker logs -f uni-db

# Check container status
docker ps
```

---

## 🛠️ 7. Troubleshooting

*   **Port Mapping**: Ensure no other service is binding to port 80 on the host.
*   **DB Connection**: Verify that the `DB_HOST` in the application environment matches the database container name/alias.
*   **AWS Security Group**: Ensure that inbound traffic for Port 80 is allowed for `0.0.0.0/0`.

---

## 📝 8. Conclusion

This project successfully demonstrates a full-stack deployment cycle. By using Docker on AWS EC2, we achieve a scalable, portable, and professional hosting environment for the Global Universities Explorer.
