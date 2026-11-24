/// MO-ATTACH-010 cgm 연결 — 센서 종류와 연결 가이드 문구 (정책서 문구 그대로)
enum CgmSensorType {
  caresensAir('케어센스 에어'),
  libre('프리스타일 리브레');

  const CgmSensorType(this.label);

  final String label;
}

class CgmGuideStep {
  const CgmGuideStep(this.title, this.description);

  final String title;
  final String description;
}

abstract final class CgmAttachPolicy {
  /// (d) 센서 직접 등록: 일련번호 뒤 4자리
  static const int serialLength = 4;

  /// (b) 연결 가이드 — 케어센스 에어
  ///
  /// 정책서 (b) 연결 가이드 프레임 문구를 그대로 씀.
  /// 문구가 리브레 가이드와 같아서 기획 확인 필요 (docs/screen-flow-notes.md)
  static const List<CgmGuideStep> caresensGuide = [
    CgmGuideStep(
      '프리스타일 리브레 앱 설치',
      '앱스토어/ 플레이스토어에서 [프리스타일 리브레]를 검색하여 설치해주세요',
    ),
    CgmGuideStep(
      '리브레 앱 시작하기',
      '리브레 앱을 켜고 [지금 시작하기]를 눌러 회원 등록 과정을 진행해주세요',
    ),
    CgmGuideStep(
      '연결된 앱 찾기',
      '계정 생성 완료 후 [다음]을 눌러 왼쪽 상단 메뉴를 선택하여 [연결된 앱] 탭을 선택해주세요',
    ),
  ];

  /// (a) 기본 — 리브레 연결 가이드 6단계
  static const List<CgmGuideStep> libreGuide = [
    CgmGuideStep(
      '프리스타일 리브레 앱 설치',
      '앱스토어/ 플레이스토어에서 [프리스타일 리브레]를 검색하여 설치해주세요',
    ),
    CgmGuideStep(
      '리브레 앱 시작하기',
      '리브레 앱을 켜고 [지금 시작하기]를 눌러 회원 등록 과정을 진행해주세요',
    ),
    CgmGuideStep(
      '연결된 앱 찾기',
      '계정 생성 완료 후 [다음]을 눌러 왼쪽 상단 메뉴를 선택하여 [연결된 앱] 탭을 선택해주세요',
    ),
    CgmGuideStep(
      '병원 등록',
      '[연결]을 누르고 [병원에 연결] 선택 후 병원 ID 입력란에 [따당]을 입력한 뒤 다음을 눌러주세요',
    ),
    CgmGuideStep('병원 등록 완료', '병원명을 확인한 뒤 [연결]을 눌러주세요'),
    CgmGuideStep('연결된 병원 확인', '연결된 병원에 등록한 병원이 생성되면 절차가 완료됩니다'),
  ];

  /// (c) 리브레 계정 확인 4단계
  static const List<CgmGuideStep> libreAccountGuide = [
    CgmGuideStep('리브레 홈', '리브레 홈에서 우측 상단 [메뉴 버튼]을 눌러주세요'),
    CgmGuideStep('리브레 메뉴', '하단 [설정 버튼]을 눌러주세요'),
    CgmGuideStep('설정', '계정 설정 > [계정 세부 정보]를 눌러주세요'),
    CgmGuideStep('계정 세부 정보', '[이메일 정보]를 확인하세요'),
  ];

  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static bool isValidEmail(String value) => _email.hasMatch(value.trim());
}
