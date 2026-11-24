import 'dart:typed_data';
import 'dart:ui' show Offset;

import 'package:glucomi/core/api/api_client.dart';

/// AI 음식 분석 결과 한 건
///
/// 팀 AI 모델 기준 (drive handoff):
/// - 분류기 cls_best.pt (YOLOv8n-cls) → food_name, confidence
/// - 로컬라이저 loc_best.pt (YOLOv8n) → 음식 영역 bbox, center (사진 픽셀 좌표)
class AnalyzedFood {
  const AnalyzedFood({
    required this.name,
    required this.confidence,
    this.foodId,
    this.center,
  });

  /// 분류기가 고른 음식명 (AI Hub 음식명)
  final String name;

  /// 0~1
  final double confidence;

  /// 서버가 음식 DB 와 매칭해 준 음식 ID (없으면 이름으로 검색해서 찾음)
  final String? foodId;

  /// 음식 칩을 띄울 위치 — 사진 크기 대비 비율 (0~1). 모르면 null → 가운데
  final Offset? center;
}

class FoodAnalysisResult {
  const FoodAnalysisResult({required this.foods});

  final List<AnalyzedFood> foods;

  bool get isEmpty => foods.isEmpty;
}

/// MO-CAMERA-010 (b) 분석중 — 사진을 보내 음식을 찾아옴
abstract class FoodAnalysisRepository {
  Future<FoodAnalysisResult> analyze(Uint8List bytes, {String? filename});
}

/// 서버 AI 분석 API
///
/// 계약은 docs/be-requests.md #12 기준 (BE 확정 전 — 경로·필드명이 바뀌면 여기만 고치면 됨)
/// POST /api/meal-records/ai-analysis (multipart, field: image)
/// → { imageWidth, imageHeight, foods: [{ foodName, confidence, foodId?, center: {x, y}, bbox? }] }
class ApiFoodAnalysisRepository implements FoodAnalysisRepository {
  ApiFoodAnalysisRepository([ApiClient? client])
    : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  static const String path = '/api/meal-records/ai-analysis';

  @override
  Future<FoodAnalysisResult> analyze(
    Uint8List bytes, {
    String? filename,
  }) async {
    final json = await _client.postMultipart(
      path,
      field: 'image',
      bytes: bytes,
      filename: filename ?? 'meal.jpg',
    );
    return parseFoodAnalysis(json);
  }
}

/// 서버 응답 → 결과 (Python 모델 출력 그대로 food_name / center 배열이 와도 읽음)
FoodAnalysisResult parseFoodAnalysis(Object? json) {
  if (json is! Map<String, dynamic>) return const FoodAnalysisResult(foods: []);
  final width = _num(json['imageWidth'] ?? json['image_width']);
  final height = _num(json['imageHeight'] ?? json['image_height']);
  final list = json['foods'] as List<dynamic>? ?? [json];

  final foods = <AnalyzedFood>[];
  for (final item in list) {
    if (item is! Map<String, dynamic>) continue;
    final name = (item['foodName'] ?? item['food_name']) as String?;
    if (name == null || name.trim().isEmpty) continue;
    foods.add(
      AnalyzedFood(
        name: name.trim(),
        confidence: _num(item['confidence']) ?? 0,
        foodId: item['foodId']?.toString(),
        center: _center(item['center'], width, height),
      ),
    );
  }
  return FoodAnalysisResult(foods: foods);
}

Offset? _center(Object? raw, double? width, double? height) {
  double? x;
  double? y;
  if (raw is Map) {
    x = _num(raw['x']);
    y = _num(raw['y']);
  } else if (raw is List && raw.length >= 2) {
    x = _num(raw[0]);
    y = _num(raw[1]);
  }
  if (x == null || y == null) return null;
  // 픽셀 좌표면 사진 크기로 나눠 비율로 바꿈 (이미 0~1 이면 그대로)
  if (x > 1 || y > 1) {
    if (width == null || height == null || width == 0 || height == 0) {
      return null;
    }
    x /= width;
    y /= height;
  }
  return Offset(x.clamp(0.0, 1.0).toDouble(), y.clamp(0.0, 1.0).toDouble());
}

double? _num(Object? v) => v is num ? v.toDouble() : double.tryParse('$v');

/// 로그인 전 / 서버 없이 볼 때 — 예시 결과
class SampleFoodAnalysisRepository implements FoodAnalysisRepository {
  const SampleFoodAnalysisRepository({
    this.delay = const Duration(seconds: 2),
  });

  final Duration delay;

  @override
  Future<FoodAnalysisResult> analyze(
    Uint8List bytes, {
    String? filename,
  }) async {
    await Future<void>.delayed(delay);
    return const FoodAnalysisResult(
      foods: [
        AnalyzedFood(name: '흑미밥', confidence: 0.7, center: Offset(0.5, 0.5)),
      ],
    );
  }
}
