enum ReaderThemeMode {
  light,
  sepia,
  dark,
}

enum ReaderFontFamily {
  serif,
  sansSerif,
  monospace,
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

