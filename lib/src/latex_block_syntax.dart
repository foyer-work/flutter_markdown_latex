import 'package:markdown/markdown.dart';

/// Syntax for block-level LaTeX expressions
class LatexBlockSyntax extends BlockSyntax {
  /// Pattern for matching block-level LaTeX expressions
  /// Matches:
  /// 1. Single or double dollar signs at start of line
  /// 2. LaTeX display math mode \[...\]
  @override
  RegExp get pattern => RegExp(
        r'^(?:(\${1,2})(?:\n|$))|(?:(?:\\\[(.+)\\\])(?:\n|$))',
        multiLine: true,
      );

  LatexBlockSyntax() : super();

  @override
  List<Line> parseChildLines(BlockParser parser) {
    final m = pattern.firstMatch(parser.current.content);

    // Handle \[...\] syntax
    if (m?[2] != null) {
      parser.advance();
      final content = m?[2] ?? '';

      if (content.isEmpty) {
        return [];
      }

      return [Line(content)];
    }

    // Handle $$...$$ syntax
    final childLines = <Line>[];
    parser.advance();

    while (!parser.isDone) {
      final match = pattern.hasMatch(parser.current.content);
      if (!match) {
        childLines.add(parser.current);
        parser.advance();
      } else {
        parser.advance();
        break;
      }
    }

    return childLines;
  }

  @override
  Node parse(BlockParser parser) {
    final lines = parseChildLines(parser);
    if (lines.isEmpty) return Element.empty('p');

    final content = lines.map((e) => e.content).join('\n').trim();
    if (content.isEmpty) return Element.empty('p');

    final textElement = Element.text('latex', content);
    textElement.attributes['MathStyle'] = 'display';

    return Element('p', [textElement]);
  }
}
