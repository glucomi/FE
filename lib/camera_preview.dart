import 'package:flutter/material.dart';
import 'package:glucomi/features/camera/food_camera_screen.dart';
import 'package:glucomi/shared/app_scroll_behavior.dart';

/// 카메라 화면만 따로 띄워보는 미리보기 (브라우저 크기 그대로 사용)
void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      scrollBehavior: AppScrollBehavior(),
      home: FoodCameraScreen(),
    ),
  );
}
