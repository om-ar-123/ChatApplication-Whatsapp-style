import 'package:flutter/material.dart';

/// Highlights @mentions in message text.
class MentionText extends StatelessWidget {
  const MentionText({
    super.key,
    required this.text,
    this.style,
    this.mentionColor = const Color(0xFF007AFF),
    this.currentUserName = 'OMAR',
  });

  final String text;
  final TextStyle? style;
  final Color mentionColor;
  final String currentUserName;

  @override
  Widget build(BuildContext context) {
    final defaultStyle = style ?? const TextStyle(fontSize: 15, height: 1.35, color: Color(0xFF111B21));
    final spans = <TextSpan>[];
    final regex = RegExp(r'@(\w+)');
    var lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start), style: defaultStyle));
      }
      final mentionName = match.group(1)!;
      final isCurrentUser = mentionName.toLowerCase() == currentUserName.toLowerCase();
      spans.add(TextSpan(
        text: '@$mentionName',
        style: defaultStyle.copyWith(
          color: isCurrentUser ? mentionColor : const Color(0xFF06CF9C),
          fontWeight: FontWeight.w600,
        ),
      ));
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: defaultStyle));
    }

    if (spans.isEmpty) {
      return Text(text, style: defaultStyle);
    }

    return RichText(text: TextSpan(children: spans));
  }
}
