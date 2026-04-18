You are a senior DevOps engineer. Fully prepare this Flutter Web project for a clean, production-ready GitHub repository and handle everything end-to-end with ZERO manual steps.

IMPORTANT CONSTRAINTS:
- Do NOT use any external/on-demand/paid services
- Work only locally with system tools (git, bash, flutter, docker if present)
- Everything must be automated

========================
STEP 1 — PROJECT ANALYSIS
========================
- Scan the entire project
- Identify:
  - Sensitive files (.env, API keys, credentials, private configs)
  - Unnecessary files (build/, .dart_tool/, .cache, logs, temp files)
  - OS/system files (.DS_Store, etc.)

========================
STEP 2 — CLEANUP & SAFETY
========================
- Create/update .gitignore using Flutter best practices
- Ensure ALL sensitive/unnecessary files are excluded
- If sensitive files exist:
  - Remove them from tracking
  - Create safe template versions:
    .env.example or config.example.json
  - Replace real values with placeholders

========================
STEP 3 — PROJECT VALIDATION
========================
- Ensure the project is runnable from scratch:
  - Run: flutter pub get
  - Run: flutter build web
- If something breaks:
  - Fix dependencies or config
- Guarantee a fresh clone can run successfully

========================
STEP 4 — OPTIONAL DOCKER (if not exists, create it)
========================
- Create a minimal Dockerfile for Flutter Web:
  - Use nginx to serve build/web
- Ensure container runs correctly

========================
STEP 5 — README (PROFESSIONAL & COMPLETE)
========================
Create a HIGH-QUALITY README.md including:

1. Project title + short impactful description
2. Tech stack (Flutter Web, Docker, CI/CD if exists)
3. Features (brief)
4. Requirements:
   - Flutter version
   - Node (if needed)
   - Docker (optional)
5. Setup (step-by-step):
   - git clone
   - flutter pub get
6. Run locally
7. Build instructions
8. Docker usage (if exists)
9. Deployment note (CI/CD if exists)
10. Environment variables:
    - Explain .env usage
    - Show how to copy:
      cp .env.example .env
11. Clean folder structure overview
12. Keep it concise but professional

========================
STEP 6 — GIT PREPARATION
========================
- Initialize git if not exists
- Ensure branch is "main"
- Add only valid files (respect .gitignore)
- Create a clean commit:
  "chore: production-ready clean repo setup"

========================
STEP 7 — GITHUB HANDLING
========================
IF remote exists:
  - Push to origin main

IF NO remote exists:
  - Create a GitHub repo using GITHUB_TOKEN env variable
  - Repo name = current folder name
  - Set private = false
  - Add remote origin
  - Push to main

========================
STEP 8 — FINAL CHECK
========================
- Verify:
  - Repo is clean
  - No sensitive data leaked
  - Project builds successfully
  - README is complete
  - GitHub repo is accessible

========================
STEP 9 — OUTPUT
========================
- Show:
  - What was removed
  - What was added
  - Repo URL
- Keep explanation short

GOAL:
Produce a clean, minimal, production-ready, shareable GitHub repository that anyone can clone and run immediately.