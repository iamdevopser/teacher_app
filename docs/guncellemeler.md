You are a senior Flutter engineer.

Fix the following two critical issues in my Flutter project WITHOUT using any external/on-demand services.

====================================
ISSUE 1 — TEXT DIRECTION BUG
====================================
Problem:
- When typing manually into TextField/TextFormField, text is written right-to-left (RTL)
- But copy-paste works correctly

Fix:
- Force ALL input fields to use LTR (left-to-right)
- Apply globally if possible

Do:
- Wrap app with Directionality(textDirection: TextDirection.ltr)
OR
- Set textDirection: TextDirection.ltr in all TextField/TextFormField
- Ensure keyboard input behaves correctly

====================================
ISSUE 2 — QUIZ DATA NOT PERSISTING
====================================
Problem:
- Quiz questions are created
- But not visible after creation
- Data is not being saved or loaded correctly

Fix:
1. Identify where quiz data is stored (likely missing)
2. Implement LOCAL persistence (NO backend)

Use:
- Hive OR shared_preferences (prefer Hive if structure is complex)

Do:
- Create Quiz model
- Save questions locally when added
- Load questions when screen opens
- Ensure state updates UI immediately

====================================
EXPECTED RESULT
====================================
- Text inputs always LTR
- Quiz questions persist after app restart
- Quiz list renders correctly
- No empty state after adding questions

====================================
OUTPUT
====================================
- Show modified code files
- Explain briefly what was fixed