class Chapter {
  final int index;
  final String title;
  final String content;

  const Chapter({
    required this.index,
    required this.title,
    required this.content,
  });

  Map<String, dynamic> toMap() {
    return {
      'index': index,
      'title': title,
      'content': content,
    };
  }

  factory Chapter.fromMap(Map<String, dynamic> map) {
    return Chapter(
      index: (map['index'] as int?) ?? 0,
      title: (map['title'] as String?) ?? '',
      content: (map['content'] as String?) ?? '',
    );
  }
}

