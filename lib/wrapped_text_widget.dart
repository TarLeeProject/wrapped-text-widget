import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class WrappedTextWidget extends StatefulWidget {
  WrappedTextWidget({
    super.key,
    required this.child,
    required this.paragraph,
    this.left = 0,
    this.top = 0,
    this.isDraggable = false,
    this.padding = EdgeInsets.zero,
    TextStyle? paragraphStyle,
  }) : paragraphStyle = paragraphStyle ?? TextStyle(color: Colors.black);

  final Widget child;
  final double left;
  final double top;
  final String paragraph;
  final bool isDraggable;
  final EdgeInsets padding;
  final TextStyle paragraphStyle;

  @override
  _MyWidgetState createState() => _MyWidgetState();
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
  bool useCharactersPackage = true,
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
      final lm = lines[t];
      if (y + lm.height < top + eps) {
        y += lm.height;
      } else {
        break;
      }
    }
    if (y == 0) {
      topPart = '';
    } else {
      final pos = tp.getPositionForOffset(Offset(fullWidth, y - eps));
      int index = pos.offset;
      topPart = useCharactersPackage
          ? currentText.characters.take(index).toString()
          : currentText.substring(0, index);

      currentText = currentText.substring(topPart.length).trim();

      topPart = topPart.trim();
    }

    do {
      final List<String> subList = [];
      for (int i = 0; i < segments.length; i++) {
        final tp = TextPainter(
          text: TextSpan(text: currentText, style: style),
          textDirection: TextDirection.ltr,
          textAlign: textAlign,
        );

        tp.layout(minWidth: 0, maxWidth: segments[i]);

        final lines = tp.computeLineMetrics();
        if (lines.isEmpty) {
          list.add(subList);
          return (topPart, list, currentText);
        }

        final pos = tp.getPositionForOffset(
          Offset(segments[i] - 1, lines.first.height - eps),
        );
        int index = pos.offset;

        String text = useCharactersPackage
            ? currentText.characters
                  .take(min(index, currentText.length))
                  .toString()
            : currentText.substring(0, min(index, currentText.length));

        subList.add(text.trim());

        currentText = currentText.substring(text.length).trim();

        text = text.trim();

        if (i == segments.length - 1) {
          splittedHeight += lines.first.height;
        }
      }
      list.add(subList);
    } while (splittedHeight < height);
    return (topPart, list, currentText);
  } catch (e, st) {
    debugPrint('There is an exception: $e');
    debugPrintStack(stackTrace: st);
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
