# Kulay Reading Lab in Kodigno — Design Spec

Date: 2026-10-09

## 1. Purpose

Bring Kulay, the local AI reading lab, into Kodigno as its Kulay tab. A local AI writes English stories at the reader's color level (8 colors, Grades 1 to 12), asks questions about them, shows the proof sentence when an answer is wrong, and moves the reader up or down a color. Kulay already works as a separate web app (`AppBuilders/kulay`, Node + Ollama); this spec ports it into Kodigno.

Decisions from brainstorming:
- **Both modes:** personal ("Just me") and classroom ("A class": many readers take turns on one device, plus a teacher view).
- **Fully offline:** no Wi-Fi, no phones on a classroom network. The only internet step is Kodigno's one-time model download.
- **Hardware:** whatever Kodigno targets (the existing Basic / Standard / High tiers). Slow stories on weak PCs are accepted.
- **Milestone:** full parity with the web app in one go.
- **Approach:** a Dart module inside Kodigno (port, not shared code). The web app stays separate as the hackathon entry.

### Parity checklist (success criteria)
1. Placement check (4 fixed passages) gives a new reader a starting color.
2. Topic picker: 16 topics or a typed topic.
3. AI story at the reader's color, with the 8-step pipeline and both checks, shown step by step while it is written.
4. Questions; a wrong answer highlights the proof sentence.
5. Move up at 80%+ on 3 stories in a row at the current color; move down below 60% on 2 in a row.
6. Background next story, so the next one is usually ready.
7. Tap a word for its meaning in that sentence, with "Hear it".
8. Listen to the story, one sentence at a time, with the sentence highlighted.
9. Teacher view: class table, skill report (details, cause and effect, feelings, word meaning), the skill to teach next, what each reader needs to work on, set a reader's color, delete a reader.
10. All of the above with Wi-Fi off.

### Out of scope
CSV export, syncing between devices, phones joining over Wi-Fi, accounts, cloud AI.

## 2. Architecture and boundaries

New code lives in one folder:

```
lib/reading/
  levels.dart             8 colors, topics, placement passages, move-up/down rule   (from levels.js)
  nlp.dart                story checks, answer grounding, wrong choices            (from nlp.js)
  story_engine.dart       the 8-step pipeline on Kodigno's LlmRuntime              (from ai.js)
  reading_controller.dart readers, current screen, current story, background next story (ChangeNotifier)
  reading_repository.dart drift reads/writes for readers, stories, attempts
  ui/                     reader picker, reader page, placement, writing, story + quiz, result, teacher view
assets/starter_stories.json  24 checked stories, 3 per color
```

### Changes to shared Kodigno files

| File | Change |
|---|---|
| `lib/ui/kulay.dart` | JIM's full-screen `KulayScreen` (opened by the color burst) shows the reading app: the welcome and reader picker beside his shelves, then the reading pages inside the same white card. His icon, burst, shelves and back pill are unchanged. |
| `lib/ai/ai_engine.dart` | `LlmRuntime.chat` gets optional `temperature` and `schema`. `LlamaServerRuntime` already has both; `test/helpers/fake_llm_runtime.dart` gets the new signature. These are the only two implementers. |
| `lib/app_controller.dart` | One method that returns the current tier's `LlmRuntime`, so Kulay shares the running model server. |
| `lib/data/database.dart` | 3 new tables; `schemaVersion` 1 → 2 with a migration. |
| `lib/main.dart` | Provide `ReadingController` with `provider`; load starter stories; stop background writing on exit. |
| `pubspec.yaml` | Add the starter stories asset. No new packages. |
| `test/ui/kulay_test.dart` | The back-button test moved to `test/reading/kulay_ui_test.dart`, since `KulayScreen` now needs a `ReadingController`. |

`app_shell.dart` needs no change: JIM already opens Kulay from the nav.

### Reuse
`nlp.dart` is a line-for-line port of Kulay's `nlp.js`, so every case in `test.js` keeps passing. Its grounding ideas came from `lib/domain/prompt.dart`; the two are kept separate because Kulay's checks are stricter (stems, negation, same-kind wrong choices) and changing `prompt.dart` would change Create's behavior.

### Surviving leaving Kulay
Going back to Kodigno disposes `KulayScreen`. All reading state (current screen, story, chosen answers, placement progress) lives in `ReadingController`, provided once above `MaterialApp`. Pages render from `controller.screen` (an enum), not from a nested `Navigator`, so opening Kulay again shows the same screen with answers intact.

### How it lands
Branch `feature/kulay-reading`, merged by PR. JIM's untracked `docs/superpowers/plans/` and `tool/` stay untouched.

## 3. AI pipeline

`story_engine.dart` runs the same 8 steps, prompts and JSON schemas as `kulay/ai.js`. Kodigno's Standard tier is Qwen 2.5 1.5B Instruct Q4_K_M, the same model the prompts were tuned on.

1. Code picks the plan: the main character's Filipino name, age and home town (topic towns: Taal Volcano → Batangas, Coral reef → Palawan, Rice farm → Nueva Ecija).
2. The AI writes the story from a paragraph plan for the color.
3. **Check 1, story makes sense** (`lintStory`): no sentence starting mid-way, the name in the first sentence and used at least twice, the name not reused for a pet or another person, not too short or long, no near-duplicate sentences, on topic, English, no placeholders. Flesch-Kincaid grade is measured. A failed draft is rewritten with the problems as feedback.
4. Number the sentences; find people, places, times.
5. The AI writes questions, each naming its proof sentence and copying a short answer from it.
6. **Check 2, answer is in the story** (`checkQuestion`): stated and not denied, not a give-away, the right kind, wrong choices of the same kind that are not also true; then the AI answers its own question twice with the choices in opposite orders. A failed question is rewritten once, then dropped. Too few questions left means a new story (2 rounds).
7. Shuffle choices, tag each question with its skill, save.
8. The reader reads and answers.

### Calls
- Every call is `runtime.chat(messages, maxTokens:, temperature:, schema:)`.
- Output cut off at `maxTokens` is broken JSON; that draft is skipped like any other failed draft.
- Token caps per color as in `ai.js` (story: `words[1] * 2.2 + 300`).

### One model server
Kulay uses the llama-server already running for Library and Create; a second one would double memory use. `ModelUnavailableException` leads to the same lower-tier offer Create shows.

### Who goes first
Model calls wait in one line with three priorities: word help, then the story the reader is waiting on, then the background next story. A waiting call goes ahead of the background story after at most one call, because the pipeline is many small calls.

### Speed
- Prompts put the numbered story first and the question last, so llama-server reuses the processed story for each self-check call.
- The Basic (0.5B) tier writes 3 drafts instead of 4, then falls back to a starter story.
- Expect roughly 1 to 3 minutes per story on a CPU-only laptop; the background next story hides this after the first one.

### No AI needed
Placement uses the 4 fixed passages. The starter stories (23: 2 or 3 per color, 65 questions) were written by the Kulay pipeline and then reviewed by hand: questions with a wrong choice that was also true, a brand name, or a wrong premise were removed, and three factual or wording slips were fixed. Each carries `checks.reviewed`.

### Word help
Same as `explainWord`: up to 3 tries (temperature 0.3, 0.6, 0.9) with feedback, rejecting meanings that reuse the word; then the synonym fallback. Results are cached in memory per word and sentence.

## 4. Data model

3 new drift tables in Kodigno's database. Kodigno already has `Attempts`, so Kulay's is `ReadingAttempts`.

| Table | Columns |
|---|---|
| `Readers` | `id`, `name` (unique, case-insensitive), `level` (0–7), `placed` (bool), `createdAt` |
| `Stories` | `id`, `level`, `topic`, `title`, `paras` (JSON), `questions` (JSON: question, choices, answer index, evidence sentence index, skill), `checks` (JSON), `pipeline` (int), `source` (`ai` / `starter`), `createdAt` |
| `ReadingAttempts` | `id`, `readerId` (cascade delete), `storyId`, `level`, `correct`, `total`, `moved` (−1 / 0 / +1), `skills` (JSON), `takenAt`; unique (`readerId`, `storyId`) |

- Stories are shared: a story written for one reader goes to another reader at the same color and topic who has not read it.
- The background next story is an unread row in `Stories`; there is no queue table.
- Only stories with the current `pipeline` version are served.
- Starter stories are copied from the asset into `Stories` on first open, skipped if already there.
- Placement progress is in memory only; closing the app mid-check restarts the check.
- Answers are saved only when the reader submits.
- Migration: `onUpgrade` from 1 creates the 3 tables. Study sets, questions, flashcards and quiz attempts are untouched.
- Settings in `shared_preferences`: reading mode (`personal` / `classroom`), teacher PIN hash (`crypto`).

## 5. Screens and modes

One set of screens, two modes, chosen the first time Kulay opens and changeable from the Kulay header menu.
- **Just me:** opens straight to the reader's page. The progress view needs no PIN.
- **A class:** opens to a grid of reader names with "Add reader". The teacher view is behind a 4-digit PIN. The PIN only stops kids from changing their own color; it is not security.

Screens:
1. **Reader page:** current color, the 8-color ladder, recent scores, topic picker.
2. **Placement:** the 4 passages; result is the starting color.
3. **Writing:** the 8 steps tick by, styled like `generating_screen.dart`. Skipped when a story is ready.
4. **Story and quiz:** story card with "Listen to the story" and tap-a-word (popover with meaning and "Hear it"); questions below; a wrong answer highlights the proof sentence.
5. **Result:** score and any color change. In classroom mode, "Done, next reader" returns to the name grid.
6. **Teacher view:** class table, skill bars, teach next, needs work on, set color, delete reader.

Look: Kodigno's theme `K` (white, pastels, Bricolage). The 8 Kulay colors stay as the level colors. Story text at 20–22 px, line height 1.6. Only lowercase words are tappable, so names and places are not.

Read-aloud uses the speech engine built into Windows (`System.Speech`) through one long-lived PowerShell process, one sentence per line, so the sentence being read can be highlighted. It prefers an en-PH voice, then any English voice. `flutter_tts` was dropped: its Windows build needs `nuget.exe` and a package download on every fresh build.

## 6. Error handling

| Situation | What the reader sees |
|---|---|
| Model will not start or crashes | Same lower-tier offer as Create. Meanwhile an unread saved story at their color is served, if any. |
| All drafts fail, or too few questions survive 2 rounds | An unread saved story at their color (any topic): "Here is a ready story while the AI rests." If none: "Couldn't write a story. Try another topic." |
| Word help fails all tries | "No meaning found for this word." |
| No English voice installed | The Listen and Hear it buttons are hidden. |
| App closes during background writing | Nothing is saved for that story; it is written again later. |
| Tier changes or app shuts down | The engine checks a cancel flag between calls and stops. |
| Duplicate reader name | Inline error on the name field. |

A broken story is never shown: every story a reader sees passed both checks or is a hand-checked starter story.

## 7. Testing

- `test/reading/levels_test.dart`, `test/reading/nlp_test.dart`: port every case in `kulay/test.js`, including the real bad outputs the model produced (Cebu splitting, off topic, Spanish, placeholder, name reuse, mammals, give-away, negation, provinces, numbers, skills, `checkMeaning`).
- `test/reading/story_engine_test.dart`: `FakeLlmRuntime` with scripted replies: good draft; bad then good draft; broken JSON; self-check failure then rewrite; Basic tier falls back to a starter story after 3 drafts.
- `test/reading/reading_repository_test.dart`: in-memory drift; shared unread stories; unique attempts; v1 → v2 migration keeps existing study sets.
- `test/reading/reading_controller_test.dart`: level moves; priority line (word help goes ahead of background writing); state survives the loader replay.
- Widget tests: wrong answer highlights the proof sentence; teacher PIN gate; tap-a-word skips names.
- Live check (`test/reading/live_story_test.dart`, skipped unless `KULAY_LIVE_MODEL` is set): writes stories on the bundled llama-server. First run, Standard model on CPU: 4 of 4 passed, 23 to 74 seconds each; word help worked.

## 8. Risks

- **CPU speed:** a story can take minutes on weak laptops. Mitigated by background writing and starter stories.
- **Basic tier quality:** the 0.5B model may fail the checks often; readers then mostly get saved stories.
- **Truth checks are word-based:** a wrong choice that is a synonym of the answer can slip past check 2; the AI self-check catches most of these.
- **Parallel work:** JIM is editing Kodigno. Shared-file changes are limited to the table in section 2.
