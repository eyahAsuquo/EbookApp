import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:ebook_app_desktop/models/recent_pdf.dart';
import 'package:ebook_app_desktop/services/database_service.dart';

class LibraryController extends ChangeNotifier {
  List<RecentPdf> _recentPdfs = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<RecentPdf> get recentPdfs => _recentPdfs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadRecentPdfs() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _recentPdfs = await DatabaseService.instance.getRecentPdfs();
    } catch (e) {
      _errorMessage = 'Failed to load recent documents: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Opens system file picker for the user to select any PDF on their device
  Future<RecentPdf?> pickAndOpenPdf() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (file == null) {
        return null;
      }
      final path = file.path;
      if (path == null || path.isEmpty) return null;

      final ioFile = File(path);
      if (!await ioFile.exists()) return null;

      final length = await ioFile.length();
      final name = file.name.isNotEmpty ? file.name : ioFile.uri.pathSegments.last;
      final id = path.hashCode.abs().toString();

      final recent = RecentPdf(
        id: id,
        filePath: path,
        fileName: name,
        fileSize: length,
        totalPages: 1, // Will be updated when PDF loads
        lastReadPage: 1,
        lastOpenedAt: DateTime.now(),
      );

      await DatabaseService.instance.saveOrUpdateRecentPdf(recent);
      await loadRecentPdfs();
      return recent;
    } catch (e) {
      _errorMessage = 'Error picking PDF file: $e';
      notifyListeners();
      return null;
    }
  }

  Future<void> updatePdfProgress(String id, int page, int totalPages) async {
    final index = _recentPdfs.indexWhere((p) => p.id == id);
    if (index != -1) {
      final updated = _recentPdfs[index].copyWith(
        lastReadPage: page,
        totalPages: totalPages > 0 ? totalPages : _recentPdfs[index].totalPages,
        lastOpenedAt: DateTime.now(),
      );
      _recentPdfs[index] = updated;
      await DatabaseService.instance.saveOrUpdateRecentPdf(updated);
      notifyListeners();
    }
  }

  Future<void> removeRecentPdf(String id) async {
    await DatabaseService.instance.removeRecentPdf(id);
    _recentPdfs.removeWhere((item) => item.id == id);
    notifyListeners();
  }
}
