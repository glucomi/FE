import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';

/// Figma 공통 토스트 (COM-TOAST-01~04)
/// - success: COM-TOAST-01 성공
/// - error: COM-TOAST-02 실패/오류
/// - info: COM-TOAST-03 안내
/// - warning: COM-TOAST-04 경고
enum AppToastType {
  success('assets/toast/success.svg', AppColors.accentsBrand),
  error('assets/toast/error.svg', AppColors.accentsDanger),
  info('assets/toast/info.svg', AppColors.accentsBrand),
  warning('assets/toast/warning.svg', AppColors.accentsBrand);

  const AppToastType(this.icon, this.actionColor);

  final String icon;
  final Color actionColor;
}

/// 토스트 노출 시간 (정책서에 없어 3초로 둠)
const Duration appToastDuration = Duration(seconds: 3);

/// 토스트를 띄움. 이미 떠 있는 토스트는 바로 내리고 새로 띄움
///
/// [actionLabel] 을 주면 우측 버튼(Action/Retry)이 같이 나옴
void showAppToast(
  BuildContext context,
  String message, {
  AppToastType type = AppToastType.info,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = appToastDuration,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  showAppToastOn(
    messenger,
    message,
    type: type,
    actionLabel: actionLabel,
    onAction: onAction,
    duration: duration,
  );
}

/// await 이후처럼 context 를 쓰기 애매할 때 미리 잡아둔 messenger 로 띄움
void showAppToastOn(
  ScaffoldMessengerState messenger,
  String message, {
  AppToastType type = AppToastType.info,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = appToastDuration,
}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        width: AppToast.width,
        padding: EdgeInsets.zero,
        elevation: 0,
        backgroundColor: Colors.transparent,
        clipBehavior: Clip.none,
        duration: duration,
        content: AppToast(
          message: message,
          type: type,
          actionLabel: actionLabel,
          onAction: onAction == null
              ? null
              : () {
                  messenger.hideCurrentSnackBar();
                  onAction();
                },
        ),
      ),
    );
}

class AppToast extends StatelessWidget {
  const AppToast({
    super.key,
    required this.message,
    this.type = AppToastType.info,
    this.actionLabel,
    this.onAction,
  });

  static const double width = 316;
  static const double minHeight = 54;

  final String message;
  final AppToastType type;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final label = actionLabel;
    return Container(
      key: const ValueKey('app-toast'),
      constraints: const BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing4,
        vertical: AppSpacing.spacing2,
      ),
      decoration: BoxDecoration(
        color: AppColors.neutralsBackground,
        border: Border.all(color: AppColors.borderDefault),
        borderRadius: BorderRadius.circular(AppRadius.radiusLg),
        boxShadow: AppShadows.defaultShadow,
      ),
      child: Row(
        children: [
          SvgPicture.asset(type.icon, width: 20, height: 20),
          const SizedBox(width: AppSpacing.spacing2),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmM.copyWith(
                color: AppColors.foregroundPrimary,
              ),
            ),
          ),
          if (label != null) ...[
            const SizedBox(width: AppSpacing.spacing2),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onAction,
              child: Container(
                height: 32,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacing3,
                ),
                child: Text(
                  label,
                  style: AppTypography.btnSm.copyWith(color: type.actionColor),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

OverlayEntry? _overlayToast;

/// 바텀시트·다이얼로그가 떠 있을 때처럼 스낵바가 딤 뒤로 가려지는 곳에서 씀
/// (루트 오버레이 맨 위에 띄우고 [duration] 뒤에 사라짐)
void showAppToastOverlay(
  BuildContext context,
  String message, {
  AppToastType type = AppToastType.info,
  Duration duration = appToastDuration,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  _overlayToast?.remove();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _OverlayToast(
      message: message,
      type: type,
      duration: duration,
      onDone: () {
        if (_overlayToast == entry) _overlayToast = null;
        if (entry.mounted) entry.remove();
      },
    ),
  );
  _overlayToast = entry;
  overlay.insert(entry);
}

class _OverlayToast extends StatefulWidget {
  const _OverlayToast({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDone,
  });

  final String message;
  final AppToastType type;
  final Duration duration;
  final VoidCallback onDone;

  @override
  State<_OverlayToast> createState() => _OverlayToastState();
}

class _OverlayToastState extends State<_OverlayToast>
    with SingleTickerProviderStateMixin {
  static const _fade = Duration(milliseconds: 200);

  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    final total = widget.duration + _fade * 2;
    final fadeWeight = _fade.inMilliseconds.toDouble();
    _controller = AnimationController(vsync: this, duration: total);
    // 타이머 대신 애니메이션 하나로 나타남 → 유지 → 사라짐 처리
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: fadeWeight),
      TweenSequenceItem(
        tween: ConstantTween(1),
        weight: widget.duration.inMilliseconds.toDouble(),
      ),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: fadeWeight),
    ]).animate(_controller);
    _controller.forward().whenComplete(() {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + AppSpacing.spacing4;
    return Positioned(
      left: 0,
      right: 0,
      bottom: bottom,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _opacity,
          child: Center(
            child: SizedBox(
              width: AppToast.width,
              child: Material(
                type: MaterialType.transparency,
                child: AppToast(message: widget.message, type: widget.type),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
