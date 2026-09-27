import 'package:flutter/foundation.dart';

enum DiabetesType {
  type1('1형 당뇨'),
  type2Insulin('2형 당뇨(인슐린 투여)'),
  type2NoInsulin('2형 당뇨(인슐린 미투여)'),
  prediabetes('전 당뇨'),
  gestational('임신성 당뇨'),
  none('해당 없음');

  const DiabetesType(this.label);

  final String label;

  /// 당뇨병 진료지침 기준 기본 목표 혈당 범위 (10 단위로 맞춤)
  ({int min, int max}) get defaultTargetRange => switch (this) {
    DiabetesType.type1 ||
    DiabetesType.type2Insulin ||
    DiabetesType.type2NoInsulin => (min: 70, max: 180),
    DiabetesType.gestational => (min: 60, max: 140),
    DiabetesType.prediabetes || DiabetesType.none => (min: 70, max: 140),
  };
}

@immutable
class CurationResult {
  const CurationResult({
    required this.diabetesType,
    required this.heightCm,
    required this.weightKg,
    required this.targetMin,
    required this.targetMax,
  });

  final DiabetesType diabetesType;
  final int heightCm;
  final double weightKg;
  final int targetMin;
  final int targetMax;
}
