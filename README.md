# DevOps Intern Task – Containerized Node.js Application

![CI Pipeline](https://github.com/cyraxabir/nodejs-sample/actions/workflows/ci.yml/badge.svg)

A minimal, production-ready Node.js web application with Docker containerization, GitHub Actions CI/CD, and Linux automation scripting.

---

## 📁 Repository Structure

```
.
├── .github/
│   └── workflows/
│       └── ci.yml              # GitHub Actions CI pipeline
├── scripts/
│   └── system_health.sh        # Linux health-check automation script
├── src/
│   ├── server.js               # Express application entry point
│   └── server.test.js          # Unit tests (Node.js built-in test runner)
├── .dockerignore               # Files excluded from Docker build context
├── .eslintrc.json              # ESLint configuration
├── .gitignore
├── Dockerfile                  # Multi-stage production Dockerfile
├── docker-compose.yml          # Local orchestration (port 8080)
├── package.json
└── README.md                   # ← You are here
```

---

## 🚀 Quick Start

### Prerequisites

| Tool            | Minimum Version |
|-----------------|-----------------|
| Docker          | 20.10+          |
| Docker Compose  | 2.0+            |
| Node.js (local) | 20 LTS          |

### Run with Docker Compose

```bash
# Clone the repository
git clone https://github.com/cyraxabir/nodejs-sample.git
cd nodejs-sample

# Build and start the container
docker-compose up --build -d

# Verify it's running
curl http://localhost:8080/
```

**Expected response:**

```json
{
  "message": "Hello from DevOps Intern Task!",
  "status": "running"
}
```

**Stop the container:**

```bash
docker-compose down
```

### Run Locally (without Docker)

```bash
npm install
npm start
# → Server is running on port 8080
```

---

## 🐳 Docker Details

### Dockerfile Best Practices Applied

| Practice | Implementation |
|----------|---------------|
| **Lightweight base image** | `node:20-alpine` (~50 MB) |
| **Multi-stage build** | Stage 1 installs deps → Stage 2 copies only production artifacts |
| **Non-root user** | Runs as `appuser` (not root) |
| **Proper signal handling** | Uses `dumb-init` as PID 1 |
| **Layer caching** | `package.json` copied before source for optimal cache |
| **Health check** | Built-in `HEALTHCHECK` instruction |
| **Minimal context** | `.dockerignore` excludes tests, docs, git history |

### Build Manually

```bash
docker build -t devops-intern-task .
docker run -p 8080:8080 devops-intern-task
```

---

## ⚙️ CI/CD Pipeline (GitHub Actions)

The pipeline (`.github/workflows/ci.yml`) triggers on every **push to `main`** and on **pull requests**.

### Pipeline Stages

```
┌─────────────┐     ┌──────────────────┐     ┌───────────────────┐
│  Code Push   │────▶│  Lint & Test      │────▶│  Build & Push     │
│  (main)      │     │  • npm ci         │     │  Docker Image     │
│              │     │  • ESLint         │     │  • Buildx         │
│              │     │  • Unit tests     │     │  • Push to Hub    │
└─────────────┘     └──────────────────┘     └───────────────────┘
```

### End-to-End Workflow Diagram

```
  Developer          GitHub               Docker Hub              VPS (AWS EC2)
  ─────────          ──────               ──────────              ─────────────
      │                  │                     │                       │
      │  git push main   │                     │                       │
      │─────────────────▶│                     │                       │
      │                  │                     │                       │
      │                  │  ┌───────────────┐  │                       │
      │                  │  │ CI Pipeline    │  │                       │
      │                  │  │               │  │                       │
      │                  │  │ 1. Checkout   │  │                       │
      │                  │  │ 2. Lint       │  │                       │
      │                  │  │ 3. Test       │  │                       │
      │                  │  │ 4. Build img  │  │                       │
      │                  │  └───────┬───────┘  │                       │
      │                  │          │          │                       │
      │                  │          │ push     │                       │
      │                  │          ├─────────▶│                       │
      │                  │          │          │  user/devops-intern   │
      │                  │          │          │  :latest, :sha-abc123 │
      │                  │          │          │                       │
      │                  │          │          │   docker pull         │
      │                  │          │          │◀──────────────────────│
      │                  │          │          │                       │
      │                  │          │          │   docker run -p 80:8080
      │                  │          │          │   ──────────────────▶ │
      │                  │          │          │                       │
      │  ✅ Pipeline      │          │          │        🟢 LIVE        │
      │◀─────────────────│          │          │                       │
```

### Setup Required Secrets

Before the pipeline can push images, add these **repository secrets** in GitHub (Settings → Secrets → Actions):

| Secret | Description |
|--------|-------------|
| `DOCKERHUB_USERNAME` | Your Docker Hub username |
| `DOCKERHUB_TOKEN` | Docker Hub access token ([create one here](https://hub.docker.com/settings/security)) |

---

## 🖥️ Linux Automation – `system_health.sh`

A Bash script that collects **CPU**, **Memory**, and **Disk** metrics and logs them to `health_log.txt`.

### How to Run

```bash
# Make executable
chmod +x scripts/system_health.sh

# Run it
./scripts/system_health.sh
```

### Sample Output

```
[2026-11-07 15:00:01]  CPU: 12.3%  |  Memory: 45.2% (1843MB / 4076MB)  |  Disk: 7.2G used of 20G (36%)
```

If disk usage exceeds **80%**, it appends a warning:

```
[2026-11-07 15:00:01]  CPU: 12.3%  |  Memory: 45.2% (1843MB / 4076MB)  |  Disk: 17G used of 20G (85%)  [WARNING] Disk space high!
```

### Automate with Cron (every 5 minutes)

```bash
crontab -e
# Add the following line:
*/5 * * * * /absolute/path/to/scripts/system_health.sh
```

---

## ☁️ Deploying to AWS (EC2 / VPS)

Here's how you would deploy this container to an AWS EC2 instance:

1. **Provision & prepare the server** – Launch an EC2 instance (e.g., `t3.micro` with Amazon Linux 2023 or Ubuntu 22.04). Open inbound ports **22 (SSH)** and **80/443 (HTTP/S)** in the security group. SSH in and install Docker + Docker Compose:
   ```bash
   sudo yum install -y docker        # Amazon Linux
   sudo systemctl enable --now docker
   sudo usermod -aG docker ec2-user
   ```

2. **Pull and run the image from Docker Hub** – Since the CI pipeline pushes the image to Docker Hub on every merge to `main`, deploying is a single command:
   ```bash
   docker pull cyrax001/devops-intern-task:latest
   docker run -d --name app --restart unless-stopped -p 80:8080 \
     cyrax001/devops-intern-task:latest
   ```

3. **Automate future deployments** – Add a **deployment job** to the GitHub Actions workflow that SSHs into the EC2 instance (using a stored SSH key in GitHub Secrets) and runs `docker pull && docker restart`. Alternatively, use **AWS ECS / Fargate** for a fully managed solution with auto-scaling, health checks, and zero-downtime rolling updates—no SSH required.

---

## 📝 License

MIT
