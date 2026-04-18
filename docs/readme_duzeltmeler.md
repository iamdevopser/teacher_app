You are a senior DevOps engineer and technical writer.

Your task is to analyze and FIX the current README.md to make it production-ready, beginner-proof, and error-free.

GOAL:
Anyone should be able to clone the repo and run the project WITHOUT confusion or errors.

========================
STEP 1 — FIND RISKS
========================
Analyze README.md and detect all potential issues, including:

- Incorrect or hardcoded folder names (e.g. cd teacher_app mismatch)
- Missing or unclear setup steps
- Ambiguous instructions
- Missing prerequisites (Flutter version, tools)
- Environment variable confusion (.env usage unclear)
- Commands that may fail in real usage
- Missing explanations for optional features (e.g. Supabase)

========================
STEP 2 — FIX EVERYTHING
========================
Rewrite README.md with the following improvements:

1. Correct ALL folder paths dynamically (use repo name or explain clearly)
2. Add clear prerequisites:
   - Flutter version
   - Required tools
3. Make setup steps copy-paste safe:
   - git clone
   - cd <repo-name>
   - flutter pub get

4. Clarify environment variables:
   - Explain that the app works without Supabase by default
   - Show optional usage with --dart-define
   - Keep .env.example as reference only

5. Ensure ALL commands are correct and runnable

6. Add a "Verified Setup" section:
   - Confirm tested on a clean environment

7. Improve clarity and flow:
   - Short sentences
   - No ambiguity
   - Beginner-friendly but professional

8. Keep it clean and minimal (no unnecessary text)

========================
STEP 3 — OUTPUT
========================
- Return the FULL corrected README.md
- Also list briefly what was fixed and why

IMPORTANT:
- Do NOT remove useful content
- Only improve, clarify, and fix
- Keep a professional DevOps tone