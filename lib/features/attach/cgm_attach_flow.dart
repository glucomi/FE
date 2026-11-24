import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/attach/cgm_attach_models.dart';
import 'package:glucomi/shared/widgets/app_header_bar.dart';
import 'package:glucomi/shared/widgets/app_toast.dart';
import 'package:glucomi/shared/widgets/bottom_action_bar.dart';

/// 센서 연결 요청 — 케어센스는 일련번호, 리브레는 계정 이메일
class CgmAttachRequest {
  const CgmAttachRequest({required this.type, this.serial, this.email});

  final CgmSensorType type;
  final String? serial;
  final String? email;
}

/// 실제 연결을 처리하고 성공하면 true (실패 안내는 연결하는 쪽에서 띄움)
typedef CgmConnector = Future<bool> Function(CgmAttachRequest request);

/// MO-ATTACH-010 cgm 연결 화면을 열고, 연결 성공 화면에서 확인을 누르면 true
///
/// 홈 '연결하기'(MO-HOME-010 7번)와 마이페이지 '센서 연결'에서 진입
Future<bool> openCgmAttach(
  BuildContext context, {
  required CgmConnector onConnect,
}) async {
  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => CgmAttachFlow(onConnect: onConnect)),
  );
  return result ?? false;
}

/// 센서 선택 → 연결 가이드 → (케어센스) 센서 스캔 / 직접 등록 · (리브레) 계정 연동 → 연결 성공
class CgmAttachFlow extends StatefulWidget {
  const CgmAttachFlow({super.key, required this.onConnect});

  final CgmConnector onConnect;

  @override
  State<CgmAttachFlow> createState() => _CgmAttachFlowState();
}

class _CgmAttachFlowState extends State<CgmAttachFlow> {
  final GlobalKey<NavigatorState> _navigator = GlobalKey<NavigatorState>();

  NavigatorState get _inner => _navigator.currentState!;

  /// 흐름 전체를 닫음 (true 면 연결 완료 → 홈으로)
  void _exit([bool connected = false]) => Navigator.of(context).pop(connected);

  void _back() {
    if (_inner.canPop()) {
      _inner.pop();
    } else {
      _exit();
    }
  }

  void _push(Widget page) =>
      _inner.push(MaterialPageRoute<void>(builder: (_) => page));

  void _openGuide(CgmSensorType type) {
    _push(
      CgmGuideScreen(
        title: '연결 가이드',
        steps: type == CgmSensorType.libre
            ? CgmAttachPolicy.libreGuide
            : CgmAttachPolicy.caresensGuide,
        onBack: _back,
        onDone: () => type == CgmSensorType.libre
            ? _push(
                LibreAccountScreen(
                  onBack: _back,
                  onCheckAccount: () => _push(
                    CgmGuideScreen(
                      title: '리브레 계정 확인',
                      steps: CgmAttachPolicy.libreAccountGuide,
                      lastLabel: '확인',
                      onBack: _back,
                      onDone: _back,
                    ),
                  ),
                  onSubmit: (email) => _connect(
                    CgmAttachRequest(type: CgmSensorType.libre, email: email),
                  ),
                ),
              )
            : _push(
                SensorScanScreen(
                  onClose: _back,
                  onManualInput: () => _push(
                    SensorSerialScreen(
                      onBack: _back,
                      onSubmit: (serial) => _connect(
                        CgmAttachRequest(
                          type: CgmSensorType.caresensAir,
                          serial: serial,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _connect(CgmAttachRequest request) async {
    final ok = await widget.onConnect(request);
    if (!ok || !mounted) return;
    _inner.pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => SensorConnectedScreen(onConfirm: () => _exit(true)),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Navigator(
        key: _navigator,
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          builder: (_) =>
              SensorSelectScreen(onBack: _back, onSelect: _openGuide),
        ),
      ),
    );
  }
}

/// (a) 진입 — 사용할 센서 선택
class SensorSelectScreen extends StatelessWidget {
  const SensorSelectScreen({
    super.key,
    required this.onBack,
    required this.onSelect,
  });

  final VoidCallback onBack;
  final ValueChanged<CgmSensorType> onSelect;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralsBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppHeaderBar(title: '센서 선택', onBack: onBack),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.spacing5,
                AppSpacing.spacing6,
                AppSpacing.spacing5,
                AppSpacing.spacing4,
              ),
              child: Text(
                '사용할 센서 선택',
                style: AppTypography.headingH1.copyWith(
                  color: AppColors.foregroundPrimary,
                ),
              ),
            ),
            // 디자인 (a)는 케어센스 에어만 있음. 리브레는 정책서 (a) 기본 가이드가 있어 함께 노출
            for (final type in CgmSensorType.values)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.spacing5,
                  0,
                  AppSpacing.spacing5,
                  AppSpacing.spacing3,
                ),
                child: _SensorCard(
                  key: ValueKey('sensor-${type.name}'),
                  label: type.label,
                  onTap: () => onSelect(type),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SensorCard extends StatelessWidget {
  const _SensorCard({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.neutralsBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.radius3xl),
        side: const BorderSide(color: AppColors.borderDefault),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.radius3xl),
        onTap: onTap,
        child: SizedBox(
          height: 140,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.sensors,
                size: 56,
                color: AppColors.foregroundTertiary,
              ),
              const SizedBox(height: AppSpacing.spacing2),
              Text(
                label,
                style: AppTypography.bodyMdM.copyWith(
                  color: AppColors.foregroundSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// (b) 연결 가이드 / (c) 리브레 계정 확인 — STEP 카드 + 페이지 인디케이터 + 건너뛰기·다음
class CgmGuideScreen extends StatefulWidget {
  const CgmGuideScreen({
    super.key,
    required this.title,
    required this.steps,
    required this.onBack,
    required this.onDone,
    this.lastLabel = '다음',
  });

  final String title;
  final List<CgmGuideStep> steps;
  final VoidCallback onBack;

  /// 마지막 단계에서 다음 또는 건너뛰기를 눌렀을 때
  final VoidCallback onDone;

  /// 마지막 단계 주 버튼 문구
  final String lastLabel;

  @override
  State<CgmGuideScreen> createState() => _CgmGuideScreenState();
}

class _CgmGuideScreenState extends State<CgmGuideScreen> {
  final PageController _pages = PageController();
  int _index = 0;

  bool get _isLast => _index == widget.steps.length - 1;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLast) {
      widget.onDone();
      return;
    }
    _pages.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralsBackground,
      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomActionBar(
          label: _isLast ? widget.lastLabel : '다음',
          onPressed: _next,
          secondaryLabel: '건너뛰기',
          onSecondaryPressed: widget.onDone,
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppHeaderBar(title: widget.title, onBack: widget.onBack),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: widget.steps.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) =>
                    _GuidePage(number: i + 1, step: widget.steps[i]),
              ),
            ),
            _PageDots(count: widget.steps.length, index: _index),
            const SizedBox(height: AppSpacing.spacing2),
          ],
        ),
      ),
    );
  }
}

class _GuidePage extends StatelessWidget {
  const _GuidePage({required this.number, required this.step});

  final int number;
  final CgmGuideStep step;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.spacing5),
      child: Column(
        children: [
          // 가이드 이미지 자리 (이미지 미확정)
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.neutralsSurface,
                borderRadius: BorderRadius.circular(AppRadius.radiusXl),
                border: Border.all(color: AppColors.borderDefault),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.spacing8),
          Text(
            'STEP ${number.toString().padLeft(2, '0')}',
            style: AppTypography.bodySmM.copyWith(
              color: AppColors.accentsBrand,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing2),
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: AppTypography.headingH1.copyWith(
              color: AppColors.foregroundPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing2),
          Text(
            step.description,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMdR.copyWith(
              color: AppColors.foregroundTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          Container(
            width: 23,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: i == index
                  ? AppColors.accentsBrand
                  : AppColors.neutralsSubtle,
              borderRadius: BorderRadius.circular(AppRadius.radiusFull),
            ),
          ),
      ],
    );
  }
}

/// (c) 센서 스캔 — 은색 패키지 라벨 바코드 스캔
///
/// 바코드 인식 패키지가 아직 없어 스캔 영역만 두고, 직접 입력으로 이어감
class SensorScanScreen extends StatelessWidget {
  const SensorScanScreen({
    super.key,
    required this.onClose,
    required this.onManualInput,
  });

  final VoidCallback onClose;
  final VoidCallback onManualInput;

  @override
  Widget build(BuildContext context) {
    final white = AppTypography.bodyMdM.copyWith(color: Colors.white);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  key: const ValueKey('sensor-scan-close'),
                  onPressed: onClose,
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
              const Expanded(
                flex: 3,
                child: ColoredBox(
                  color: Color(0xFF2A2B33),
                  child: Center(
                    child: Icon(
                      Icons.qr_code_scanner,
                      color: Colors.white54,
                      size: 64,
                    ),
                  ),
                ),
              ),
              TextButton(
                key: const ValueKey('sensor-manual-input'),
                onPressed: onManualInput,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('센서 정보 직접 입력', style: white),
                    const Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.spacing6),
              Text(
                '은색 패키지 라벨에 있는 바코드를 스캔하세요.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmR.copyWith(color: Colors.white),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

/// (d) 센서 직접 등록 — 일련번호 뒤 4자리
class SensorSerialScreen extends StatefulWidget {
  const SensorSerialScreen({
    super.key,
    required this.onBack,
    required this.onSubmit,
  });

  final VoidCallback onBack;
  final Future<void> Function(String serial) onSubmit;

  @override
  State<SensorSerialScreen> createState() => _SensorSerialScreenState();
}

class _SensorSerialScreenState extends State<SensorSerialScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _submitting = false;

  bool get _valid =>
      _controller.text.length == CgmAttachPolicy.serialLength && !_submitting;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await widget.onSubmit(_controller.text);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralsBackground,
      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomActionBar(
          label: '다음',
          onPressed: _valid ? _submit : null,
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppHeaderBar(title: '센서 정보 직접 입력', onBack: widget.onBack),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.spacing5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    key: const ValueKey('sensor-serial'),
                    controller: _controller,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    maxLength: CgmAttachPolicy.serialLength,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: '일련번호 뒤 4자리',
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.radiusLg),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spacing4),
                  Text(
                    '센서 패키지 라벨에 있는\n일련번호 뒤 4자리를 입력해 주세요.',
                    style: AppTypography.bodyMdR.copyWith(
                      color: AppColors.foregroundSecondary,
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

/// (b) 리브레 계정 연동 — 이메일 입력 후 연동하기
class LibreAccountScreen extends StatefulWidget {
  const LibreAccountScreen({
    super.key,
    required this.onBack,
    required this.onCheckAccount,
    required this.onSubmit,
  });

  final VoidCallback onBack;
  final VoidCallback onCheckAccount;
  final Future<void> Function(String email) onSubmit;

  @override
  State<LibreAccountScreen> createState() => _LibreAccountScreenState();
}

class _LibreAccountScreenState extends State<LibreAccountScreen> {
  final TextEditingController _email = TextEditingController();
  bool _submitting = false;

  bool get _valid =>
      CgmAttachPolicy.isValidEmail(_email.text) && !_submitting;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await widget.onSubmit(_email.text.trim());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralsBackground,
      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomActionBar(
          label: '연동하기',
          onPressed: _valid ? _submit : null,
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppHeaderBar(title: '리브레 계정 연동', onBack: widget.onBack),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.spacing4),
                children: [
                  Text(
                    '이메일',
                    style: AppTypography.bodySmM.copyWith(
                      color: AppColors.foregroundPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spacing2),
                  TextField(
                    key: const ValueKey('libre-email'),
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: '리브레 계정 이메일',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.radiusLg),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spacing8),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.spacing4),
                    decoration: BoxDecoration(
                      color: AppColors.neutralsSubtle,
                      borderRadius: BorderRadius.circular(AppRadius.radiusLg),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 20,
                              color: AppColors.foregroundSecondary,
                            ),
                            const SizedBox(width: AppSpacing.spacing2),
                            Text(
                              '리브레 앱에서 병원등록을 하셨나요?',
                              style: AppTypography.bodyMdM.copyWith(
                                color: AppColors.foregroundPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.spacing2),
                        Text(
                          '• 리브레 앱 가입 후 병원 등록까지 완료해야\n  계정 연동이 가능해요.',
                          style: AppTypography.bodySmR.copyWith(
                            color: AppColors.foregroundTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spacing4),
                  Material(
                    color: AppColors.statusWarningSubtle,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.radiusLg),
                      side: const BorderSide(color: AppColors.statusWarning),
                    ),
                    child: InkWell(
                      key: const ValueKey('libre-check-account'),
                      borderRadius: BorderRadius.circular(AppRadius.radiusLg),
                      onTap: widget.onCheckAccount,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.spacing4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppColors.statusWarning,
                            ),
                            const SizedBox(width: AppSpacing.spacing2),
                            Expanded(
                              child: Text(
                                '리브레 계정 연동 전, 계정을 확인해주세요',
                                style: AppTypography.bodyMdM.copyWith(
                                  color: AppColors.foregroundPrimary,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward,
                              size: 18,
                              color: AppColors.statusWarning,
                            ),
                          ],
                        ),
                      ),
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

/// (e) 센서 연결 성공 — 확인 시 홈으로
class SensorConnectedScreen extends StatelessWidget {
  const SensorConnectedScreen({super.key, required this.onConfirm});

  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onConfirm();
      },
      child: Scaffold(
        backgroundColor: AppColors.neutralsBackground,
        bottomNavigationBar: SafeArea(
          top: false,
          child: BottomActionBar(label: '확인', onPressed: onConfirm),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                size: 64,
                color: AppColors.accentsBrand,
              ),
              const SizedBox(height: AppSpacing.spacing4),
              Text(
                '센서 연결 성공',
                style: AppTypography.headingH1.copyWith(
                  color: AppColors.foregroundPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.spacing2),
              Text(
                '센서 안정화까지 최대 2시간이 필요해요',
                style: AppTypography.bodyMdR.copyWith(
                  color: AppColors.foregroundTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 연결 API 가 없을 때 쓰는 기본 안내 (리브레 등)
void showAttachNotReady(BuildContext context, CgmSensorType type) {
  showAppToast(context, '${type.label} 연동은 준비 중이에요.');
}
