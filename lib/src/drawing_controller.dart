import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'helper/safe_value_notifier.dart';
import 'paint_contents/eraser.dart';
import 'paint_contents/paint_content.dart';
import 'paint_contents/simple_line.dart';
import 'paint_extension/ex_paint.dart';


class DrawConfig {
  DrawConfig({
    required this.contentType,
    this.angle = 0,
    this.fingerCount = 0,
    this.size,
    this.blendMode = BlendMode.srcOver,
    this.color = Colors.red,
    this.colorFilter,
    this.filterQuality = FilterQuality.high,
    this.imageFilter,
    this.invertColors = false,
    this.isAntiAlias = false,
    this.maskFilter,
    this.shader,
    this.strokeCap = StrokeCap.round,
    this.strokeJoin = StrokeJoin.round,
    this.strokeWidth = 4,
    this.style = PaintingStyle.stroke,
  });

  DrawConfig.def({
    required this.contentType,
    this.angle = 0,
    this.fingerCount = 0,
    this.size,
    this.blendMode = BlendMode.srcOver,
    this.color = Colors.red,
    this.colorFilter,
    this.filterQuality = FilterQuality.high,
    this.imageFilter,
    this.invertColors = false,
    this.isAntiAlias = false,
    this.maskFilter,
    this.shader,
    this.strokeCap = StrokeCap.round,
    this.strokeJoin = StrokeJoin.round,
    this.strokeWidth = 4,
    this.style = PaintingStyle.stroke,
  });


  final int angle;

  final Type contentType;

  final int fingerCount;

  final Size? size;


  final BlendMode blendMode;
  final Color color;
  final ColorFilter? colorFilter;
  final FilterQuality filterQuality;
  final ui.ImageFilter? imageFilter;
  final bool invertColors;
  final bool isAntiAlias;
  final MaskFilter? maskFilter;
  final Shader? shader;
  final StrokeCap strokeCap;
  final StrokeJoin strokeJoin;
  final double strokeWidth;
  final PaintingStyle style;


  Paint get paint => Paint()
    ..blendMode = blendMode
    ..color = color
    ..colorFilter = colorFilter
    ..filterQuality = filterQuality
    ..imageFilter = imageFilter
    ..invertColors = invertColors
    ..isAntiAlias = isAntiAlias
    ..maskFilter = maskFilter
    ..shader = shader
    ..strokeCap = strokeCap
    ..strokeJoin = strokeJoin
    ..strokeWidth = strokeWidth
    ..style = style;

  DrawConfig copyWith({
    Type? contentType,
    BlendMode? blendMode,
    Color? color,
    ColorFilter? colorFilter,
    FilterQuality? filterQuality,
    ui.ImageFilter? imageFilter,
    bool? invertColors,
    bool? isAntiAlias,
    MaskFilter? maskFilter,
    Shader? shader,
    StrokeCap? strokeCap,
    StrokeJoin? strokeJoin,
    double? strokeWidth,
    PaintingStyle? style,
    int? angle,
    int? fingerCount,
    Size? size,
  }) {
    return DrawConfig(
      contentType: contentType ?? this.contentType,
      angle: angle ?? this.angle,
      blendMode: blendMode ?? this.blendMode,
      color: color ?? this.color,
      colorFilter: colorFilter ?? this.colorFilter,
      filterQuality: filterQuality ?? this.filterQuality,
      imageFilter: imageFilter ?? this.imageFilter,
      invertColors: invertColors ?? this.invertColors,
      isAntiAlias: isAntiAlias ?? this.isAntiAlias,
      maskFilter: maskFilter ?? this.maskFilter,
      shader: shader ?? this.shader,
      strokeCap: strokeCap ?? this.strokeCap,
      strokeJoin: strokeJoin ?? this.strokeJoin,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      style: style ?? this.style,
      fingerCount: fingerCount ?? this.fingerCount,
      size: size ?? this.size,
    );
  }
}


class DrawingController extends ChangeNotifier {
  DrawingController({DrawConfig? config, PaintContent? content}) {
    _history = <PaintContent>[];
    _currentIndex = 0;
    realPainter = RePaintNotifier();
    painter = RePaintNotifier();
    drawConfig = SafeValueNotifier<DrawConfig>(
        config ?? DrawConfig.def(contentType: SimpleLine));
    setPaintContent(content ?? SimpleLine());
  }


  Offset? _startPoint;


  late GlobalKey painterKey = GlobalKey();


  late SafeValueNotifier<DrawConfig> drawConfig;


  late PaintContent _paintContent;

  
  PaintContent? currentContent;


  PaintContent? eraserContent;

  ui.Image? cachedImage;


  late List<PaintContent> _history;


  bool _mounted = true;


  List<PaintContent> get getHistory => _history;


  late int _currentIndex;


  RePaintNotifier? painter;


  RePaintNotifier? realPainter;


  int get currentIndex => _currentIndex;


  Color get getColor => drawConfig.value.color;


  bool get couldDraw => drawConfig.value.fingerCount <= 1;


  bool get hasPaintingContent =>
      currentContent != null || eraserContent != null;


  Offset? get startPoint => _startPoint;


  void setBoardSize(Size? size) {
    drawConfig.value = drawConfig.value.copyWith(size: size);
  }


  void addFingerCount(Offset offset) {
    drawConfig.value = drawConfig.value
        .copyWith(fingerCount: drawConfig.value.fingerCount + 1);
  }


  void reduceFingerCount(Offset offset) {
    if (drawConfig.value.fingerCount <= 0) {
      return;
    }

    drawConfig.value = drawConfig.value
        .copyWith(fingerCount: drawConfig.value.fingerCount - 1);
  }


  void setStyle({
    BlendMode? blendMode,
    Color? color,
    ColorFilter? colorFilter,
    FilterQuality? filterQuality,
    ui.ImageFilter? imageFilter,
    bool? invertColors,
    bool? isAntiAlias,
    MaskFilter? maskFilter,
    Shader? shader,
    StrokeCap? strokeCap,
    StrokeJoin? strokeJoin,
    double? strokeMiterLimit,
    double? strokeWidth,
    PaintingStyle? style,
  }) {
    drawConfig.value = drawConfig.value.copyWith(
      blendMode: blendMode,
      color: color,
      colorFilter: colorFilter,
      filterQuality: filterQuality,
      imageFilter: imageFilter,
      invertColors: invertColors,
      isAntiAlias: isAntiAlias,
      maskFilter: maskFilter,
      shader: shader,
      strokeCap: strokeCap,
      strokeJoin: strokeJoin,
      strokeWidth: strokeWidth,
      style: style,
    );
  }


  void setPaintContent(PaintContent content) {
    content.paint = drawConfig.value.paint;
    _paintContent = content;
    drawConfig.value =
        drawConfig.value.copyWith(contentType: content.runtimeType);
  }


  void addContent(PaintContent content) {
    _history.add(content);
    _currentIndex++;
    cachedImage = null;
    _refreshDeep();
  }


  void addContents(List<PaintContent> contents) {
    _history.addAll(contents);
    _currentIndex += contents.length;
    cachedImage = null;
    _refreshDeep();
  }


  void turn() {
    drawConfig.value =
        drawConfig.value.copyWith(angle: (drawConfig.value.angle + 1) % 4);
  }


  void startDraw(Offset startPoint) {
    if (_currentIndex == 0 && _paintContent is Eraser) {
      return;
    }

    _startPoint = startPoint;
    if (_paintContent is Eraser) {
      eraserContent = _paintContent.copy();
      eraserContent?.paint = drawConfig.value.paint.copyWith();
      eraserContent?.startDraw(startPoint);
    } else {
      currentContent = _paintContent.copy();
      currentContent?.paint = drawConfig.value.paint;
      currentContent?.startDraw(startPoint);
    }
  }


  void cancelDraw() {
    _startPoint = null;
    currentContent = null;
    eraserContent = null;
  }


  void drawing(Offset nowPaint) {
    if (!hasPaintingContent) {
      return;
    }

    if (_paintContent is Eraser) {
      eraserContent?.drawing(nowPaint);
      _refresh();
      _refreshDeep();
    } else {
      currentContent?.drawing(nowPaint);
      _refresh();
    }
  }


  void endDraw() {
    if (!hasPaintingContent) {
      return;
    }

    _startPoint = null;
    final int hisLen = _history.length;

    if (hisLen > _currentIndex) {
      _history.removeRange(_currentIndex, hisLen);
    }

    if (eraserContent != null) {
      _history.add(eraserContent!);
      _currentIndex = _history.length;
      eraserContent = null;
    }

    if (currentContent != null) {
      _history.add(currentContent!);
      _currentIndex = _history.length;
      currentContent = null;
    }

    _refresh();
    _refreshDeep();
    notifyListeners();
  }


  void undo() {
    cachedImage = null;
    if (_currentIndex > 0) {
      _currentIndex = _currentIndex - 1;
      _refreshDeep();
      notifyListeners();
    }
  }


  bool canUndo() {
    if (_currentIndex > 0) {
      return true;
    } else {
      return false;
    }
  }


  void redo() {
    cachedImage = null;
    if (_currentIndex < _history.length) {
      _currentIndex = _currentIndex + 1;
      _refreshDeep();
      notifyListeners();
    }
  }


  bool canRedo() {
    if (_currentIndex < _history.length) {
      return true;
    } else {
      return false;
    }
  }


  void clear() {
    cachedImage = null;
    _history.clear();
    _currentIndex = 0;
    _refreshDeep();
  }


  Future<ByteData?> getImageData() async {
    try {
      final RenderRepaintBoundary boundary = painterKey.currentContext!
          .findRenderObject()! as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(
          pixelRatio: View.of(painterKey.currentContext!).devicePixelRatio);
      return await image.toByteData(format: ui.ImageByteFormat.png);
    } catch (e) {
      debugPrint('获取图片数据出错:$e');
      return null;
    }
  }


  Future<ByteData?> getSurfaceImageData() async {
    try {
      if (cachedImage != null) {
        return await cachedImage!.toByteData(format: ui.ImageByteFormat.png);
      }
      return null;
    } catch (e) {
      debugPrint('获取表层图片数据出错:$e');
      return null;
    }
  }


  List<Map<String, dynamic>> getJsonList() {
    return _history.map((PaintContent e) => e.toJson()).toList();
  }


  void _refresh() {
    painter?._refresh();
  }


  void _refreshDeep() {
    realPainter?._refresh();
  }


  @override
  void dispose() {
    if (!_mounted) {
      return;
    }

    drawConfig.dispose();
    realPainter?.dispose();
    painter?.dispose();
    _history.clear();
    _currentIndex = 0;
    _startPoint = null;
    cachedImage = null;

    _mounted = false;
    super.dispose();
  }
}


class RePaintNotifier extends ChangeNotifier {
  void _refresh() {
    notifyListeners();
  }
}
