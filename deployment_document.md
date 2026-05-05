# Deployment Document — Global Universities Explorer

---

## 1. Application Overview

Global Universities Explorer is a web app that helps students search universities across 7 countries, filter by GPA, budget, and field of study, and check their admission eligibility. It includes a recommendation engine and a side-by-side comparison tool.

### API Endpoints

| Method | URL | Description |
|--------|-----|-------------|
| GET | `/` | Homepage |
| GET | `/countries` | List all countries |
| GET | `/country/<id>` | Universities in a country |
| GET | `/university/<id>` | Single university detail |
| GET | `/explore` | Search and filter page |
| GET | `/eligibility` | GPA eligibility checker page |
| GET | `/recommendations` | Top-5 recommendations page |
| GET | `/compare` | Side-by-side comparison page |
| GET | `/api/universities` | JSON list of universities (supports filters) |
| GET | `/api/university/<id>` | JSON detail for one university |
| GET | `/api/eligibility` | JSON programs with eligibility status |
| GET | `/api/recommendations` | JSON top-5 scored recommendations |

---

## 2. Architecture Diagram

```
Browser -> EC2 Server -> Docker -> Flask App -> PostgreSQL Database
```

- **Browser** — the user accesses the app through any web browser
- **EC2 Server** — an AWS virtual machine that hosts the app
- **Docker** — runs the app and database as isolated containers
- **Flask App** — handles routes and returns HTML pages or JSON
- **PostgreSQL** — stores all university, program, and country data

---

## 3. Tools and Technologies

| Tool | Why It Was Used |
|------|----------------|
| Linux (Ubuntu 22.04) | Operating system on the EC2 server |
| Python 3.11 | Language the application is written in |
| Flask 3.x | Web framework for handling routes and responses |
| PostgreSQL 15 | Relational database to store all app data |
| psycopg2 | Python library to connect Flask to PostgreSQL |
| Git | Version control to track and push code changes |
| Docker | Packages the app into containers for consistent deployment |
| Docker Compose | Starts the Flask and PostgreSQL containers together |
| GitHub Actions | Automates testing and deployment on every push |
| AWS EC2 | Cloud server that makes the app publicly accessible |

---

## 4. Local Setup Instructions

You need **Git** and **Docker Desktop** installed before starting.

1. Clone the repository:

```bash
git clone https://github.com/<your-username>/global-universities-explorer.git
cd global-universities-explorer
```

2. Start the app:

```bash
docker compose up --build
```

3. Open your browser and go to:

```
http://localhost:5000
```

4. To stop the app:

```bash
docker compose down
```

---

## 5. CI/CD Pipeline Explanation

The pipeline is defined in `.github/workflows/deploy.yml` and runs automatically on every push to the `main` branch.

**Job 1 — test:** Installs Python dependencies and runs all pytest tests.

**Job 2 — deploy:** Only runs if all tests pass. It SSHs into the EC2 server, pulls the latest code, and restarts the Docker containers.

If any test fails, the deploy job is skipped and the broken code is never pushed to the live server. GitHub sends an email notification about the failure.

Two secrets must be added in GitHub under Settings → Secrets:

| Secret | Value |
|--------|-------|
| `EC2_HOST` | Public IP of the EC2 instance |
| `EC2_SSH_KEY` | Contents of the `.pem` private key file |

---

## 6. Deployment Steps

1. Launch an EC2 instance (Ubuntu 22.04, t2.micro) on AWS and download the `.pem` key file.

2. Open port 5000 in the EC2 security group for inbound traffic.

3. Connect to the server:

```bash
chmod 400 uni-explorer-key.pem
ssh -i uni-explorer-key.pem ubuntu@<EC2-PUBLIC-IP>
```

4. Install Docker on the server:

```bash
sudo apt-get update -y
sudo apt-get install -y docker.io docker-compose-v2
sudo usermod -aG docker ubuntu
newgrp docker
```

5. Clone the repository:

```bash
git clone https://github.com/<your-username>/global-universities-explorer.git
cd global-universities-explorer
```

6. Start the app:

```bash
docker compose up --build -d
```

7. Confirm it is running:

```bash
curl http://localhost:5000/api/universities
```

---

## 7. Testing Evidence

**pytest output:**

```
============================= test session starts ==============================
collected 12 items

tests/test_routes.py::test_homepage_loads PASSED
tests/test_routes.py::test_api_universities_returns_json PASSED
tests/test_routes.py::test_api_eligibility_marks_eligible PASSED
tests/test_routes.py::test_api_recommendations_returns_max_5 PASSED
...

============================== 12 passed in 1.84s ==============================
```

**GitHub Actions:** Both the `test` and `deploy` jobs completed with green checkmarks after pushing to `main`.

**Live server curl check:**

```bash
curl -o /dev/null -s -w "%{http_code}" http://<EC2-PUBLIC-IP>:5000/
200
```

---

## 8. Challenges and Solutions

**Challenge 1 — Flask crashed because PostgreSQL was not ready yet**

When Docker starts both containers at once, Flask tried to connect to the database before it was fully initialised. The fix was to add a health check to the `db` service in `docker-compose.yml` so the app container waits until PostgreSQL is actually ready before starting.

**Challenge 2 — SSH connection was rejected due to key file permissions**

The first SSH attempt failed because the `.pem` file permissions were too open. Running `chmod 400` on the file fixed it immediately.

```bash
chmod 400 uni-explorer-key.pem
```

---

## 9. Lessons Learned

1. **Docker containers use service names, not localhost, to talk to each other.** Setting `DB_HOST=db` (the service name) instead of `localhost` was required for Flask to find the database container.

2. **`depends_on` does not mean the service is ready.** It only means the container has started, not that the app inside it is ready. A proper health check is needed to avoid race conditions.

3. **CI/CD secrets must be exact.** Any extra whitespace in the SSH key secret causes the deploy job to fail silently, which took time to diagnose.

4. **Writing documentation reveals gaps in understanding.** Explaining each step forced me to look up details I had glossed over during setup, which made the overall understanding much stronger.
