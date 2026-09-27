import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/home/home_models.dart';

/// 오늘의 기록 (헤더 + 기록 카드 타임라인)
class DailyRecordList extends StatelessWidget {
  const DailyRecordList({
    super.key,
    required this.records,
    this.onTapDailyCard,
    this.onTapRecord,
  });

  final List<DailyRecord> records;
  final VoidCallback? onTapDailyCard;
  final ValueChanged<DailyRecord>? onTapRecord;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              '오늘의 기록',
              style: TextStyle(
                fontFamily: AppTypography.fontFamilySans,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.32,
                color: Color(0xFF354051),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onTapDailyCard,
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 28,
                padding: const EdgeInsets.only(
                  left: AppSpacing.spacing2,
                  right: AppSpacing.spacing1,
                ),
                decoration: BoxDecoration(
                  color: AppColors.foregroundOnAccent,
                  borderRadius: BorderRadius.circular(AppRadius.radiusSm),
                  boxShadow: AppShadows.defaultShadow,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '일일 카드',
                      style: AppTypography.btnSm.copyWith(
                        color: AppColors.foregroundSecondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.spacing1),
                    SvgPicture.asset(
                      'assets/home/chevron_right_16.svg',
                      width: 16,
                      height: 16,
                      colorFilter: const ColorFilter.mode(
                        AppColors.foregroundSecondary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.spacing4),
        if (records.isEmpty)
          const _EmptyRecords()
        else
          for (var i = 0; i < records.length; i++) ...[
            if (i > 0) const _TimelineConnector(),
            DailyRecordCard(
              record: records[i],
              onTap: onTapRecord == null ? null : () => onTapRecord!(records[i]),
            ),
          ],
      ],
    );
  }
}

class _EmptyRecords extends StatelessWidget {
  const _EmptyRecords();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing16),
      child: Column(
        children: [
          Text(
            '기록이 없습니다',
            style: AppTypography.bodyMdM.copyWith(
              color: AppColors.foregroundSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing05),
          Text(
            '기록을 추가해주세요',
            style: AppTypography.bodySmR.copyWith(
              color: AppColors.foregroundTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 카드 사이 세로 점선
class _TimelineConnector extends StatelessWidget {
  const _TimelineConnector();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          for (var i = 0; i < 4; i++)
            Container(
              width: 1.5,
              height: 2,
              margin: const EdgeInsets.symmetric(vertical: 1),
              color: AppColors.neutralsEmphasis,
            ),
        ],
      ),
    );
  }
}

/// Figma card/dailyMemo
class DailyRecordCard extends StatelessWidget {
  const DailyRecordCard({super.key, required this.record, this.onTap});

  final DailyRecord record;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final metaStyle = AppTypography.labelBadge.copyWith(
      color: AppColors.foregroundQuaternary,
    );

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing4,
          vertical: 13,
        ),
        decoration: BoxDecoration(
          color: AppColors.gray0,
          borderRadius: BorderRadius.circular(AppRadius.radiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.spacing1),
              child: Row(
                children: [
                  Text(formatRecordTime(record.time), style: metaStyle),
                  const Spacer(),
                  RecordTypeChip(type: record.type),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.spacing15),
            Container(
              padding: const EdgeInsets.only(
                left: AppSpacing.spacing4,
                right: AppSpacing.spacing2,
                top: AppSpacing.spacing3,
                bottom: AppSpacing.spacing3,
              ),
              decoration: BoxDecoration(
                color: AppColors.gray10,
                borderRadius: BorderRadius.circular(AppRadius.radiusLg),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: Row(
                children: [
                  if (record.type == DailyRecordType.food) ...[
                    _FoodThumbnail(imageAsset: record.imageAsset),
                    const SizedBox(width: AppSpacing.spacing2),
                  ],
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.spacing1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMdM.copyWith(
                              color: AppColors.foregroundPrimary,
                            ),
                          ),
                          if (record.details.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.spacing1),
                            Row(
                              children: [
                                for (var i = 0; i < record.details.length; i++) ...[
                                  if (i > 0) ...[
                                    const SizedBox(width: AppSpacing.spacing1),
                                    Container(
                                      width: 1,
                                      height: 10,
                                      color: AppColors.neutralsEmphasis,
                                    ),
                                    const SizedBox(width: AppSpacing.spacing1),
                                  ],
                                  // 좁으면 말줄임
                                  Flexible(
                                    child: Text(
                                      record.details[i],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: metaStyle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.spacing2),
                  SvgPicture.asset(
                    'assets/home/chevron_right_16.svg',
                    width: 16,
                    height: 16,
                    colorFilter: const ColorFilter.mode(
                      AppColors.neutralsEmphasis,
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoodThumbnail extends StatelessWidget {
  const _FoodThumbnail({this.imageAsset});

  final String? imageAsset;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.radiusSm),
      child: SizedBox(
        width: 57,
        height: 57,
        child: imageAsset != null
            ? Image.asset(imageAsset!, fit: BoxFit.cover)
            : ColoredBox(
                color: DailyRecordType.food.tint,
                child: Center(
                  child: SvgPicture.asset(
                    DailyRecordType.food.iconAsset,
                    width: 24,
                    height: 24,
                  ),
                ),
              ),
      ),
    );
  }
}

/// Figma Chip/Memo
class RecordTypeChip extends StatelessWidget {
  const RecordTypeChip({super.key, required this.type});

  final DailyRecordType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing2),
      decoration: BoxDecoration(
        color: type.tint,
        borderRadius: BorderRadius.circular(AppRadius.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            type.iconAsset,
            width: 10,
            height: 10,
            colorFilter: ColorFilter.mode(type.color, BlendMode.srcIn),
          ),
          const SizedBox(width: AppSpacing.spacing1),
          Text(type.label, style: AppTypography.labelBadge.copyWith(color: type.color)),
        ],
      ),
    );
  }
}
