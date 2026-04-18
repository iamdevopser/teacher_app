You are a senior DevOps engineer.

Your task is to prepare this Flutter Web project for multi-platform CI/CD support WITHOUT using any external or on-demand services.

IMPORTANT:
- Do NOT trigger any pipelines
- Do NOT connect to external services
- ONLY generate configuration files and local project structure
- Keep everything production-ready but minimal

========================
GOAL
========================
Make this project ready to run CI/CD on multiple platforms:

- GitHub Actions
- GitLab CI/CD
- Bitbucket Pipelines
- Jenkins

========================
STEP 1 — ANALYZE PROJECT
========================
- Detect Flutter project structure
- Ensure commands:
  - flutter pub get
  - flutter build web --release
  are valid

========================
STEP 2 — CREATE CI/CD FILES
========================

1. GitHub Actions:
Create:
.github/workflows/flutter-ci.yml

Include:
- checkout
- setup flutter
- flutter pub get
- flutter build web --release

---

2. GitLab:
Create:
.gitlab-ci.yml

Include:
- flutter docker image
- build stage
- build web command

---

3. Bitbucket:
Create:
bitbucket-pipelines.yml

Include:
- flutter docker image
- build step

---

4. Jenkins:
Create:
Jenkinsfile

Include:
- pipeline
- build stage
- flutter commands

========================
STEP 3 — DOCKER CONSISTENCY
========================
- Ensure Dockerfile exists
- If missing, create a minimal one:
  - nginx
  - serve build/web

========================
STEP 4 — STANDARDIZE COMMANDS
========================
All pipelines must use the SAME commands:

- flutter pub get
- flutter build web --release

No platform-specific hacks.

========================
STEP 5 — ADD COMMENTS
========================
In each file:
- Add short comments explaining steps
- Keep clean and readable

========================
STEP 6 — README UPDATE
========================
Update README.md:

- Add "CI/CD Options" section
- List supported platforms
- Explain that configs are ready
- Do NOT add long explanations

========================
STEP 7 — FINAL CHECK
========================
- Ensure files are in correct paths
- No syntax errors
- Clean formatting

========================
OUTPUT
========================
- List all created files
- Brief explanation of each