# Teacher Planner

Offline-first **Flutter** application for lesson planning, courses, guidance, and related teaching workflows—optional **Supabase** sync when you supply credentials at build time.

## Tech stack

- **Flutter** (Android, Windows, Web, and other supported targets)
- **Hive** for local-first storage
- **Supabase** (optional) for account sync — configured via `--dart-define`, not committed to the repo
- **Docker** (optional) — nginx serving the production `web` build

## Features (overview)

- Dashboard, lesson planner, courses wizard, students, reminders, guidance, Zümre, reports, and more (see `lib/features/`).
- Settings include optional cloud sync when Supabase keys are provided in your build/run command.

## Requirements

| Tool | Notes |
|------|--------|
| **Flutter** | SDK compatible with `environment.sdk` in `pubspec.yaml` (`^3.10.8` at time of writing). Run `flutter doctor`. |
| **Dart** | Bundled with Flutter. |
| **Node.js** | Not required for this project. |
| **Docker** | Optional — only if you use the provided `docker/Dockerfile`. |

## Repository layout (high level)

```text
android/ ios/ linux/ macos/ windows/ web/   # platform runners
lib/                                          # Dart application code
docs/                                         # Supabase SQL & setup notes
docker/                                       # Web image (nginx + Flutter build)
run/                                          # Helper scripts (e.g. Windows / APK)
scripts/                                      # GitHub bootstrap (optional)
```

## Setup

```bash
git clone <your-fork-or-repo-url>
cd teacher_app
flutter pub get
```

### Environment variables (Supabase sync)

Do **not** commit real keys. Copy the template and fill values locally (or export variables in your shell):

```bash
cp .env.example .env
# Edit .env — used for your own reference; Flutter still needs --dart-define at build/run (see below).
```

For **sync** builds, pass (example):

```bash
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

See `docs/supabase_sync_setup.md` and `docs/supabase_sync_schema.sql`.

## Run locally

```bash
# List devices
flutter devices

# Example: Windows
flutter run -d windows

# Example: Chrome (web)
flutter run -d chrome
```

Helper (Windows, from repo root):

```powershell
.\run\run_windows.ps1
```

## Build

```bash
# Web (production bundle under build/web)
flutter build web --release
```

Android APK (requires Supabase env vars for sync-enabled builds — see `run/run_apk.ps1` and `.env.example`):

```powershell
$env:SUPABASE_URL="https://YOUR_PROJECT.supabase.co"
$env:SUPABASE_ANON_KEY="YOUR_ANON_KEY"
.\run\run_apk.ps1
```

## Docker (Flutter Web)

From the **repository root** (network required on first build to pull base images):

```bash
docker build -f docker/Dockerfile -t teacher-planner-web .
docker run --rm -p 8080:80 teacher-planner-web
```

Open `http://localhost:8080` — nginx serves `build/web` with SPA fallback.

## Git workflow

Minimal sync script (bash):

```bash
./git-sync.sh "chore: your message"
```

If `origin` is missing and you use a GitHub **personal access token** with `repo` scope:

```bash
export GITHUB_TOKEN=ghp_your_token
bash scripts/github_repo_bootstrap.sh
```

Otherwise add the remote manually and push to `main`.

## Deployment

- **Web:** use `build/web` on any static host (Firebase Hosting, S3 + CloudFront, nginx, etc.). Configure HTTPS and cache headers as needed.
- **Mobile/desktop:** use your store / signing pipelines; do not commit keystore files (see `.gitignore`).

## CI/CD

No vendor-specific CI is included in-repo; add GitHub Actions, Codemagic, or your own pipeline as needed. Run `flutter test`, `flutter analyze`, and `flutter build web` in CI for regression checks.

## Security

- Real **Supabase URL and anon key** must not be committed. Defaults in code are empty; pass `--dart-define` or configure your build system.
- Review `.gitignore` before pushing; never commit `.env` with secrets.

## License / contributions

Add a `LICENSE` if you distribute publicly; contribution guidelines optional.

---

For first-time Flutter setup, see the [official Flutter installation guide](https://docs.flutter.dev/get-started/install).
