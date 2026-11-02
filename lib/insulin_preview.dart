import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:glucomi/features/insulin/insulin_models.dart';
import 'package:glucomi/features/insulin/insulin_record_screen.dart';
import 'package:glucomi/shared/app_scroll_behavior.dart';

/// 인슐린 화면만 따로 띄워보는 미리보기 (내 인슐린 예시 3개)
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const InsulinPreviewApp());
}

class InsulinPreviewApp extends StatelessWidget {
  const InsulinPreviewApp({super.key});

  static const Size _designSize = Size(360, 800);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scrollBehavior: const AppScrollBehavior(),
      home: InsulinRecordScreen(
        repository: SampleInsulinRepository.withExamples(),
      ),
      builder: (context, child) {
        if (!kIsWeb) return child ?? const SizedBox.shrink();

        final mediaQuery = MediaQuery.of(context).copyWith(
          size: _designSize,
          padding: EdgeInsets.zero,
          viewPadding: EdgeInsets.zero,
          viewInsets: EdgeInsets.zero,
        );
        return ColoredBox(
          color: const Color(0xFFF5F6F8),
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: _designSize.width,
              height: _designSize.height,
              child: ClipRect(
                child: MediaQuery(
                  data: mediaQuery,
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
