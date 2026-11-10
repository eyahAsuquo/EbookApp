class WordDefinition {
  final int? id;
  final String word;
  final String phonetic;
  final String partOfSpeech;
  final String definition;
  final String? example;
  final List<String> synonyms;
  final bool isBookmarked;

  const WordDefinition({
    this.id,
    required this.word,
    required this.phonetic,
    required this.partOfSpeech,
    required this.definition,
    this.example,
    this.synonyms = const [],
    this.isBookmarked = false,
  });

  WordDefinition copyWith({
    int? id,
    String? word,
    String? phonetic,
    String? partOfSpeech,
    String? definition,
    String? example,
    List<String>? synonyms,
    bool? isBookmarked,
  }) {
    return WordDefinition(
      id: id ?? this.id,
      word: word ?? this.word,
      phonetic: phonetic ?? this.phonetic,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      definition: definition ?? this.definition,
      example: example ?? this.example,
      synonyms: synonyms ?? this.synonyms,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'word': word,
      'phonetic': phonetic,
      'part_of_speech': partOfSpeech,
      'definition': definition,
      'example': example,
      'synonyms': synonyms.join(','),
    };
  }

  factory WordDefinition.fromMap(Map<String, dynamic> map, {bool isBookmarked = false}) {
    final synonymsRaw = map['synonyms'] as String?;
    final synonymsList = (synonymsRaw != null && synonymsRaw.trim().isNotEmpty)
        ? synonymsRaw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
        : <String>[];

    return WordDefinition(
      id: map['id'] as int?,
      word: (map['word'] as String?) ?? '',
      phonetic: (map['phonetic'] as String?) ?? '',
      partOfSpeech: (map['part_of_speech'] as String?) ?? 'definition',
      definition: (map['definition'] as String?) ?? '',
      example: map['example'] as String?,
      synonyms: synonymsList,
      isBookmarked: isBookmarked || (map['is_bookmarked'] == 1),
    );
  }

  factory WordDefinition.fromJson(Map<String, dynamic> json) {
    List<String> synonymsList = [];
    if (json['synonyms'] is List) {
      synonymsList = (json['synonyms'] as List).map((e) => e.toString()).toList();
    } else if (json['synonyms'] is String && (json['synonyms'] as String).isNotEmpty) {
      synonymsList = (json['synonyms'] as String).split(',').map((s) => s.trim()).toList();
    }

    return WordDefinition(
      word: (json['word'] as String?) ?? '',
      phonetic: (json['phonetic'] as String?) ?? '',
      partOfSpeech: (json['part_of_speech'] as String?) ?? (json['partOfSpeech'] as String?) ?? 'noun',
      definition: (json['definition'] as String?) ?? '',
      example: json['example'] as String?,
      synonyms: synonymsList,
      isBookmarked: json['is_bookmarked'] == true || json['is_bookmarked'] == 1,
    );
  }
}

