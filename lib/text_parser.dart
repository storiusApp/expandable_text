class TextSegment {
  String text;

  final String? name;
  final bool isHashtag;
  final bool isMention;
  final bool isUrl;

  bool get isText => !isHashtag && !isMention && !isUrl;

  TextSegment(this.text,
      [this.name,
      this.isHashtag = false,
      this.isMention = false,
      this.isUrl = false]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextSegment &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          name == other.name &&
          isHashtag == other.isHashtag &&
          isMention == other.isMention &&
          isUrl == other.isUrl;

  @override
  int get hashCode =>
      text.hashCode ^
      name.hashCode ^
      isHashtag.hashCode ^
      isMention.hashCode ^
      isUrl.hashCode;
}

/// Split the string into multiple instances of [TextSegment] for mentions, hashtags, URLs and regular text.
///
/// Mentions are all words that start with @, e.g. @mention.
/// Hashtags are all words that start with #, e.g. #hashtag.
List<TextSegment> parseText(String? text) {
  final segments = <TextSegment>[];

  if (text == null || text.isEmpty) {
    return segments;
  }

  // parse urls and words starting with @ (mention) or # (hashtag)
  RegExp exp = RegExp(
      r'(?<keyword>(?:@|#)\w+)|(?<url>((?:https?:\/\/)?(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.\S{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.\S{2,}|(?:https?:\/\/)?(?:www\.|(?!www))[a-zA-Z0-9]+\.\S{2,}|www\.[a-zA-Z0-9]+\.\S{2,}))',
      unicode: true);
  final matches = exp.allMatches(text);

  var start = 0;
  matches.forEach((match) {
    // text before the keyword
    if (match.start > start) {
      if (segments.isNotEmpty && segments.last.isText) {
        segments.last.text += text.substring(start, match.start);
      } else {
        segments.add(TextSegment(text.substring(start, match.start)));
      }
      start = match.start;
    }

    final url = match.namedGroup('url');
    final keyword = match.namedGroup('keyword');

    if (url != null) {
      segments.add(TextSegment(url, url, false, false, true));
    } else if (keyword != null) {
      final isWord = match.start == 0 ||
          [' ', '\n'].contains(text.substring(match.start - 1, start));
      if (!isWord) {
        return;
      }

      final isHashtag = keyword.startsWith('#');
      final isMention = keyword.startsWith('@');

      segments.add(
          TextSegment(keyword, keyword.substring(1), isHashtag, isMention));
    }

    start = match.end;
  });

  // text after the last keyword or the whole text if it does not contain any keywords
  if (start < text.length) {
    if (segments.isNotEmpty && segments.last.isText) {
      segments.last.text += text.substring(start);
    } else {
      segments.add(TextSegment(text.substring(start)));
    }
  }

  return segments;
}
