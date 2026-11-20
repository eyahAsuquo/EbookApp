import 'dart:io';
import 'package:flutter/foundation.dart';

class FileAssociationService {
  FileAssociationService._();
  static final FileAssociationService instance = FileAssociationService._();

  /// Returns true if running on Windows
  bool get isWindows => !kIsWeb && Platform.isWindows;

  /// Registers the running executable as the default handler for .pdf files in Windows Registry (HKCU)
  Future<bool> registerPdfAssociation([String? customExePath]) async {
    if (!isWindows) return false;

    try {
      final exePath = customExePath ?? Platform.resolvedExecutable;
      if (!File(exePath).existsSync()) return false;

      // 1. Register ProgID PepperReader.PDF
      await _runReg([
        'add',
        r'HKCU\Software\Classes\PepperReader.PDF',
        '/ve',
        '/t',
        'REG_SZ',
        '/d',
        'PDF Document (Pepper Reader)',
        '/f',
      ]);

      // 2. Set default application icon to exe
      await _runReg([
        'add',
        r'HKCU\Software\Classes\PepperReader.PDF\DefaultIcon',
        '/ve',
        '/t',
        'REG_SZ',
        '/d',
        '$exePath,0',
        '/f',
      ]);

      // 3. Register open command
      await _runReg([
        'add',
        r'HKCU\Software\Classes\PepperReader.PDF\shell\open\command',
        '/ve',
        '/t',
        'REG_SZ',
        '/d',
        '"$exePath" "%1"',
        '/f',
      ]);

      // 4. Map .pdf extension in HKCU\Software\Classes\.pdf
      await _runReg([
        'add',
        r'HKCU\Software\Classes\.pdf',
        '/ve',
        '/t',
        'REG_SZ',
        '/d',
        'PepperReader.PDF',
        '/f',
      ]);

      // 5. Register in OpenWithProgids so it appears in "Open with" context menu
      await _runReg([
        'add',
        r'HKCU\Software\Classes\.pdf\OpenWithProgids',
        '/v',
        'PepperReader.PDF',
        '/t',
        'REG_NONE',
        '/f',
      ]);

      // 6. Register Application command
      final exeName = exePath.split(Platform.pathSeparator).last;
      await _runReg([
        'add',
        'HKCU\\Software\\Classes\\Applications\\$exeName\\shell\\open\\command',
        '/ve',
        '/t',
        'REG_SZ',
        '/d',
        '"$exePath" "%1"',
        '/f',
      ]);

      return true;
    } catch (e) {
      debugPrint('Error registering PDF file association: $e');
      return false;
    }
  }

  /// Checks if .pdf is currently associated with PepperReader.PDF
  Future<bool> isPdfAssociated() async {
    if (!isWindows) return false;

    try {
      final result = await Process.run('reg.exe', [
        'query',
        r'HKCU\Software\Classes\.pdf',
        '/ve',
      ]);

      if (result.exitCode == 0) {
        return (result.stdout as String).contains('PepperReader.PDF');
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _runReg(List<String> args) async {
    final res = await Process.run('reg.exe', args);
    if (res.exitCode != 0) {
      debugPrint('reg.exe failed with code ${res.exitCode}: ${res.stderr}');
    }
  }
}
