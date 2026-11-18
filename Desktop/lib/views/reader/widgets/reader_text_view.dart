import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ebook_app_desktop/controllers/dictionary_controller.dart';
import 'package:ebook_app_desktop/models/reader_settings.dart';
import 'package:ebook_app_desktop/views/dictionary/dictionary_bottom_sheet.dart';

class ReaderTextView extends StatefulWidget {
  final String content;
  final ReaderSettings settings;

  const ReaderTextView({
    super.key,
    required this.content,
    required this.settings,
  });

  @override
  State<ReaderTextView> createState() => _ReaderTextViewState();
}

class _ReaderTextViewState extends State<ReaderTextView> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
    super.dispose();
  }

  void _onWordTapped(BuildContext context, String rawWord) async {
    final definition = await context.read<DictionaryController>().lookupWord(rawWord);
    if (definition != null && context.mounted) {
      DictionaryBottomSheet.show(context, definition);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Clear previously stored recognizers before rebuilding
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final baseStyle = widget.settings.bodyTextStyle;
    final paragraphs = widget.content.split('\n\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.map((paragraph) {
        if (paragraph.trim().isEmpty) return const SizedBox.shrink();

        final tokens = paragraph.split(RegExp(r'(\s+)'));
        final spans = <InlineSpan>[];

        for (final token in tokens) {
          if (RegExp(r'^\s+$').hasMatch(token)) {
            spans.add(TextSpan(text: token, style: baseStyle));
            continue;
          }

          final recognizer = TapGestureRecognizer()
            ..onTap = () => _onWordTapped(context, token);
          _recognizers.add(recognizer);

          spans.add(
            TextSpan(
              text: token,
              style: baseStyle,
              recognizer: recognizer,
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Text.rich(
            TextSpan(children: spans),
            textAlign: TextAlign.start,
          ),
        );
      }).toList(),
    );
  }
}
