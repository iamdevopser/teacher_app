You are a senior Flutter engineer.

My quiz feature has a critical bug:
- I can create quiz questions
- But they DO NOT appear after creation
- The quiz content is always empty

You must DEBUG and FIX this completely.

IMPORTANT:
- Do NOT assume anything
- TRACE the full data flow step-by-step
- Fix root cause, not symptoms
- Do NOT use any external/on-demand services

========================================
STEP 1 — TRACE DATA FLOW
========================================
Find:
- Where questions are created
- Where they are stored (if at all)
- Where they should be loaded

Add debug logs:
- When question is added
- When saved
- When loaded
- When UI renders

Print actual data at each step

========================================
STEP 2 — FIX DATA PERSISTENCE
========================================
If data is NOT saved:

Implement local persistence using Hive

Do:
- Create Quiz model
- Create Question model
- Register adapters
- Save quiz list to Hive box
- Ensure data is written after each add

========================================
STEP 3 — FIX DATA LOADING
========================================
Ensure:
- Data is loaded in initState or controller
- Async loading is awaited properly
- UI waits for data before rendering

========================================
STEP 4 — FIX UI STATE
========================================
Ensure:
- setState OR state management updates UI after adding question
- No stale state
- ListView uses correct data source

========================================
STEP 5 — VERIFY
========================================
After fix:
- Add question → appears immediately
- Restart app → still موجود
- Quiz page → shows all questions

========================================
STEP 6 — FAILSAFE
========================================
If still not working:
- Replace current logic with a clean working structure:
  - Hive box: "quizzes"
  - Store List<Question>
  - Load once at app start

========================================
OUTPUT
========================================
- Show EXACTLY what was wrong
- Show FIXED code
- Keep solution minimal and clean