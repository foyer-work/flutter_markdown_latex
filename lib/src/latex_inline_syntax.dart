import 'package:markdown/markdown.dart';

final List<Map<String, dynamic>> delimiterList = [
  {'left': r'$$', 'right': r'$$', 'display': true},
  {'left': r'$', 'right': r'$', 'display': false},
  {'left': r'\pu{', 'right': '}', 'display': false},
  {'left': r'\ce{', 'right': '}', 'display': false},
  {'left': r'\(', 'right': r'\)', 'display': false},
  {'left': '( ', 'right': ' )', 'display': false},
  {'left': r'\[', 'right': r'\]', 'display': true},
  {'left': '[ ', 'right': ' ]', 'display': true},
];

/// Cache for escaped delimiters
final Map<String, String> _escapedDelimiters = {};

/// List of compiled regex patterns for inline LaTeX
List<String> inlinePatterns = [];

/// List of compiled regex patterns for block LaTeX
List<String> blockPatterns = [];

/// Escapes special regex characters in a string
String escapeRegex(String string) {
  if (_escapedDelimiters.containsKey(string)) {
    return _escapedDelimiters[string]!;
  }

  final escaped = string.replaceAllMapped(
      RegExp(
        r'[-\/\\^$*+?.()|[\]{}]',
      ), (match) {
    return '\\${match.group(0)}';
  });

  _escapedDelimiters[string] = escaped;
  return escaped;
}

/// Generates regex rules for LaTeX delimiters
String generateRegexRules(List<Map<String, dynamic>> delimiters) {
  for (var delimiter in delimiters) {
    String left = delimiter['left'];
    String right = delimiter['right'];

    // Ensure regex-safe delimiters
    String escapedLeft = escapeRegex(left);
    String escapedRight = escapeRegex(right);

    // Inline pattern with improved handling of escaped characters
    inlinePatterns.add('$escapedLeft((?:\\\\.|[^\\\\\\n])*?(?:\\\\.|[^\\\\\\n]|(?!$escapedRight)))$escapedRight');

    // Block pattern with improved handling of escaped characters
    blockPatterns.add('$escapedLeft\\n((?:\\\\[^]|[^\\\\])+?)\\n$escapedRight');
  }

  return '(${inlinePatterns.join("|")})(?=[\\s?!.,:？！。，：]|\$)';
}

/// Compiled regex pattern for LaTeX expressions
final _latexPattern = generateRegexRules(delimiterList);

/// Syntax for inline LaTeX expressions
class LatexInlineSyntax extends InlineSyntax {
  LatexInlineSyntax() : super(_latexPattern);

  @override
  bool onMatch(InlineParser parser, Match match) {
    String raw = match.group(0) ?? '';

    // Validate input
    if (raw.isEmpty) return false;

    int delimiterLength = 1;
    String mathStyle = 'text';

    // Find matching delimiter
    for (var delimiter in delimiterList) {
      if (raw.startsWith(delimiter['left']) && raw.endsWith(delimiter['right'])) {
        mathStyle = delimiter['display'] ? 'display' : 'text';
        delimiterLength = delimiter['left'].length;
        break;
      }
    }

    // Extract equation content
    final equation = raw
        .substring(
          delimiterLength,
          raw.length - delimiterLength,
        )
        .trim();

    // Skip empty equations
    if (equation.isEmpty) {
      return false;
    }

    final element = Element.text('latex', equation);
    element.attributes['MathStyle'] = mathStyle;
    parser.addNode(element);

    return true;
  }
}
