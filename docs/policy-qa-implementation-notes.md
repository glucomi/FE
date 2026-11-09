# Policy-first QA implementation notes (2026-11-09)

## Source of truth

Figma file `V49aTmnVC5RcZhq98tyRG5`, page `와이어프레임&정책서` (node `2:13`).
Screen policy beats visual comps, except where the policy explicitly conflicts with itself.

## Applied in this patch

- Blood glucose: 10–300 mg/dL UI validation, out-of-range reset on focus loss and COM-TOAST-03; BE uses 10–600 so backend validators must be aligned separately.
- Manual blood glucose records: existing BE CRUD endpoints, with date retrieval on logged-in home.
- Medication records: existing member medications and medication-record CRUD, with date retrieval on logged-in home.
- Meal search: registration suggestion appears when typing, while actual DB search still executes on Enter.
- Signup/demo flow: connect exercise and memo records (previously unreachable from the add menu).
- UI validation tests adjusted for 10–300 mg/dL.

## Server / policy dependencies not silently changed

- **MO-MEAL-040 photos**: current BE `MealRecordController` explicitly says photo attachments are not yet supported. UI photos currently cannot persist on BE.
- **MO-MEMO-010 photo-only memo**: policy allows photo-only, but BE `MemoRecordRequest.content` is `@NotBlank` and does not accept photos. Needs BE extension before real persistence.
- **MO-INSULIN-010/020/030**: BE API exists on `feat/record-33-insulin-record` (not merged). FE now uses `ApiInsulinRepository` against that contract — works once BE #33 is merged and deployed.
- **MO-EXERCISE-010**: policy supports multiple exercises per record, but BE `ExerciseRecordRequest` takes one `exerciseId` only. Interim: FE saves one BE record per exercise with the same time/memo (see `docs/be-requests.md` #7).
- **MO-MEAL-040 → MO-GLYCEMIC-010**: policy requires post-save navigation, but FE has no glycemic result screen and the exact policy flow (meal draft/save vs AI registration) conflicts with other meal screens; design/flow needs clarification before implementation.
- **MO-MEAL-020 AI registration**: policy calls for AI and routes to 040; current 040 is meal save, while 050 is custom food. Resolve screen ID and required backend AI capability.
- **MO-INSULIN-010**: 30 U max conflicts with the same policy's '100.0' example. Current 30 U remains until the policy is corrected.
- **MO-EXERCISE-010 memo placeholder**: policy says '복용과 관련한...', design says '운동과 관련한...'. Keep code aligned with policy until policy text is corrected.
- **MO-MEMO-010 / COM-04**: memo required vs photo OR text rule conflict. Keep the screen-specific photo-or-text rule.

## Added 2026-11-09 (policy QA round 2)

- Weight, exercise, memo, insulin now use BE APIs when logged in (`Api*Repository`), loaded per date on home.
- Meal nutrient key fixed: `sugarsG` (was `sugarG`).
- Save/delete/list errors on drug, insulin, exercise, weight screens now show COM-TOAST instead of failing silently.
- Kakao web callback: `?code&state` removed from the address bar right after it is read.
- Meal record edit/delete from home is not implemented: policy has no edit/delete spec for saved meals (MO-MEAL-040 goes to MO-GLYCEMIC-010).
- BE follow-ups: `docs/be-requests.md`.

## Verification

Run `dart format lib test`, `flutter analyze`, `flutter test` and device QA against the Figma policy before merging. Backend API integration tests require a live authenticated test account; the code was not compiled by this script.
