class RecentPdf {
  final String id;
  final String filePath;
  final String fileName;
  final int fileSize;
  final int totalPages;
  final int lastReadPage;
  final DateTime lastOpenedAt;

  const RecentPdf({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.totalPages,
    required this.lastReadPage,
    required this.lastOpenedAt,
  });

  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get formattedLastOpened {
    final now = DateTime.now();
    final difference = now.difference(lastOpenedAt);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${lastOpenedAt.year}-${lastOpenedAt.month.toString().padLeft(2, '0')}-${lastOpenedAt.day.toString().padLeft(2, '0')}';
  }

  RecentPdf copyWith({
    String? id,
    String? filePath,
    String? fileName,
    int? fileSize,
    int? totalPages,
    int? lastReadPage,
    DateTime? lastOpenedAt,
  }) {
    return RecentPdf(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      totalPages: totalPages ?? this.totalPages,
      lastReadPage: lastReadPage ?? this.lastReadPage,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'file_path': filePath,
      'file_name': fileName,
      'file_size': fileSize,
      'total_pages': totalPages,
      'last_read_page': lastReadPage,
      'last_opened_at': lastOpenedAt.toIso8601String(),
    };
  }

  factory RecentPdf.fromMap(Map<String, dynamic> map) {
    return RecentPdf(
      id: map['id'] as String,
      filePath: map['file_path'] as String,
      fileName: map['file_name'] as String,
      fileSize: (map['file_size'] as int?) ?? 0,
      totalPages: (map['total_pages'] as int?) ?? 1,
      lastReadPage: (map['last_read_page'] as int?) ?? 1,
      lastOpenedAt: DateTime.tryParse(map['last_opened_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
