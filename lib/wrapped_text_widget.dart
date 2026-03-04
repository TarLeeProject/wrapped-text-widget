import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

/// A widget that allows a paragraph of text to wrap around another widget.
///
/// This widget is useful when you want to display text flowing around an
/// embedded widget such as an image or a decorative element. Common use
/// cases include blog-style text wrapping or implementing a drop cap effect.
///
/// The [WrappedTextWidget] takes a [child] widget that the text will wrap
/// around, and a [paragraph] which represents the text content.
///
/// You can control the position of the [child] using the [left] and [top]
/// offsets. The child can optionally be made draggable by setting
/// [isDraggable] to true, and additional spacing around it can be added
/// via the [padding] parameter.
///
/// See also:
///
///  * [Text], the basic widget for displaying text.
///
class WrappedTextWidget extends StatefulWidget {
  /// Creates a widget that allows a paragraph of text to wrap around
  /// another widget.
  WrappedTextWidget({
    super.key,
    required this.child,
    required this.paragraph,
    this.left = 0.0,
    this.top = 0.0,
    this.isDraggable = false,
    this.padding = EdgeInsets.zero,
    TextStyle? paragraphStyle,
  }) : paragraphStyle = paragraphStyle ?? TextStyle(color: Colors.black);

  /// The widget that the paragraph will wrap around.
  ///
  /// This is typically an [Image], [Icon], or any decorative widget.
  final Widget child;

  /// The horizontal offset of the widget from the left edge.
  ///
  /// This value represents the x-coordinate of the widget's top-left corner.
  ///
  /// Default is `0.0`
  final double left;

  /// The vertical offset of the widget from the top edge.
  ///
  /// This value represents the y-coordinate of the widget's top-left corner.
  ///
  /// Default is `0.0`
  final double top;

  /// The text content that flows around the widget.
  final String paragraph;

  /// Whether the widget can be dragged by the user.
  ///
  /// When set to true, the widget can be repositioned via drag gestures.
  ///
  /// Default is `false`
  final bool isDraggable;

  /// The padding applied around the widget.
  ///
  /// This creates spacing between the widget and the surrounding text.
  ///
  /// Default is `EdgeInsets.zero`
  final EdgeInsets padding;

  /// The text style applied to the paragraph.
  ///
  /// This controls the font, color, and other visual properties of the text.
  ///
  /// Default value is `TextStyle(color: Colors.black)`
  final TextStyle paragraphStyle;

  @override
  State<WrappedTextWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<WrappedTextWidget> {
  static const _debounceTime = 100;

  final _key = GlobalKey();
  final parentKey = GlobalKey();

  double? _width;
  double? _height;
  double? _left;
  double? _top;

  double get width => _width ?? 0;
  double get height => _height ?? 0;
  double get left => _left ?? 0;
  double get top => _top ?? 0;

  final _drgPos = ValueNotifier<Offset>(Offset.zero);
  final _texts = ValueNotifier((
    '',
    [
      [''],
      [''],
    ],
    '',
  ));
  List<double> _segments = [];

  Timer? _timer;

  late BoxConstraints _constraint;

  @override
  void initState() {
    super.initState();
    _drgPos.value = Offset(widget.left, widget.top);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _updatedBounds();
      });
    });
  }

  @override
  void didUpdateWidget(WrappedTextWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _drgPos.value = Offset(widget.left, widget.top);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _updatedBounds();
      });
    });
  }

  void _updatedBounds() {
    try {
      final renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
      final parentBox =
          parentKey.currentContext?.findRenderObject() as RenderBox?;

      if (renderBox != null && parentBox != null) {
        final offset = renderBox.localToGlobal(
          Offset.zero,
          ancestor: parentBox,
        );
        _width = renderBox.size.width;
        _height = renderBox.size.height;
        _left = offset.dx;
        _top = min(offset.dy, parentBox.size.height - 1);

        if ((top + height) >= parentBox.size.height) {
          _height = max(1, parentBox.size.height - top);
        } else if (offset.dy < 0) {
          _height = renderBox.size.height + offset.dy;
        }

        if (left < 0) {
          _width = max(1, renderBox.size.width + left);
        }
      }
    } catch (e, st) {
      debugPrint('There is a exception while calculate metrics: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  void _updateParagraph() {
    final maxWidth = _constraint.maxWidth;
    _segments = [max(1, left), max(maxWidth - max(left, 1) - width, 1)];
    _texts.value = _substringByHeightLineMetrics(
      widget.paragraph,
      _segments,
      height,
      top,
      widget.paragraphStyle,
      maxWidth,
      textAlign: TextAlign.justify,
    );
  }

  void _debounce(Function function) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: _debounceTime), () {
      function.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _constraint = constraints;
        _updateParagraph();
        return Column(
          key: parentKey,
          children: [
            ValueListenableBuilder(
              valueListenable: _drgPos,
              builder: (context, position, child) {
                return Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_texts.value.$1.isNotEmpty)
                          RichText(
                            text: TextSpan(
                              text: _texts.value.$1.replaceAll("¶", ""),
                              style: widget.paragraphStyle,
                            ),
                            textAlign: TextAlign.justify,
                          ),
                        Column(
                          children: _texts.value.$2.map((lines) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                if (lines.isNotEmpty)
                                  SizedBox(
                                    width: _segments[0],
                                    child:
                                        lines.length == 1 ||
                                            lines[0].contains("¶")
                                        ? RichText(
                                            text: TextSpan(
                                              text: lines[0].replaceAll(
                                                "¶",
                                                "",
                                              ),
                                              style: widget.paragraphStyle,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: lines[0]
                                                .replaceAll("¶", "")
                                                .split(' ')
                                                .map(
                                                  (word) => RichText(
                                                    text: TextSpan(
                                                      text: word,
                                                      style:
                                                          widget.paragraphStyle,
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                  ),
                                SizedBox(
                                  width: min(
                                    width,
                                    constraints.maxWidth - left - 1,
                                  ),
                                ),
                                if (lines.length >= 2)
                                  SizedBox(
                                    width: _segments[1],
                                    child: lines[1].contains("¶")
                                        ? RichText(
                                            text: TextSpan(
                                              text: lines[1].replaceAll(
                                                "¶",
                                                "",
                                              ),
                                              style: widget.paragraphStyle,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: lines[1]
                                                .replaceAll("¶", "")
                                                .split(' ')
                                                .map(
                                                  (word) => RichText(
                                                    text: TextSpan(
                                                      text: word,
                                                      style:
                                                          widget.paragraphStyle,
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                  ),
                              ],
                            );
                          }).toList(),
                        ),
                        if (_texts.value.$3.isNotEmpty)
                          RichText(
                            text: TextSpan(
                              text: _texts.value.$3.replaceAll("¶", ""),
                              style: widget.paragraphStyle,
                            ),
                            textAlign: TextAlign.justify,
                          ),
                      ],
                    ),
                    Positioned(
                      left: position.dx,
                      top: position.dy,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          if (!widget.isDraggable) return;
                          _drgPos.value = Offset(
                            position.dx + details.delta.dx,
                            position.dy + details.delta.dy,
                          );
                          _debounce(
                            () => setState(() {
                              _updatedBounds();
                              _updateParagraph();
                            }),
                          );
                        },
                        child: Container(
                          key: _key,
                          child: Padding(
                            padding: widget.padding,
                            child: widget.child,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

(String, List<List<String>>, String) _substringByHeightLineMetrics(
  String originalParagraph,
  List<double> segments,
  double height,
  double top,
  TextStyle style,
  double fullWidth, {
  TextAlign textAlign = TextAlign.justify,
}) {
  final paragraph = originalParagraph.replaceAll("\n", "¶\n");
  try {
    final List<List<String>> list = [];
    String currentText = paragraph.trim();
    double splittedHeight = 0;
    String topPart = '';

    final tp = TextPainter(
      text: TextSpan(text: currentText, style: style),
      textDirection: TextDirection.ltr,
      textAlign: textAlign,
    );
    tp.layout(minWidth: 0, maxWidth: fullWidth);

    final lines = tp.computeLineMetrics();
    double y = 0.0;
    const eps = 0.0001;

    for (var t = 0; t < lines.length; t++) {
      if (y + lines[t].height < top + eps) {
        y += lines[t].height;
      } else {
        break;
      }
    }

    if (y > 0) {
      final pos = tp.getPositionForOffset(Offset(fullWidth, y - eps));
      topPart = _getSafePart(currentText, pos.offset, tp);
      currentText = currentText.substring(topPart.length).trim();
      topPart = topPart.trim();
    }

    do {
      final List<String> subList = [];
      for (int i = 0; i < segments.length; i++) {
        if (currentText.isEmpty) break;

        final tpSegment = TextPainter(
          text: TextSpan(text: currentText, style: style),
          textDirection: TextDirection.ltr,
          textAlign: textAlign,
        );
        tpSegment.layout(minWidth: 0, maxWidth: segments[i]);

        final sLines = tpSegment.computeLineMetrics();
        if (sLines.isEmpty) break;

        final pos = tpSegment.getPositionForOffset(
          Offset(segments[i] - 1, sLines.first.height - eps),
        );

        String textPart = _getSafePart(currentText, pos.offset, tpSegment);

        subList.add(textPart.trim());
        currentText = currentText.substring(textPart.length).trim();

        if (i == segments.length - 1) {
          splittedHeight += sLines.first.height;
        }
      }

      if (subList.isNotEmpty) {
        list.add(subList);
      } else {
        break;
      }
    } while (splittedHeight < height && currentText.isNotEmpty);

    return (topPart, list, currentText);
  } catch (e, stackTrace) {
    debugPrint('Exception: $e');
    debugPrint('Stacktrace: $stackTrace');
    return (
      '',
      [
        [''],
        [''],
      ],
      '',
    );
  }
}

String _getSafePart(String text, int offset, TextPainter measuredPainter) {
  if (offset <= 0) return "";
  if (offset >= text.length) return text;

  final wordRange = measuredPainter.getWordBoundary(
    TextPosition(offset: offset),
  );
  int safeOffset = offset;

  if (offset > wordRange.start && offset < wordRange.end) {
    safeOffset = wordRange.start;
  }

  final range = CharacterRange.at(text, 0, safeOffset);

  if (range.current.isEmpty && text.isNotEmpty) {
    return text.characters.take(1).toString();
  }

  return range.current;
}
