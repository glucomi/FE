import 'package:flutter/material.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/home/home_models.dart';

/// 일일카드에 보여줄 하루 요약 (어제 기준)
class DailyCardData {
  const DailyCardData({
    required this.date,
    this.averageGlucose,
    this.maxGlucose,
    this.minGlucose,
    this.tirPercent,
    this.tirMinutes,
  });

  /// CGM 측정값으로 계산 (측정값이 없으면 전부 null)
  factory DailyCardData.fromPoints(
    DateTime date,
    List<CgmPoint> points, {
    int? targetMin,
    int? targetMax,
  }) {
    if (points.isEmpty) return DailyCardData(date: date);
    final values = [for (final p in points) p.value];
    final avg = values.reduce((a, b) => a + b) / values.length;
    int? tir;
    int? tirMinutes;
    if (targetMin != null && targetMax != null) {
      final inRange = values
          .where((v) => v >= targetMin && v <= targetMax)
          .length;
      tir = (inRange / values.length * 100).round();
      tirMinutes = (24 * 60 * inRange / values.length).round();
    }
    return DailyCardData(
      date: date,
      averageGlucose: avg.round(),
      maxGlucose: values.reduce((a, b) => a > b ? a : b).round(),
      minGlucose: values.reduce((a, b) => a < b ? a : b).round(),
      tirPercent: tir,
      tirMinutes: tirMinutes,
    );
  }

  final DateTime date;
  final int? averageGlucose;
  final int? maxGlucose;
  final int? minGlucose;
  final int? tirPercent;
  final int? tirMinutes;

  bool get hasData => averageGlucose != null;
}

/// COM-POP-11 일일카드 (MO-HOME-010 11번 '일일카드' 탭 시 호출)
///
/// 정책·디자인: '일일카드 임시 작업' 상태. 1차 전달본 '일일카드' 시안
/// (어제 혈당 요약: 평균·최고·최저·TIR) 구성으로 우선 구현
Future<void> showDailyCardDialog(
  BuildContext context, {
  required Future<DailyCardData> Function() load,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => _DailyCardDialog(load: load),
  );
}

class _DailyCardDialog extends StatefulWidget {
  const _DailyCardDialog({required this.load});

  final Future<DailyCardData> Function() load;

  @override
  State<_DailyCardDialog> createState() => _DailyCardDialogState();
}

class _DailyCardDialogState extends State<_DailyCardDialog> {
  late final Future<DailyCardData> _data = widget.load();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: const ValueKey('daily-card'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 25),
      backgroundColor: AppColors.neutralsBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.radius2xl),
      ),
      child: SizedBox(
        width: 310,
        height: 530,
        child: FutureBuilder<DailyCardData>(
          future: _data,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data;
            if (data == null) {
              return const Center(child: Text('일일카드를 불러오지 못했어요.'));
            }
            return _Content(data: data);
          },
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.data});

  final DailyCardData data;

  @override
  Widget build(BuildContext context) {
    String mg(int? v) => v == null ? '--' : '$v mg/dL';
    final tir = data.tirPercent == null
        ? '--'
        : '${data.tirPercent}%'
              '${data.tirMinutes == null ? '' : '(약 ${data.tirMinutes! ~/ 60}시간${data.tirMinutes! % 60}분)'}';

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.spacing6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '어제(${data.date.month}월${data.date.day}일)혈당, 같이 볼까요?',
                  style: AppTypography.bodyMdM.copyWith(
                    color: AppColors.foregroundSecondary,
                  ),
                ),
              ),
              GestureDetector(
                key: const ValueKey('daily-card-close'),
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.close, size: 22),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing3),
          Text(
            data.hasData ? '어제 혈당을 정리했어요' : '어제 측정된 혈당이 없어요',
            style: AppTypography.headingH1.copyWith(
              color: AppColors.foregroundPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing6),
          _Row('평균 혈당', mg(data.averageGlucose)),
          _Row('최고 혈당', mg(data.maxGlucose)),
          _Row('최저 혈당', mg(data.minGlucose)),
          _Row('TIR', tir),
          const Spacer(),
          Text(
            '요약 문구·경보 카드는 기획 확정 후 반영돼요',
            style: AppTypography.labelBadge.copyWith(
              color: AppColors.foregroundQuaternary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing2),
      child: Row(
        children: [
          Text(
            label,
            style: AppTypography.bodyMdR.copyWith(
              color: AppColors.foregroundTertiary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTypography.bodyMdM.copyWith(
              color: AppColors.foregroundPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
