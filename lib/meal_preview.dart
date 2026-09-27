import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:glucomi/features/meal/meal_food_repository.dart';
import 'package:glucomi/features/meal/meal_record_screen.dart';
import 'package:glucomi/shared/app_scroll_behavior.dart';

/// 음식 기록하기 화면만 따로 띄워보는 미리보기
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MealPreviewApp());
}

class MealPreviewApp extends StatelessWidget {
  const MealPreviewApp({super.key});

  static const Size _designSize = Size(360, 800);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scrollBehavior: const AppScrollBehavior(),
      home: MealRecordScreen(repository: SampleMealFoodRepository()),
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
