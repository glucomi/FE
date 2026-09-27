import 'dart:async';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:image_picker/image_picker.dart';

/// 음식 사진 촬영 (진입 · 실시간 촬영 → 분석중)
class FoodCameraScreen extends StatefulWidget {
  const FoodCameraScreen({
    super.key,
    this.onAnalyze,
    this.loadCameras = availableCameras,
  });

  /// 찍거나 고른 사진을 분석 (서버 연동 전에는 없어서 분석중 화면에 머무름)
  final Future<void> Function(XFile photo)? onAnalyze;

  /// 사용할 수 있는 카메라 목록 (테스트에서 바꿔 끼울 수 있음)
  final Future<List<CameraDescription>> Function() loadCameras;

  @override
  State<FoodCameraScreen> createState() => _FoodCameraScreenState();
}

class _FoodCameraScreenState extends State<FoodCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  String? _cameraError;
  bool _busy = false;

  /// 분석 중인 사진
  Uint8List? _photo;

  bool get _analyzing => _photo != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 앱이 백그라운드로 가면 카메라를 놓아주고, 돌아오면 다시 켬
    final controller = _controller;
    if (controller == null || _analyzing) return;
    if (state == AppLifecycleState.inactive) {
      _controller = null;
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await widget.loadCameras();
      if (cameras.isEmpty) {
        _setCameraError('카메라를 찾을 수 없어요');
        return;
      }
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _cameraError = null;
      });
    } on CameraException catch (e) {
      _setCameraError(
        e.code.contains('Denied') || e.code.contains('Permission')
            ? '카메라 권한이 필요해요'
            : '카메라를 사용할 수 없어요',
      );
    } catch (_) {
      _setCameraError('카메라를 사용할 수 없어요');
    }
  }

  void _setCameraError(String message) {
    if (mounted) setState(() => _cameraError = message);
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (_busy || controller == null || !controller.value.isInitialized) return;
    _busy = true;
    try {
      final file = await controller.takePicture();
      await _analyze(file);
    } catch (_) {
      _showMessage('사진을 찍지 못했어요. 다시 시도해 주세요.');
    } finally {
      _busy = false;
    }
  }

  Future<void> _pickFromGallery() async {
    if (_busy) return;
    _busy = true;
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file != null) await _analyze(file);
    } catch (_) {
      _showMessage('사진을 불러오지 못했어요.');
    } finally {
      _busy = false;
    }
  }

  Future<void> _analyze(XFile file) async {
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _photo = bytes);
    await _controller?.pausePreview();
    await widget.onAnalyze?.call(file);
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final frame = _frameRect(constraints.biggest, padding);

            return Stack(
              children: [
                Positioned.fill(child: _buildBackground()),
                Positioned.fill(child: _FrameMask(frame: frame)),
                Positioned.fromRect(
                  rect: frame,
                  child: _FrameBorder(
                    showCrosshair: !_analyzing && _cameraError == null,
                  ),
                ),
                if (!_analyzing && _cameraError != null)
                  Positioned.fromRect(
                    rect: frame,
                    child: _CameraErrorMessage(message: _cameraError!),
                  ),
                if (_analyzing) Positioned.fill(child: _Scanner(frame: frame)),
                Positioned(
                  left: AppSpacing.spacing4,
                  top: padding.top + AppSpacing.spacing4,
                  child: Semantics(
                    button: true,
                    label: '닫기',
                    child: GestureDetector(
                      key: const ValueKey('camera-close'),
                      onTap: () => Navigator.of(context).maybePop(),
                      behavior: HitTestBehavior.opaque,
                      child: SvgPicture.asset(
                        'assets/camera/close_white.svg',
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ),
                ),
                if (_analyzing)
                  Positioned(
                    left: AppSpacing.spacing4,
                    right: AppSpacing.spacing4,
                    top: frame.bottom + AppSpacing.spacing10,
                    child: const _GuideText(
                      '사진 속 음식을 분석하고 있어요',
                      '화면을 나가도 시간이 자동 저장됩니다',
                    ),
                  )
                else
                  Positioned(
                    left: AppSpacing.spacing4,
                    right: AppSpacing.spacing4,
                    bottom: AppSpacing.spacing16 + padding.bottom,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _GuideText(
                          '정확한 분석을 위해',
                          '식단 전체가 포함되도록 촬영해주세요',
                        ),
                        const SizedBox(height: AppSpacing.spacing6),
                        _Controls(
                          canCapture: _controller?.value.isInitialized ?? false,
                          onCapture: _capture,
                          onGallery: _pickFromGallery,
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 아래 안내 문구 + 버튼 영역 높이 (문구 44 + 간격 24 + 버튼 줄 120 + 아래 여백 64)
  static const double _bottomBlockHeight = 44 + 24 + 120 + 64;

  /// 촬영 영역 (Figma: 좌우 20 여백, 상태바 아래 124.5 에서 시작하는 정사각형)
  /// 화면이 낮으면 (사파리 주소창 등) 아래 안내 문구와 겹치지 않게 줄이고 위로 올림
  Rect _frameRect(Size screen, EdgeInsets padding) {
    const gap = AppSpacing.spacing6;
    final minTop = padding.top + 72; // 닫기 버튼 아래
    final bottomLimit =
        screen.height - padding.bottom - _bottomBlockHeight - gap;

    final size = (screen.width - 40)
        .clamp(0.0, (bottomLimit - minTop).clamp(0.0, double.infinity))
        .toDouble();
    var top = padding.top + 124.5;
    if (top + size > bottomLimit) {
      top = (bottomLimit - size).clamp(minTop, double.infinity).toDouble();
    }
    return Rect.fromLTWH((screen.width - size) / 2, top, size, size);
  }

  Widget _buildBackground() {
    if (_photo != null) {
      return Image.memory(_photo!, fit: BoxFit.cover, gaplessPlayback: true);
    }
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const ColoredBox(color: Colors.black);
    }
    // 세로 화면을 가득 채우도록 잘라서 보여줌
    final ratio = controller.value.aspectRatio;
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: 1000 / ratio,
          height: 1000,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}

/// 촬영 영역 밖을 어둡게 가리는 마스크 (검정 90% + 블러 5)
class _FrameMask extends StatelessWidget {
  const _FrameMask({required this.frame});

  final Rect frame;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _OutsideFrameClipper(frame),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: const ColoredBox(color: Color(0xE6000000)),
      ),
    );
  }
}

class _OutsideFrameClipper extends CustomClipper<Path> {
  const _OutsideFrameClipper(this.frame);

  final Rect frame;

  @override
  Path getClip(Size size) => Path()
    ..fillType = PathFillType.evenOdd
    ..addRect(Offset.zero & size)
    ..addRRect(
      RRect.fromRectAndRadius(frame, const Radius.circular(AppRadius.radiusLg)),
    );

  @override
  bool shouldReclip(_OutsideFrameClipper oldClipper) =>
      oldClipper.frame != frame;
}

class _FrameBorder extends StatelessWidget {
  const _FrameBorder({required this.showCrosshair});

  final bool showCrosshair;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderDefault, width: 3),
          borderRadius: BorderRadius.circular(AppRadius.radiusLg),
        ),
        child: showCrosshair
            ? const Center(
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 2,
                        height: 36,
                        child: ColoredBox(color: AppColors.neutralsBackground),
                      ),
                      SizedBox(
                        width: 36,
                        height: 2,
                        child: ColoredBox(color: AppColors.neutralsBackground),
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

class _CameraErrorMessage extends StatelessWidget {
  const _CameraErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacing6),
        child: Text(
          '$message\n앨범에서 사진을 선택해 주세요',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMdM.copyWith(
            color: AppColors.foregroundQuaternary,
          ),
        ),
      ),
    );
  }
}

class _GuideText extends StatelessWidget {
  const _GuideText(this.first, this.second);

  final String first;
  final String second;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.bodyMdM.copyWith(
      color: AppColors.neutralsBackground,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(first, textAlign: TextAlign.center, style: style),
        const SizedBox(height: AppSpacing.spacing05),
        Text(second, textAlign: TextAlign.center, style: style),
      ],
    );
  }
}

/// 앨범 / 촬영 버튼 줄
class _Controls extends StatelessWidget {
  const _Controls({
    required this.canCapture,
    required this.onCapture,
    required this.onGallery,
  });

  final bool canCapture;
  final VoidCallback onCapture;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing2),
        child: Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Semantics(
                  button: true,
                  label: '앨범에서 선택',
                  child: GestureDetector(
                    key: const ValueKey('camera-gallery'),
                    onTap: onGallery,
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0x1AFFFFFF),
                        border: Border.all(color: AppColors.neutralsSurface),
                        borderRadius: BorderRadius.circular(AppRadius.radiusSm),
                      ),
                      child: SvgPicture.asset(
                        'assets/camera/picture.svg',
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(
                          AppColors.neutralsSurface,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.spacing6),
            Expanded(
              child: Center(
                child: Semantics(
                  button: true,
                  label: '촬영',
                  enabled: canCapture,
                  child: GestureDetector(
                    key: const ValueKey('camera-shutter'),
                    onTap: canCapture ? onCapture : null,
                    child: Opacity(
                      opacity: canCapture ? 1 : 0.4,
                      child: SvgPicture.asset(
                        'assets/camera/shutter.svg',
                        width: 80,
                        height: 80,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.spacing6),
            const Expanded(child: SizedBox()),
          ],
        ),
      ),
    );
  }
}

/// 분석중 스캔 애니메이션: 초록 선이 촬영 영역을 위아래로 훑고 아래로 그라데이션이 따라감
class _Scanner extends StatefulWidget {
  const _Scanner({required this.frame});

  final Rect frame;

  @override
  State<_Scanner> createState() => _ScannerState();
}

class _ScannerState extends State<_Scanner>
    with SingleTickerProviderStateMixin {
  // Figma: 4초 동안 아래→위→아래→위→아래
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  static const _up = Cubic(0.293, -0.245, 0.652, 1.123);
  static const _down = Cubic(0.546, 0.008, 0.372, 1.001);
  static const Color _glow = Color(0xFF16B09E);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frame = widget.frame;
    // 선이 움직이는 범위 (Figma 기준 영역 위 19, 아래 11 안쪽)
    final top = frame.top + 19;
    final bottom = frame.bottom - 11;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        // 0→0.5 올라감, 0.5→1 내려옴
        final progress = t < 0.5
            ? _up.transform(t * 2)
            : 1 - _down.transform((t - 0.5) * 2);
        final lineY = bottom - (bottom - top) * progress;
        final trail = (bottom - lineY) * 0.6;

        return Stack(
          children: [
            Positioned(
              left: frame.left - 6,
              width: frame.width + 12,
              top: lineY,
              height: trail,
              child: const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x8016B09E), Color(0x0016B09E)],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: frame.left - 5,
              width: frame.width + 10,
              top: lineY - 4,
              height: 8,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.accentsBrand,
                    borderRadius: BorderRadius.circular(AppRadius.radiusFull),
                    boxShadow: [
                      BoxShadow(
                        color: _glow.withValues(alpha: 0.6),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
