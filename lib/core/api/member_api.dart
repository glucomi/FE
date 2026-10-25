import 'package:glucomi/core/api/api_client.dart';
import 'package:glucomi/features/curation/curation_models.dart';
import 'package:glucomi/features/signup/signup_screen.dart';

/// GET /api/terms 항목
class TermsItem {
  const TermsItem({
    required this.type,
    required this.title,
    required this.isRequired,
    required this.hasDocument,
    this.documentUrl,
  });

  factory TermsItem.fromJson(Map<String, dynamic> json) => TermsItem(
    type: json['termsType'] as String,
    title: json['title'] as String? ?? '',
    isRequired: json['required'] == true,
    hasDocument: json['hasDocument'] == true,
    documentUrl: json['documentUrl'] as String?,
  );

  /// AGE_OVER_14 / SERVICE / PRIVACY / SERVICE_IMPROVEMENT / MARKETING
  final String type;
  final String title;
  final bool isRequired;
  final bool hasDocument;

  /// 약관 본문 URL (문서 확정 전까지 null)
  final String? documentUrl;
}

/// GET /api/members/me
class MemberInfo {
  const MemberInfo({
    required this.memberId,
    required this.signupCompleted,
    required this.onboardingCompleted,
    this.name,
    this.diabetesType,
    this.heightCm,
    this.targetMin,
    this.targetMax,
  });

  factory MemberInfo.fromJson(Map<String, dynamic> json) => MemberInfo(
    memberId: asInt(json['memberId']) ?? 0,
    name: json['name'] as String?,
    diabetesType: diabetesTypeFromApi(json['diabetesType'] as String?),
    heightCm: asDouble(json['heightCm']),
    targetMin: asInt(json['targetGlucoseMin']),
    targetMax: asInt(json['targetGlucoseMax']),
    signupCompleted: json['signupCompleted'] == true,
    onboardingCompleted: json['onboardingCompleted'] == true,
  );

  final int memberId;
  final String? name;
  final DiabetesType? diabetesType;
  final double? heightCm;
  final int? targetMin;
  final int? targetMax;
  final bool signupCompleted;
  final bool onboardingCompleted;
}

String diabetesTypeToApi(DiabetesType type) => switch (type) {
  DiabetesType.type1 => 'TYPE1',
  DiabetesType.type2Insulin => 'TYPE2_INSULIN',
  DiabetesType.type2NoInsulin => 'TYPE2_NO_INSULIN',
  DiabetesType.prediabetes => 'PRE',
  DiabetesType.gestational => 'GESTATIONAL',
  DiabetesType.none => 'NONE',
};

DiabetesType? diabetesTypeFromApi(String? value) {
  for (final type in DiabetesType.values) {
    if (diabetesTypeToApi(type) == value) return type;
  }
  return null;
}

class MemberApi {
  MemberApi([ApiClient? client]) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  /// 약관 목록 (로그인 없이 호출 가능)
  Future<List<TermsItem>> terms() async {
    final list = await _client.get('/api/terms', auth: false) as List<dynamic>;
    return [
      for (final item in list) TermsItem.fromJson(item as Map<String, dynamic>),
    ];
  }

  /// 약관 동의 저장 → 회원가입 완료
  Future<void> agree(SignupConsent consent) async {
    await _client.post(
      '/api/members/me/agreements',
      body: {
        'agreements': [
          {'termsType': 'AGE_OVER_14', 'agreed': consent.age},
          {'termsType': 'SERVICE', 'agreed': consent.terms},
          {'termsType': 'PRIVACY', 'agreed': consent.privacy},
          {'termsType': 'SERVICE_IMPROVEMENT', 'agreed': consent.quality},
          {'termsType': 'MARKETING', 'agreed': consent.marketing},
        ],
      },
    );
  }

  Future<MemberInfo> me() async {
    final json = await _client.get('/api/members/me') as Map<String, dynamic>;
    return MemberInfo.fromJson(json);
  }

  /// 큐레이션 4단계 저장 (몸무게는 서버에서 체중 기록으로도 저장됨)
  Future<MemberInfo> saveOnboarding(CurationResult result) async {
    final json =
        await _client.put(
              '/api/members/me/onboarding',
              body: {
                'diabetesType': diabetesTypeToApi(result.diabetesType),
                'heightCm': result.heightCm,
                'weightKg': result.weightKg,
                'targetGlucoseMin': result.targetMin,
                'targetGlucoseMax': result.targetMax,
              },
            )
            as Map<String, dynamic>;
    return MemberInfo.fromJson(json);
  }
}
