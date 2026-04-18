# Teacher App

Offline-first **Flutter** app for lesson planning, courses, guidance, and related teaching workflows.  
Data stays on the device (**Hive**) by default. **Supabase** cloud sync is **optional** and only activates when you pass URL and anon key at build/run time.

## Tech stack

- **Flutter** — Android, Windows, Web, and other supported targets  
- **Hive** — local-first storage  
- **Supabase** (optional) — account sync via `--dart-define` (nothing secret is committed)  
- **Docker** (optional) — serve the production web build with nginx  

## Prerequisites

| Requirement | Details |
|---------------|---------|
| **Git** | To clone the repository. |
| **Flutter SDK** | Dart **3.10.8+** (see `environment.sdk` in `pubspec.yaml`). Install via [Flutter install](https://docs.flutter.dev/get-started/install). |
| **IDE (optional)** | VS Code or Android Studio with Flutter/Dart plugins. |
| **Platform tools (optional)** | Android SDK / Xcode / Visual Studio workload only if you build for that platform. Run `flutter doctor` and fix what it reports. |
| **Node.js** | Not used. |
| **Docker** | Only for the [Docker](#docker-flutter-web) section. |

## Repository layout

```text
android/ ios/ linux/ macos/ windows/ web/   # platform runners
lib/                                       # application code
docs/                                      # Supabase SQL & setup
docker/                                    # web image (Flutter build + nginx)
run/                                       # helper scripts (Windows / APK)
scripts/                                   # optional GitHub bootstrap
```

## Quick start (copy-paste)

Replace the clone URL with **your** fork or the upstream repo URL. After `git clone`, the project folder name is **whatever the repository is named on GitHub** (this repo is usually cloned as `teacher_app`).

```bash
git clone https://github.com/<YOUR_USERNAME_OR_ORG>/teacher_app.git
cd teacher_app

flutter pub get
flutter doctor
```

Run the app (pick a device from `flutter devices`):

```bash
flutter run -d windows    # example: Windows desktop
# or
flutter run -d chrome     # example: web in Chrome
```

**Windows helper** (from repo root — sets the correct project directory):

```powershell
.\run\run_windows.ps1
```

### Works without Supabase

You do **not** need Supabase for daily use. The app runs locally; sync features in Settings stay inactive until credentials are provided via `--dart-define`.

### Optional: Supabase sync

1. Create a project and run the SQL in `docs/supabase_sync_schema.sql` (see `docs/supabase_sync_setup.md`).  
2. Pass keys only at **build/run** time (not via a committed `.env` file—Flutter does **not** load `.env` automatically):

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

3. **`.env.example`** is a human-readable checklist. You may copy it to `.env` for your own notes or shell exports; the Flutter tool still needs `--dart-define` (or your CI must inject the same values).

## Build

### Web

```bash
flutter build web --release
```

Output: `build/web/` (static files ready to host).

### Android APK

- **With optional sync (helper script)** — set variables, then:

```powershell
$env:SUPABASE_URL="https://YOUR_PROJECT.supabase.co"
$env:SUPABASE_ANON_KEY="YOUR_ANON_KEY"
.\run\run_apk.ps1
```

- **Without Supabase** — use the standard Flutter command (no `--dart-define` required):

```bash
flutter build apk --release
```

## Docker (Flutter Web)

Run from the **repository root** (downloads base images on first build):

```bash
docker build -f docker/Dockerfile -t teacher-planner-web .
docker run --rm -p 8080:80 teacher-planner-web
```

Open [http://localhost:8080](http://localhost:8080). Nginx serves the built `web` bundle with SPA routing support.

## Git workflow

```bash
git add -A
git status
git commit -m "chore: your message"
git push origin main
```

If `origin` is missing and you use a GitHub **personal access token** with `repo` scope:

```bash
export GITHUB_TOKEN=ghp_your_token
bash scripts/github_repo_bootstrap.sh
```

Otherwise add `origin` manually and push to `main`.

## Deployment

- **Web:** upload `build/web` to any static host (S3, nginx, GitHub Pages, etc.).  
- **Stores:** use your signing keys and store pipelines; do not commit keystores (see `.gitignore`).

## CI/CD

No hosted CI is mandatory; you can add GitHub Actions or similar. Suggested checks: `flutter analyze`, `flutter test`, `flutter build web`.

## Security

- Do not commit real Supabase keys. Use `--dart-define` or CI secrets.  
- Do not commit `.env` with secrets; it is listed in `.gitignore`.

## Verified setup

These steps match the **declared** SDK and layout in this repo (`pubspec.yaml`, Flutter tooling). A successful run depends on your machine: always run `flutter doctor` after install and resolve **platform** issues (Android licenses, Windows desktop enablement, Chrome for web, etc.). The maintainers verify `flutter pub get` and `flutter build web --release` against this configuration before releases.

## License / contributions

## ⚠️ License & Usage

This project is source-available for educational and portfolio purposes only.

You are NOT allowed to:
- Use this project for commercial purposes
- Modify and redistribute this project
- Sell or sublicense any part of this codebase

Permission is required for:
- Commercial use
- Production deployment
- Custom implementations

For licensing or usage inquiries:

👉 Contact me

---

**Flutter install:** [docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install)
