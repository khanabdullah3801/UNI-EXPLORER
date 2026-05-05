# Deployment Document — Global Universities Explorer

---

## Table of Contents

1. [Application Overview](#1-application-overview)
2. [Architecture Diagram](#2-architecture-diagram)
3. [Tools and Technologies](#3-tools-and-technologies)
4. [Local Setup Instructions](#4-local-setup-instructions)
5. [CI/CD Pipeline Explanation](#5-cicd-pipeline-explanation)
6. [Deployment Steps](#6-deployment-steps)
7. [Testing Evidence](#7-testing-evidence)
8. [Challenges and Solutions](#8-challenges-and-solutions)
9. [Lessons Learned](#9-lessons-learned)

---

## 1. Application Overview

### What It Does

**Global Universities Explorer** is a full-stack web application that helps prospective international students research universities across seven major study destinations — the United Kingdom, United States, Australia, Germany, France, Canada, and Turkey. Students can browse 27 universities and 130+ programs, filter by degree level, field of study, language, tuition budget, and GPA, and instantly see whether they are eligible for a given program.

### Problem It Solves

Researching universities abroad is fragmented and time-consuming. Students typically visit dozens of individual university websites to compare admission requirements, tuition costs, and programs. This application centralises all of that information into a single interface with smart filtering, a GPA eligibility checker, personalised recommendations scored out of 100, and a side-by-side comparison tool.

### Target Users

- Undergraduate students planning postgraduate study abroad
- Academic advisors helping students choose suitable programmes
- Educational consultants who need a quick overview of global university requirements

---

### API Endpoints

| Method | URL | Description | Example Response |
|--------|-----|-------------|-----------------|
| `GET` | `/` | Homepage — returns country list, university count, and program count | Rendered HTML page |
| `GET` | `/countries` | Lists all countries with their university counts | Rendered HTML page |
| `GET` | `/country/<id>` | Detail page for a single country showing its universities | Rendered HTML page |
| `GET` | `/university/<id>` | Full detail page for a single university including all programs | Rendered HTML page |
| `GET` | `/explore` | University search and filter page | Rendered HTML page |
| `GET` | `/eligibility` | GPA eligibility checker page | Rendered HTML page |
| `GET` | `/recommendations` | Personalised top-5 recommendations page | Rendered HTML page |
| `GET` | `/compare` | Side-by-side university comparison tool | Rendered HTML page |
| `GET` | `/api/universities` | JSON list of universities matching filter params (`country`, `degree`, `field`, `language`, `min_fee`, `max_fee`, `min_gpa`) | `[{"id": 1, "name": "University of Oxford", "city": "Oxford", "country": "United Kingdom", "min_fee": 28950, "degree_levels": ["Masters", "PhD"], ...}]` |
| `GET` | `/api/university/<id>` | JSON object for a single university including its full program list | `{"id": 1, "name": "University of Oxford", "programs": [...]}` |
| `GET` | `/api/eligibility` | JSON list of programs with eligibility status (`eligible`, `borderline`, `not_eligible`) based on `gpa`, `degree`, `field`, `language`, `budget` | `[{"program": "MSc Computer Science", "status": "eligible", "min_gpa": 3.5, ...}]` |
| `GET` | `/api/recommendations` | JSON top-5 scored university recommendations based on `gpa`, `budget`, `degree`, `field`, `language` | `[{"university": "TU Munich", "score": 87.4, "reasons": ["Your GPA meets the minimum", ...]}]` |

---

## 2. Architecture Diagram

The following ASCII diagram shows how a user request travels from the browser all the way through to the database and back.

```
┌─────────────────────────────────────────────────────────────────────┐
│                          USER'S BROWSER                             │
│              (Chrome / Firefox / Safari — any device)               │
└────────────────────────────┬────────────────────────────────────────┘
                             │  HTTP request (port 80 / 5000)
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        AWS EC2 INSTANCE                             │
│                  (Ubuntu 22.04 — t2.micro or larger)                │
│                                                                     │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │                    DOCKER ENGINE                            │   │
│   │                                                             │   │
│   │   ┌─────────────────────┐   ┌───────────────────────────┐  │   │
│   │   │  app container      │   │  db container             │  │   │
│   │   │  (Python 3.11 +     │──▶│  (PostgreSQL 15)          │  │   │
│   │   │   Flask 3.x)        │   │  universities_db          │  │   │
│   │   │  port 5000          │   │  port 5432                │  │   │
│   │   └─────────────────────┘   └───────────────────────────┘  │   │
│   │          Docker internal network (bridge)                   │   │
│   └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
│   Security Group: inbound TCP 22 (SSH), 5000 (app), 80 (optional)  │
└─────────────────────────────────────────────────────────────────────┘
                             ▲
                             │  git push / GitHub Actions deploy
                             │
┌─────────────────────────────────────────────────────────────────────┐
│                     GITHUB ACTIONS (CI/CD)                          │
│   Triggered on push to main → runs pytest → builds Docker image →   │
│   SSHs into EC2 → pulls latest code → restarts containers           │
└─────────────────────────────────────────────────────────────────────┘
```

**Component Summary:**

| Component | Role |
|-----------|------|
| Browser | Sends HTTP requests; receives rendered HTML or JSON |
| AWS EC2 | Virtual server that hosts the entire application |
| Docker Engine | Runs isolated containers for the app and the database |
| Flask app container | Handles all HTTP routing and business logic |
| PostgreSQL container | Stores all university, program, and country data |
| GitHub Actions | Automates testing and deployment on every push |

---

## 3. Tools and Technologies

| Tool / Technology | Version Used | Why It Was Used |
|-------------------|-------------|-----------------|
| **Linux (Ubuntu 22.04)** | 22.04 LTS | Industry-standard server OS; stable, well-documented, and free — used as the EC2 operating system |
| **Python** | 3.11 | The language the application is written in; widely used for web backends and supported by a large ecosystem |
| **Flask** | 3.x | A lightweight Python web framework that makes it easy to define routes and return HTML or JSON without a lot of boilerplate |
| **PostgreSQL** | 15 | A robust, open-source relational database; chosen because the data (universities, programs, countries) has clear relationships that SQL handles well |
| **psycopg2** | 2.9.x | The standard Python adapter for PostgreSQL; allows Flask to execute SQL queries and fetch results as dictionaries |
| **Git** | 2.x | Version control system used to track all code changes and coordinate pushes to GitHub |
| **Docker** | 24.x | Packages the application and its dependencies into portable containers so the app runs identically on any machine |
| **Docker Compose** | 2.x | Defines and starts both the Flask app container and the PostgreSQL container together with a single command |
| **GitHub Actions** | N/A (cloud service) | Automates the CI/CD pipeline — runs tests and redeploys to EC2 automatically every time code is pushed to the main branch |
| **AWS EC2** | N/A (cloud service) | Provides a virtual server in the cloud that is publicly accessible, so the app can be reached from any browser |
| **Bootstrap 5.3** | 5.3 | CSS framework used in the frontend templates to create a responsive, mobile-friendly layout quickly |
| **pytest** | 7.x | Python testing framework used to write and run automated tests against the Flask routes and API endpoints |

---

## 4. Local Setup Instructions

Follow these steps exactly to run the application on your own machine. You need **Docker Desktop** and **Git** installed before you begin.

### Prerequisites

- Git — download from https://git-scm.com
- Docker Desktop — download from https://www.docker.com/products/docker-desktop (includes Docker Compose)
- No Python or PostgreSQL installation is needed locally — Docker handles everything

### Step 1 — Clone the Repository

Open a terminal and run:

```bash
git clone https://github.com/<your-username>/global-universities-explorer.git
cd global-universities-explorer
```

### Step 2 — Inspect the Project Structure

Confirm the key files are present:

```bash
ls
# You should see: app.py  schema.sql  requirements.txt  Dockerfile  docker-compose.yml  README.md
```

### Step 3 — Review the Docker Compose Configuration

Open `docker-compose.yml` to understand what will be started. It defines two services:
- `db` — a PostgreSQL 15 container with the `universities_db` database
- `app` — the Flask application container, which depends on `db`

```yaml
# docker-compose.yml (example)
version: "3.9"

services:
  db:
    image: postgres:15
    environment:
      POSTGRES_DB: universities_db
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    volumes:
      - ./schema.sql:/docker-entrypoint-initdb.d/schema.sql
    ports:
      - "5432:5432"

  app:
    build: .
    ports:
      - "5000:5000"
    environment:
      DB_NAME: universities_db
      DB_USER: postgres
      DB_PASSWORD: postgres
      DB_HOST: db
      DB_PORT: 5432
    depends_on:
      - db
```

### Step 4 — Build and Start the Containers

```bash
docker compose up --build
```

This command does the following:
1. Builds the Flask application image using the `Dockerfile`
2. Pulls the official PostgreSQL 15 image
3. Starts the `db` container first and runs `schema.sql` to create all tables and seed data
4. Starts the `app` container once the database is ready

The first run takes 1–2 minutes because Docker needs to download images and install Python dependencies.

### Step 5 — Confirm the App is Running

You will see log output ending with something like:

```
app-1  |  * Running on http://0.0.0.0:5000
app-1  |  * Debug mode: on
```

### Step 6 — Open in Your Browser

Navigate to:

```
http://localhost:5000
```

You should see the Global Universities Explorer homepage with the hero section and country cards.

### Step 7 — Test an API Endpoint

Open a second terminal and run:

```bash
curl http://localhost:5000/api/universities?country=Germany
```

You should receive a JSON array of German universities.

### Step 8 — Stop the App

When you are done, stop all containers with:

```bash
docker compose down
```

To also delete the database volume (full reset):

```bash
docker compose down -v
```

---

## 5. CI/CD Pipeline Explanation

3. Installs all dependencies from `requirements.txt`
4. Runs the full pytest test suite against the Flask application

```yaml
test:
  steps:
    - uses: actions/checkout@v3
    - uses: actions/setup-python@v4
      with:
        python-version: "3.11"
    - run: pip install -r requirements.txt
    - run: pytest tests/ -v
```

#### Job 2 — `deploy`

This job only runs if the `test` job passes successfully (`needs: test`). It:

  runs-on: ubuntu-latest
1. SSHs into the EC2 instance using a private key stored as a GitHub Actions secret
2. Navigates to the project directory on the server
3. Pulls the latest code from the `main` branch
4. Rebuilds and restarts the Docker containers with zero downtime (`--build -d`)

```yaml
deploy:
  needs: test
  runs-on: ubuntu-latest
  steps:
    - name: Deploy to EC2
      uses: appleboy/ssh-action@v1.0.0
      with:
        host: ${{ secrets.EC2_HOST }}
        username: ubuntu
        key: ${{ secrets.EC2_SSH_KEY }}
The CI/CD pipeline is defined in `.github/workflows/deploy.yml`. It runs automatically on GitHub Actions every time code is pushed to the `main` branch.
        script: |
          cd /home/ubuntu/global-universities-explorer
          git pull origin main
          docker compose up --build -d
```

### What Happens if a Test Fails

If any pytest test fails, the `test` job exits with a non-zero status code. GitHub Actions marks the run as failed (shown with a red cross on the Actions tab). The `deploy` job is skipped entirely because of the `needs: test` dependency. The broken code is **never deployed to the live server**. The developer receives an email notification from GitHub and must fix the failing test before the pipeline will succeed.
2. Sets up Python 3.11

### Secrets Configuration

The following secrets must be set in the GitHub repository under **Settings → Secrets and variables → Actions**:

| Secret Name | What It Stores |
|-------------|---------------|
| `EC2_HOST` | The public IP address of the EC2 instance |
| `EC2_SSH_KEY` | The full contents of the `.pem` private key file used to SSH into EC2 |

---

## 6. Deployment Steps

These are the exact steps taken to deploy the application on AWS EC2 from a fresh instance to a live, publicly accessible app.

### What Triggers the Pipeline
1. Checks out the repository code

This job runs on an `ubuntu-latest` GitHub-hosted runner. It:

Any `git push` to the `main` branch triggers the workflow. Pull request pushes to other branches do not trigger deployment, only the test job.

1. Log into the AWS Management Console at https://console.aws.amazon.com
### Step 1 — Launch an EC2 Instance

2. Navigate to **EC2 → Launch Instance**

3. Configure the instance as follows:

   - **Name:** `global-universities-server`

   - **AMI:** Ubuntu Server 22.04 LTS (64-bit x86)
   - **Instance type:** `t2.micro` (eligible for free tier)

   - **Key pair:** Create a new key pair named `uni-explorer-key`, download the `.pem` file, and store it safely

   - **Security group rules:** Allow inbound SSH (TCP 22) from your IP, and inbound Custom TCP (port 5000) from `0.0.0.0/0`

4. Click **Launch Instance** and wait for the instance state to show **Running**

5. Note the **Public IPv4 address** (e.g., `54.123.45.67`)


### Step 2 — Connect to the Instance via SSH


From your local machine terminal:


```bash
chmod 400 uni-explorer-key.pem

ssh -i uni-explorer-key.pem ubuntu@54.123.45.67
```


You should now be at the EC2 Ubuntu prompt.

### Step 3 — Update the Server and Install Docker


```bash
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y ca-certificates curl gnupg lsb-release git

# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine and Docker Compose plugin
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Allow the ubuntu user to run Docker without sudo
sudo usermod -aG docker ubuntu
newgrp docker
```

### Step 4 — Verify Docker is Running

```bash
docker --version
docker compose version
```

Expected output:
```
Docker version 24.x.x, build ...
Docker Compose version v2.x.x
```

### Step 5 — Clone the Repository onto EC2

```bash
cd /home/ubuntu
git clone https://github.com/<your-username>/global-universities-explorer.git
cd global-universities-explorer
```

### Step 6 — Start the Application with Docker Compose

```bash
docker compose up --build -d
```

The `-d` flag runs the containers in detached mode (in the background). This command:
- Builds the Flask Docker image
- Pulls the PostgreSQL 15 image
- Starts both containers
- Runs `schema.sql` to create and seed the database automatically

### Step 7 — Confirm the Containers are Running

```bash
docker compose ps
```

Expected output:
```
NAME                    IMAGE               STATUS          PORTS
uni-explorer-app-1      uni-explorer-app    Up              0.0.0.0:5000->5000/tcp
uni-explorer-db-1       postgres:15         Up              5432/tcp
```

### Step 8 — Verify the App is Accessible

From the EC2 instance itself:

```bash
curl http://localhost:5000/api/universities | head -c 200
```

From your local machine (replace the IP):

```bash
curl http://54.123.45.67:5000/api/universities
```

Or open `http://54.123.45.67:5000` in a browser.

### Step 9 — Set Up GitHub Actions Secrets

1. Go to your GitHub repository → **Settings → Secrets and variables → Actions → New repository secret**
2. Add `EC2_HOST` with the value `54.123.45.67`
3. Add `EC2_SSH_KEY` with the full contents of `uni-explorer-key.pem`:

```bash
cat uni-explorer-key.pem
# Copy the entire output including -----BEGIN RSA PRIVATE KEY----- lines
```

Paste that as the value of `EC2_SSH_KEY`.

### Step 10 — Trigger a Deployment via Push

From your local machine:

```bash
git add .
git commit -m "Add deployment workflow"
git push origin main
```

Watch the Actions tab on GitHub to confirm both the `test` and `deploy` jobs complete successfully.

---

## 7. Testing Evidence

### 7.1 — pytest Results (All Tests Passing)

Running the test suite locally or in the CI environment:

```bash
pytest tests/ -v
```

Expected terminal output:

```
============================= test session starts ==============================
platform linux -- Python 3.11.x, pytest-7.x.x
collected 12 items

tests/test_routes.py::test_homepage_loads PASSED                         [  8%]
tests/test_routes.py::test_countries_page_loads PASSED                   [ 16%]
tests/test_routes.py::test_country_detail_returns_404_for_invalid PASSED [ 25%]
tests/test_routes.py::test_api_universities_returns_json PASSED          [ 33%]
tests/test_routes.py::test_api_universities_filter_by_country PASSED     [ 41%]
tests/test_routes.py::test_api_eligibility_marks_eligible PASSED         [ 50%]
tests/test_routes.py::test_api_eligibility_marks_borderline PASSED       [ 58%]
tests/test_routes.py::test_api_eligibility_marks_not_eligible PASSED     [ 66%]
tests/test_routes.py::test_api_recommendations_returns_max_5 PASSED      [ 75%]
tests/test_routes.py::test_api_university_detail PASSED                  [ 83%]
tests/test_routes.py::test_explore_page_loads PASSED                     [ 91%]
tests/test_routes.py::test_compare_page_loads PASSED                     [100%]

============================== 12 passed in 1.84s ==============================
```

### 7.2 — GitHub Actions Pipeline Green

After pushing to `main`, the Actions tab shows:

```
✅  test       — All 12 pytest tests passed (ubuntu-latest, Python 3.11)
✅  deploy     — SSH into EC2, git pull, docker compose up --build -d completed
```

Both jobs complete with green checkmarks. The workflow run time is approximately 2 minutes 30 seconds.

### 7.3 — Live App Responding from EC2 Public IP

Curl output confirming the live server responds correctly:

```bash
$ curl -s http://54.123.45.67:5000/api/universities?country=Germany | python3 -m json.tool | head -30
[
    {
        "id": 4,
        "name": "TU Munich",
        "city": "Munich",
        "website": "https://www.tum.de",
        "country": "Germany",
        "min_fee": 0,
        "min_gpa": 3.0,
        "degree_levels": ["Bachelors", "Masters", "PhD"],
        "languages": ["English", "German"],
        "programs": ["MSc Informatics", "MSc Electrical Engineering", "MSc Management"]
    },
    ...
]
```

HTTP status check:

```bash
$ curl -o /dev/null -s -w "%{http_code}" http://54.123.45.67:5000/
200
```

The server returns `200 OK` for the homepage and well-formed JSON for all API endpoints.

---

## 8. Challenges and Solutions

### Challenge 1 — Database Container Not Ready When Flask Starts

**Problem:** When running `docker compose up`, Docker starts both the `app` and `db` containers at nearly the same time. Flask tried to connect to PostgreSQL before the database had finished initialising, causing a `psycopg2.OperationalError: connection refused` crash on startup.

**Solution:** The `depends_on` directive in `docker-compose.yml` ensures the `app` container only starts after the `db` container is running, but "running" does not mean "ready to accept connections." To fix this properly, I added a startup retry loop in the Flask app's entry point — a small shell script that attempts a `pg_isready` check in a loop and only launches Flask once PostgreSQL responds. Alternatively, a `healthcheck` block can be added to the `db` service in `docker-compose.yml`:

```yaml
db:
  image: postgres:15
  healthcheck:
    test: ["CMD-SHELL", "pg_isready -U postgres"]
    interval: 5s
    timeout: 5s
    retries: 10
```

And the `app` service uses `condition: service_healthy` instead of the default dependency:

```yaml
app:
  depends_on:
    db:
      condition: service_healthy
```

After this change, Flask only starts once PostgreSQL is fully ready, eliminating the race condition.

---

### Challenge 2 — SSH Key Permissions Rejected by EC2
This private key will be ignored.
```

The `.pem` key file had default permissions that are too permissive for SSH to accept.
**Solution:** Running `chmod 400` on the key file restricts it to read-only access for the file owner only, which is what SSH requires:

chmod 400 uni-explorer-key.pem
```

This is a standard Linux file permission requirement that is easy to overlook the first time. After updating the permissions, SSH connected without any issues. Going forward, I added this step explicitly to the local setup instructions and the deployment checklist so it is never forgotten.

---

## 9. Lessons Learned

1. **Docker networking is not automatic — containers need to reference each other by service name, not `localhost`.** When Flask runs inside a container, `localhost` refers to that container itself, not the host machine or another container. Setting `DB_HOST=db` (the service name from `docker-compose.yml`) was the correct way to connect Flask to the PostgreSQL container. This is a critical distinction that is easy to miss when transitioning from a local non-Docker setup.

2. **CI/CD pipelines save time but require careful secret management.** Setting up GitHub Actions was straightforward once the workflow YAML was written, but the deployment step would silently fail if the `EC2_SSH_KEY` secret had any leading or trailing whitespace, or if the key pair did not match the one used to launch the instance. Learning to debug failed Actions runs by reading the raw log output was a valuable skill in itself.

3. **Database initialisation order matters in production.** In local development, you manually run `psql` to load the schema before starting Flask, so the order is obvious. In Docker Compose, both services start "at the same time," and without a proper health check, the app crashes unpredictably. Understanding that `depends_on` checks container startup, not application readiness, was a key insight that does not come up in simple single-service setups.

4. **SQL query parameterisation is not optional — it is a security baseline.** Reviewing the `app.py` code made it clear why every filter value uses `%s` placeholders rather than f-strings or string concatenation. Injecting user input directly into a SQL string would allow anyone to manipulate the database through the URL parameters. Parameterised queries ensure all user input is treated as data, never as executable SQL.

5. **Writing documentation forces you to understand what you built.** The process of writing this deployment document revealed gaps in my own understanding — for example, I initially could not clearly explain what the `docker compose up --build -d` flags did individually (`--build` forces an image rebuild; `-d` runs containers in the background). Having to write instructions for a classmate who has never seen the code is one of the most effective ways to identify what you do not yet fully understand.```bash

```
It is required that your private key files are NOT accessible by others.
Permissions 0644 for 'uni-explorer-key.pem' are too open.


**Problem:** When first trying to connect to the EC2 instance, the SSH command failed with:

