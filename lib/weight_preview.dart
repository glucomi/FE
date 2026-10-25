import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:glucomi/features/weight/weight_models.dart';
import 'package:glucomi/features/weight/weight_record_screen.dart';
import 'package:glucomi/shared/app_scroll_behavior.dart';

/// 체중 화면만 따로 띄워보는 미리보기
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WeightPreviewApp());
}

class WeightPreviewApp extends StatelessWidget {
  const WeightPreviewApp({super.key});

  static const Size _designSize = Size(360, 800);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scrollBehavior: const AppScrollBehavior(),
      home: WeightRecordScreen(repository: SampleWeightRepository()),
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
