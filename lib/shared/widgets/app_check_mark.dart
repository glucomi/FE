import 'package:flutter/material.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';

class AppCheckMark extends StatelessWidget {
  const AppCheckMark({
    super.key,
    required this.checked,
  });

  final bool checked;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Icon(
        Icons.check_rounded,
        size: 24,
        color: checked
            ? AppColors.interactiveBrandDefault
            : AppColors.borderDefault,
      ),
    );
  }
}
