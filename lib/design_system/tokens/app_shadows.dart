import 'package:flutter/material.dart';

abstract final class AppShadows {
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color.fromRGBO(137, 137, 137, 0.05),
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> defaultShadow = [
    BoxShadow(
      color: Color.fromRGBO(137, 137, 137, 0.10),
      offset: Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color.fromRGBO(137, 137, 137, 0.10),
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: -1,
    ),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color.fromRGBO(137, 137, 137, 0.10),
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -1,
    ),
    BoxShadow(
      color: Color.fromRGBO(137, 137, 137, 0.10),
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: -2,
    ),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color.fromRGBO(137, 137, 137, 0.10),
      offset: Offset(0, 10),
      blurRadius: 15,
      spreadRadius: -3,
    ),
    BoxShadow(
      color: Color.fromRGBO(137, 137, 137, 0.10),
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -4,
    ),
  ];

  static const List<BoxShadow> xl = [
    BoxShadow(
      color: Color.fromRGBO(137, 137, 137, 0.10),
      offset: Offset(0, 20),
      blurRadius: 25,
      spreadRadius: -5,
    ),
    BoxShadow(
      color: Color.fromRGBO(137, 137, 137, 0.10),
      offset: Offset(0, 8),
      blurRadius: 10,
      spreadRadius: -6,
    ),
  ];
}
