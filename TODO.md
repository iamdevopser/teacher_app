# Teacher Planner - Future Upgrades

## High Priority

- [ ] **Local notifications** for reminders (flutter_local_notifications is added but not wired)
- [ ] **Optional app lock** (PIN or biometrics) for privacy
- [ ] **Excel export** for reports (optional per master_prompt)

## Medium Priority

- [ ] **RTL layout support** (currently LTR; prepare for future RTL languages)
- [ ] **Date/time locale formatting** (use intl DateFormat with locale)
- [ ] **Backup/restore** - export all data to file, import from file
- [ ] **Student absence count** - automatic tally per student

## Nice to Have

- [ ] **Dark mode toggle** in settings (currently follows system)
- [ ] **Lesson templates** - save common lesson structures
- [ ] **Widget for home screen** - today's lessons at a glance
- [ ] **Search** across lessons, students, notes

## Technical Debt

- [ ] Remove unused dependencies (e.g. timezone if notifications not used)
- [ ] Add unit tests for repositories
- [ ] Add widget tests for critical screens
