# BE 요청 사항 (FE 정책서 QA 결과, 2026-11-09)

기준: 피그마 `와이어프레임&정책서` 페이지. FE는 아래 계약대로 이미 연결해 두었고, 표시한 BE 작업이 끝나면 추가 FE 수정 없이 동작합니다.

## 🔴 배포 전에 꼭 필요 (웹 카카오 로그인)

웹(ddadang.vercel.app)은 카카오 SDK 토큰을 직접 받을 수 없어서 **인가 코드 방식**으로 로그인합니다.
FE는 `POST /api/auth/kakao/code`를 호출하도록 이미 연결해 두었습니다.

1. **API 추가: `POST /api/auth/kakao/code`** (인증 없이 호출, `/api/auth/**` 공개 경로)
   - 요청: `{ "code": "<카카오 인가 코드>", "redirectUri": "https://ddadang.vercel.app/" }`
   - 처리: 서버에서 `https://kauth.kakao.com/oauth/token`에 `grant_type=authorization_code, client_id=<REST API 키>, redirect_uri, code`(+ Client Secret을 켰다면 `client_secret`)를 form으로 보내 `access_token`을 받은 뒤, **기존 `authService.loginWithKakao(accessToken)`을 그대로 호출**
   - 응답: 기존 `POST /api/auth/kakao`와 같은 `LoginResponse` (accessToken, refreshToken, memberId, isNewMember, signupCompleted, onboardingCompleted)
   - 보안: `redirectUri`는 서버 설정값과 정확히 같을 때만 허용. REST 키·Client Secret은 서버에만 두기
   - 실패(코드 만료/재사용, redirectUri 불일치): 4xx + 기존 `INVALID_KAKAO_TOKEN` 에러
2. **CORS 설정** — 지금 develop에는 CORS가 없어서 배포된 웹에서 Authorization 헤더를 붙인 요청이 브라우저에서 전부 막힙니다.
   - 허용 Origin: `https://ddadang.vercel.app`, 개발용 `http://localhost:*`
   - Methods: GET, POST, PUT, DELETE, OPTIONS / Headers: Authorization, Content-Type, Accept
   - Spring Security에 `.cors(Customizer.withDefaults())` + `CorsConfigurationSource` 빈
3. **설정값** (`application.yml` + EC2 `.env` + `docker-compose.prod.yml`의 environment)
   ```
   KAKAO_REST_API_KEY=<카카오 REST API 키>
   KAKAO_REDIRECT_URI=https://ddadang.vercel.app/
   KAKAO_CLIENT_SECRET=<콘솔에서 Client Secret을 켰을 때만>
   APP_CORS_ORIGINS=https://ddadang.vercel.app
   ```
4. **카카오 개발자 콘솔**
   - 플랫폼 > Web 사이트 도메인: `https://ddadang.vercel.app`
   - 카카오 로그인 > Redirect URI: `https://ddadang.vercel.app/` (끝 `/`까지 FE·BE 값과 완전히 같아야 함)
   - 카카오 로그인 활성화 ON
5. **확인 방법**
   ```bash
   curl -i -X OPTIONS https://54-116-228-101.sslip.io/api/members/me \
     -H 'Origin: https://ddadang.vercel.app' \
     -H 'Access-Control-Request-Method: GET' \
     -H 'Access-Control-Request-Headers: authorization'
   # → 200 + Access-Control-Allow-Origin: https://ddadang.vercel.app
   ```

## 🟠 머지 필요

6. **인슐린 API `feat/record-33-insulin-record` (#33) develop 머지**
   - 10/5 이후 develop과 갈라져 있어서 rebase가 필요합니다.
   - FE는 이 브랜치 계약으로 연결 완료: `GET /api/insulin-products`, `GET/POST/DELETE /api/members/me/insulins`, `GET(date)/POST/PUT/DELETE /api/insulin-records`
   - FE는 `POST /api/members/me/insulins`가 409를 주면 "이미 등록된 인슐린이에요"(COM-TOAST-02)를 띄웁니다. 409를 꼭 유지해 주세요.
   - `InsulinActionType`에 **복합형(솔리쿠아·줄토피)**이 없습니다. 정책·디자인(COM-POP-08)은 초속효성/속효성/중간형/장기형/혼합형/복합형 6분류입니다. `COMBINATION` 추가를 요청합니다. 지금 FE는 모르는 값을 혼합형으로 표시합니다.

## 🟡 정책과 다른 부분 (계약 변경 요청)

7. **운동 기록: 한 기록에 운동 여러 개** (MO-EXERCISE-010)
   - 정책: 한 번 저장에 운동 N개(운동별 시간)
   - 현재 BE: `ExerciseRecordRequest.exerciseId` 1개
   - 임시 FE 처리: 운동마다 기록을 하나씩 만들고 같은 일시·메모로 저장합니다. 홈에는 운동별 카드로 따로 보입니다.
   - 요청: `items: [{exerciseId, durationMin}]` 형태로 바꿔 주시면 FE를 맞추겠습니다.
8. **메모: 사진만 있는 메모 + 사진 첨부** (MO-MEMO-010)
   - 정책: 사진 또는 텍스트 중 하나만 있어도 저장 가능, 사진 최대 10장
   - 현재 BE: `content @NotBlank`, 사진 필드 없음
   - 임시 FE 처리: 내용이 없으면 저장하지 않고 "사진만 있는 메모는 아직 저장할 수 없어요" 안내. 사진은 서버에 저장되지 않음
   - 요청: `content` 선택값으로 변경 + 사진 업로드 API(멀티파트 또는 업로드 URL 발급)
9. **식단 사진** (MO-MEAL-040 사진 최대 10장)
   - 현재 BE: 사진 첨부 미지원(`MealRecordController` 설명). 7번과 같은 업로드 방식으로 요청합니다.
10. **혈당 직접 기록 범위** (MO-GLUCOSER-010)
   - 정책: 10~300 mg/dL. BE `GlucoseRecordRequest`는 `@Max(600)`
   - 요청: `@Max(300)`으로 맞춰 주세요. FE는 이미 300에서 막습니다.
11. **체중 기록 시각**
    - `WeightRecordResponse`에 날짜만 있어서 홈 그래프 마커가 00:00에 찍힙니다.
    - 정책상 "결과 그래프에 해당 이벤트 마커 즉시 노출"이 있으니 `measuredAt`(일시)도 응답에 넣어 주시면 좋겠습니다.

## 참고: FE에서 이번에 연결한 API

| 화면 | API |
|---|---|
| MO-WEIGHT-010 | `PUT/GET/DELETE /api/weight-records/{date}`, `GET /api/weight-records/latest` |
| MO-EXERCISE-010/020 | `GET /api/exercises(?keyword, popular)`, `GET /api/exercises/recent`, `GET(date)/POST/PUT/DELETE /api/exercise-records` |
| MO-MEMO-010 | `GET(date)/POST/PUT/DELETE /api/memo-records` |
| MO-INSULIN-010/020/030 | 6번 참고 |
| MO-MEAL | 영양성분 당류 필드명 `sugarsG`로 수정 (기존 FE가 `sugarG`로 읽어서 당류가 항상 비어 있었음) |
