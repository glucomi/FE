import 'package:flutter/foundation.dart';
import 'package:glucomi/core/api/auth_session.dart';
import 'package:glucomi/core/api/member_api.dart';
import 'package:glucomi/features/curation/curation_models.dart';

enum Gender {
  male('남성', '남자'),
  female('여성', '여자');

  const Gender(this.optionLabel, this.displayLabel);

  /// 성별 수정 팝업 선택지
  final String optionLabel;

  /// 내 프로필 화면 표시값
  final String displayLabel;
}

/// MO-PROFILE-010 내 프로필
@immutable
class UserProfile {
  const UserProfile({
    required this.name,
    this.birthDate,
    this.gender,
    this.heightCm,
    this.diabetesType,
  });

  final String name;
  final DateTime? birthDate;
  final Gender? gender;
  final int? heightCm;
  final DiabetesType? diabetesType;

  UserProfile copyWith({
    String? name,
    DateTime? birthDate,
    Gender? gender,
    int? heightCm,
    DiabetesType? diabetesType,
  }) => UserProfile(
    name: name ?? this.name,
    birthDate: birthDate ?? this.birthDate,
    gender: gender ?? this.gender,
    heightCm: heightCm ?? this.heightCm,
    diabetesType: diabetesType ?? this.diabetesType,
  );
}

/// 마이페이지 센서 카드 상태 (Figma 3가지)
enum SensorState {
  /// 센서 미연결 — 연결 필요
  none,

  /// 정상 연결 — 연결 N일차
  connected,

  /// 연결 끊김 — 연결 N일차 (빨간색)
  disconnected,
}

@immutable
class SensorStatus {
  const SensorStatus({required this.state, this.deviceName, this.day});

  const SensorStatus.none() : this(state: SensorState.none);

  final SensorState state;

  /// 케어센스에어 등
  final String? deviceName;

  /// 부착 후 N일차
  final int? day;

  /// GET /api/home 의 sensor (connected, provider, sensorDay)
  ///
  /// 연결 끊김은 서버에 따로 표시가 없어서
  /// '연결 안 됨 + 부착 일차는 있음'을 끊김으로 봄
  factory SensorStatus.fromHome({
    required bool connected,
    String? provider,
    int? day,
  }) {
    final name = sensorProviderName(provider);
    if (connected) {
      return SensorStatus(
        state: SensorState.connected,
        deviceName: name,
        day: day,
      );
    }
    if (day != null) {
      return SensorStatus(
        state: SensorState.disconnected,
        deviceName: name,
        day: day,
      );
    }
    return const SensorStatus.none();
  }
}

String sensorProviderName(String? provider) => switch (provider) {
  'LIBRE' => '프리스타일 리브레',
  _ => '케어센스에어',
};

/// MO-ALARM-010 알림 설정
@immutable
class NotificationSettings {
  const NotificationSettings({this.push = false, this.marketing = false});

  final bool push;
  final bool marketing;

  NotificationSettings copyWith({bool? push, bool? marketing}) =>
      NotificationSettings(
        push: push ?? this.push,
        marketing: marketing ?? this.marketing,
      );
}

/// 마이페이지에서 보여주는 내 정보 묶음
@immutable
class MyPageData {
  const MyPageData({
    required this.profile,
    required this.sensor,
    required this.notifications,
    this.targetMin,
    this.targetMax,
  });

  final UserProfile profile;
  final SensorStatus sensor;
  final NotificationSettings notifications;
  final int? targetMin;
  final int? targetMax;

  MyPageData copyWith({
    UserProfile? profile,
    SensorStatus? sensor,
    NotificationSettings? notifications,
    int? targetMin,
    int? targetMax,
  }) => MyPageData(
    profile: profile ?? this.profile,
    sensor: sensor ?? this.sensor,
    notifications: notifications ?? this.notifications,
    targetMin: targetMin ?? this.targetMin,
    targetMax: targetMax ?? this.targetMax,
  );
}

/// 마이페이지 데이터
///
/// - 불러오기: 로그인 상태면 GET /api/members/me (이름·키·당뇨 유형·목표 혈당),
///   아니면 예시 데이터. 센서 상태는 홈에서 받은 값(GET /api/home)을 넘겨받음
/// - 저장: 프로필 수정·목표 혈당 수정·알림 설정·탈퇴 API 가 아직 없어서
///   앱이 켜져 있는 동안만 메모리에 들고 있음 (API 생기면 여기만 바꾸면 됨)
class MyPageRepository extends ChangeNotifier {
  MyPageRepository({MemberApi? memberApi, MyPageData? initial})
    // ignore: prefer_initializing_formals
    : _memberApi = memberApi,
      _data = initial;

  final MemberApi? _memberApi;

  MyPageData? _data;
  MyPageData? get data => _data;

  bool get _online => AuthSession.instance.isLoggedIn;

  static const MyPageData sample = MyPageData(
    profile: UserProfile(
      name: '글루코미',
      gender: Gender.female,
      heightCm: 168,
      diabetesType: DiabetesType.none,
    ),
    sensor: SensorStatus(
      state: SensorState.connected,
      deviceName: '케어센스에어',
      day: 1,
    ),
    notifications: NotificationSettings(),
    targetMin: 70,
    targetMax: 150,
  );

  Future<MyPageData> load({SensorStatus? sensor}) async {
    final cached = _data;
    if (cached != null) {
      if (sensor == null) return cached;
      return _data = cached.copyWith(sensor: sensor);
    }
    if (!_online) {
      return _data = sample.copyWith(
        profile: sample.profile.copyWith(birthDate: DateTime(2002, 1, 18)),
        sensor: sensor,
      );
    }

    final me = await (_memberApi ?? MemberApi()).me();
    return _data = MyPageData(
      profile: UserProfile(
        name: me.name ?? '',
        heightCm: me.heightCm?.round(),
        diabetesType: me.diabetesType,
      ),
      sensor: sensor ?? const SensorStatus.none(),
      notifications: const NotificationSettings(),
      targetMin: me.targetMin,
      targetMax: me.targetMax,
    );
  }

  Future<void> updateProfile(UserProfile profile) async {
    final current = _data;
    if (current == null) return;
    _data = current.copyWith(profile: profile);
    notifyListeners();
  }

  Future<void> updateTarget(int min, int max) async {
    final current = _data;
    if (current == null) return;
    _data = current.copyWith(targetMin: min, targetMax: max);
    notifyListeners();
  }

  Future<void> updateNotifications(NotificationSettings settings) async {
    final current = _data;
    if (current == null) return;
    _data = current.copyWith(notifications: settings);
    notifyListeners();
  }

  /// 로그아웃 — 토큰만 지움 (서버 로그아웃 API 없음)
  Future<void> logout() async {
    _data = null;
    await AuthSession.instance.clear();
  }

  /// 탈퇴 — 탈퇴 API 가 없어서 지금은 로그아웃과 같게 처리
  Future<void> withdraw(String reason) async {
    await logout();
  }
}
