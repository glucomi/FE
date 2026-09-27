import 'package:flutter/material.dart';

abstract final class AppTypography {
  static const String fontFamilySans = 'Pretendard';
  static const String fontFamilyMono = 'Roboto Mono';

  static const double fontSizeXs = 11;
  static const double fontSizeSm = 12;
  static const double fontSizeBase = 13;
  static const double fontSizeMd = 14;
  static const double fontSizeLg = 15;
  static const double fontSizeXl = 16;
  static const double fontSize2xl = 18;
  static const double fontSize3xl = 20;
  static const double fontSize4xl = 24;
  static const double fontSize5xl = 28;
  static const double fontSize6xl = 32;

  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemibold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;
  static const FontWeight fontWeightExtrabold = FontWeight.w800;

  static const double lineHeightTight = 1.2;
  static const double lineHeightSnug = 1.3;
  static const double lineHeightNormal = 1.4;
  static const double lineHeightRelaxed = 1.5;
  static const double lineHeightLoose = 1.7;

  static const double letterSpacingDefault = 0;
  static const String letterSpacingWide = '0.04em';
  static const String letterSpacingWider = '0.06em';
  static const String letterSpacingWidest = '0.10em';

  static const TextStyle displayLg = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 48,
    fontWeight: FontWeight.w700,
    height: 45 / 48,
  );

  static const TextStyle displayMd = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 38 / 36,
  );

  static const TextStyle displaySm = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 30 / 24,
  );

  static const TextStyle headingH1 = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 25 / 20,
  );

  static const TextStyle headingH2 = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 23 / 18,
  );

  static const TextStyle headingH3 = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 25 / 16,
  );

  static const TextStyle bodyLgM = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 22 / 16,
  );

  static const TextStyle bodyLgR = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 22 / 16,
  );

  static const TextStyle bodyMdM = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 21 / 14,
  );

  static const TextStyle bodyMdR = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 21 / 14,
  );

  static const TextStyle bodySmM = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 18 / 12,
  );

  static const TextStyle bodySmR = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 18 / 12,
  );

  static const TextStyle bodyXsM = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 16 / 10,
  );

  static const TextStyle bodyXsR = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    height: 16 / 10,
  );

  static const TextStyle labelBadge = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1,
  );

  static const TextStyle labelMeta = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 18 / 12,
  );

  static const TextStyle labelNav = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 16 / 10,
  );

  static const TextStyle btnLg = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 22 / 16,
  );

  static const TextStyle btnMd = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 21 / 14,
  );

  static const TextStyle btnSm = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 15 / 11,
  );
}
