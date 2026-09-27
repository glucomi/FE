import 'package:flutter/material.dart';
import 'package:glucomi/features/camera/food_camera_screen.dart';
import 'package:glucomi/shared/app_scroll_behavior.dart';
import 'package:glucomi/shared/phone_frame.dart';

/// 카메라 화면만 따로 띄워보는 미리보기 (실제 앱과 같은 폰 프레임 사용)
void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      scrollBehavior: const AppScrollBehavior(),
      builder: (context, child) => PhoneFrame(child: child),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  fullscreenDialog: true,
                  builder: (_) => const FoodCameraScreen(),
                ),
              ),
              child: const Text('카메라 열기'),
            ),
          ),
        ),
      ),
    ),
  );
}
