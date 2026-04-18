Create a simple, minimal script for this project to automate Git commits and pushes.

Requirements:
- Assume the project may already be a Git repo and connected to GitHub
- Create a script named "git-sync.sh"
- The script should:
  1. Add all changes (git add .)
  2. Create a commit with a message passed as an argument
     - If no message is provided, use a default message like "update"
  3. Push to the main branch (git push origin main)

- Make the script executable
- Keep it clean and minimal (no over-engineering)
- Add a short usage example at the top of the script

Optional:
- Handle basic errors (e.g., no changes to commit)

Explain briefly what each part does.