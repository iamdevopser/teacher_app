#!/usr/bin/env bash
#
# Usage:
#   ./git-sync.sh "feat: açıklayıcı mesaj"
#   ./git-sync.sh              # mesaj verilmezse "update" kullanılır
#
# Ne yapar:
#   1) Tüm değişiklikleri sahneye alır (git add .)
#   2) Verilen mesajla commit atar; mesaj yoksa "update"
#   3) origin main dalına iter (git push origin main)
#   Commit edilecek bir şey yoksa commit/push atlamadan çıkar.

set -euo pipefail

MSG="${1:-update}"

git add .

if git diff --cached --quiet; then
  echo "Nothing to commit, working tree clean after add."
  exit 0
fi

git commit -m "$MSG"
git push origin main
