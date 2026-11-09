#!/usr/bin/env bash
# Vercel 빌드 (vercel.json buildCommand 256자 제한 때문에 스크립트로 분리)
# 카카오 키·API 주소는 Vercel 환경변수에서 받아 --dart-define 으로 넘김
set -euo pipefail
.flutter-sdk/bin/flutter build web --release \
  --dart-define=API_BASE_URL="${API_BASE_URL:-https://54-116-228-101.sslip.io}" \
  --dart-define=KAKAO_REST_API_KEY="${KAKAO_REST_API_KEY:-}" \
  --dart-define=KAKAO_JAVASCRIPT_KEY="${KAKAO_JAVASCRIPT_KEY:-}" \
  --dart-define=KAKAO_REDIRECT_URI="${KAKAO_REDIRECT_URI:-https://ddadang.vercel.app/}"
