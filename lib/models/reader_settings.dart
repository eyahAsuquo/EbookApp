import 'package:flutter/material.dart';
import 'package:ebook_app/core/constants/app_colors.dart';

enum ReaderThemeMode {
  light,
  sepia,
  dark;

  Color get backgroundColor {
    switch (this) {
      case ReaderThemeMode.light:
        return AppColors.readerLightBg;
      case ReaderThemeMode.sepia:
        return AppColors.readerSepiaBg;
      case ReaderThemeMode.dark:
        return AppColors.readerDarkBg;
    }
  }

  Color get textColor {
    switch (this) {
      case ReaderThemeMode.light:
        return AppColors.readerLightText;
      case ReaderThemeMode.sepia:
        return AppColors.readerSepiaText;
      case ReaderThemeMode.dark:
        return AppColors.readerDarkText;
    }
  }
}

enum ReaderFontFamily {
  serif,
  sansSerif,
  monospace;

  String get familyName {
    switch (this) {
      case ReaderFontFamily.serif:
        return 'serif';
      case ReaderFontFamily.sansSerif:
        return 'sans-serif';
      case ReaderFontFamily.monospace:
        return 'monospace';
    }
  }
}

class ReaderSettings {
  final double fontSize;
  final ReaderThemeMode themeMode;
  final ReaderFontFamily fontFamily;
  final double lineHeight;

  const ReaderSettings({
    this.fontSize = 17.0,
    this.themeMode = ReaderThemeMode.sepia,
    this.fontFamily = ReaderFontFamily.serif,
    this.lineHeight = 1.65,
  });

  Color get backgroundColor => themeMode.backgroundColor;
  Color get textColor => themeMode.textColor;
  String get fontFamilyName => fontFamily.familyName;

  TextStyle get bodyTextStyle => TextStyle(
        fontSize: fontSize,
        height: lineHeight,
        color: textColor,
        fontFamily: fontFamilyName,
        letterSpacing: 0.15,
      );

  ReaderSettings copyWith({
    double? fontSize,
    ReaderThemeMode? themeMode,
    ReaderFontFamily? fontFamily,
    double? lineHeight,
  }) {
    return ReaderSettings(
      fontSize: fontSize ?? this.fontSize,
      themeMode: themeMode ?? this.themeMode,
      fontFamily: fontFamily ?? this.fontFamily,
      lineHeight: lineHeight ?? this.lineHeight,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fontSize': fontSize,
      'themeMode': themeMode.index,
      'fontFamily': fontFamily.index,
      'lineHeight': lineHeight,
    };
  }

  factory ReaderSettings.fromMap(Map<String, dynamic> map) {
    return ReaderSettings(
      fontSize: (map['fontSize'] as num?)?.toDouble() ?? 17.0,
      themeMode: ReaderThemeMode.values[(map['themeMode'] as int?) ?? 1],
      fontFamily: ReaderFontFamily.values[(map['fontFamily'] as int?) ?? 0],
      lineHeight: (map['lineHeight'] as num?)?.toDouble() ?? 1.65,
    );
  }
}
