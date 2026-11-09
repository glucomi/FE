# Kakao login QA and configuration

Screen source: Figma `2878:19195` and policy `MO-LOGIN-010` on page `2:13`.

## Setup

- `flutter pub get`
- Flutter SDK 3.38+ and Dart 3.9+ for Kakao Flutter SDK v2.
- `KAKAO_NATIVE_APP_KEY`: registered native app key (Android/iOS only).
- `KAKAO_JAVASCRIPT_KEY`: registered JavaScript key (Flutter SDK initialization).
- `KAKAO_REST_API_KEY`: Kakao REST API key (OAuth `client_id` in web).
- `KAKAO_REDIRECT_URI`: an exact registered redirect URL, e.g. `https://qa.example.com/`.
- `API_BASE_URL`: Spring Boot backend origin. Web CORS must allow the Flutter origin.

The Kakao Developer Console must enable Kakao Login, register the exact Web domain,
register the redirect URI, and configure Android package hashes/iOS URL schemes
when native targets are added. No client secret belongs in a frontend dart-define.

Web login requires the BE `POST /api/auth/kakao/code` patch and BE env vars
`KAKAO_REST_API_KEY`, `KAKAO_REDIRECT_URI`. It MUST NOT exchange the auth code
using a confidential Kakao key from the browser.

Example (replace values only in your local shell, never commit secrets):

```bash
flutter pub get
flutter run -d chrome \
  --dart-define=API_BASE_URL=https://your-api.example.com \
  --dart-define=KAKAO_REST_API_KEY=your-kakao-rest-api-key \
  --dart-define=KAKAO_JAVASCRIPT_KEY=your-kakao-js-key \
  --dart-define=KAKAO_REDIRECT_URI=http://localhost:YOUR_STABLE_PORT/
```

Run Chrome with `--web-port=YOUR_STABLE_PORT` to match the registered URI.

## Verification matrix

1. No saved JWT -> MO-LOGIN-010 screen with a single active Kakao CTA.
2. Cancel Kakao consent -> stay on login with no false success.
3. Invalid/reused auth code -> backend 4xx, no saved JWT.
4. Correct OAuth state -> POST `/api/auth/kakao/code`, save returned JWT.
5. Wrong/missing state -> reject before making the backend call.
6. New account -> terms screen; pending account -> terms screen.
7. Signed up but not onboarded -> curation.
8. Returning complete account -> home.
9. App restart -> securely restored JWT, login skipped (BE verifies `/api/members/me`).
10. API unreachable -> show failure and retry, do not silently mark signup incomplete.

No live success claim without a registered Kakao application, deployed backend,
valid redirect URI, and real authorized test account.

## Deploy checklist (ddadang.vercel.app)

- Vercel env: `KAKAO_REST_API_KEY`, `KAKAO_JAVASCRIPT_KEY`, (optional) `KAKAO_REDIRECT_URI`, `API_BASE_URL` — `vercel.json` passes them as `--dart-define`.
- Local build upload: pass the same four values with `--dart-define`.
- BE `.env`: see `docs/be-requests.md` #1–5.
