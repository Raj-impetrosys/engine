// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

class HtmlRenderer implements Renderer {
  static HtmlRenderer get instance => _instance;
  static late HtmlRenderer _instance;

  @override
  String get rendererTag => 'html';

  late final HtmlFontCollection _fontCollection = HtmlFontCollection();

  late FlutterViewEmbedder _viewEmbedder;

  @override
  HtmlFontCollection get fontCollection => _fontCollection;

  @override
  void initialize() {
    scheduleMicrotask(() {
      // Access [lineLookup] to force the lazy unpacking of line break data
      // now. Removing this line won't break anything. It's just an optimization
      // to make the unpacking happen while we are waiting for network requests.
      lineLookup;
    });

    _instance = this;
  }

  @override
  void reset(FlutterViewEmbedder embedder) {
    _viewEmbedder = embedder;
  }

  @override
  ui.Paint createPaint() => SurfacePaint();

  @override
  ui.Vertices createVertices(
    ui.VertexMode mode,
    List<ui.Offset> positions, {
    List<ui.Offset>? textureCoordinates,
    List<ui.Color>? colors,
    List<int>? indices,
  }) => SurfaceVertices(
    mode,
    positions,
    colors: colors,
    indices: indices);

  @override
  ui.Vertices createVerticesRaw(
    ui.VertexMode mode,
    Float32List positions, {
    Float32List? textureCoordinates,
    Int32List? colors,
    Uint16List? indices,
  }) => SurfaceVertices.raw(
    mode,
    positions,
    colors: colors,
    indices: indices);

  @override
  ui.Canvas createCanvas(ui.PictureRecorder recorder, [ui.Rect? cullRect]) =>
    SurfaceCanvas(recorder as EnginePictureRecorder, cullRect);

  @override
  ui.Gradient createLinearGradient(
    ui.Offset from,
    ui.Offset to,
    List<ui.Color> colors, [
    List<double>? colorStops,
    ui.TileMode tileMode = ui.TileMode.clamp,
    Float32List? matrix4
  ]) => GradientLinear(from, to, colors, colorStops, tileMode, matrix4);

  @override
  ui.Gradient createRadialGradient(
    ui.Offset center,
    double radius,
    List<ui.Color> colors, [
    List<double>? colorStops,
    ui.TileMode tileMode = ui.TileMode.clamp,
    Float32List? matrix4,
  ]) => GradientRadial(center, radius, colors, colorStops, tileMode, matrix4);

  @override
  ui.Gradient createConicalGradient(
    ui.Offset focal,
    double focalRadius,
    ui.Offset center,
    double radius,
    List<ui.Color> colors,
    [List<double>? colorStops,
    ui.TileMode tileMode = ui.TileMode.clamp,
    Float32List? matrix
  ]) => GradientConical(
    focal,
    focalRadius,
    center,
    radius,
    colors,
    colorStops,
    tileMode,
    matrix);

  @override
  ui.Gradient createSweepGradient(
    ui.Offset center,
    List<ui.Color> colors, [
    List<double>? colorStops,
    ui.TileMode tileMode = ui.TileMode.clamp,
    double startAngle = 0.0,
    double endAngle = math.pi * 2,
    Float32List? matrix4
  ]) => GradientSweep(center, colors, colorStops, tileMode, startAngle, endAngle, matrix4);

  @override
  ui.PictureRecorder createPictureRecorder() => EnginePictureRecorder();

  @override
  ui.SceneBuilder createSceneBuilder() => SurfaceSceneBuilder();

  // TODO(ferhat): implement TileMode.
  @override
  ui.ImageFilter createBlurImageFilter({
    double sigmaX = 0.0,
    double sigmaY = 0.0,
    ui.TileMode tileMode = ui.TileMode.clamp
  }) => EngineImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY, tileMode: tileMode);

  @override
  ui.ImageFilter createDilateImageFilter({double radiusX = 0.0, double radiusY = 0.0}) {
    // TODO(fzyzcjy): implement dilate. https://github.com/flutter/flutter/issues/101085
    throw UnimplementedError('ImageFilter.dilate not implemented for HTML renderer.');
  }

  @override
  ui.ImageFilter createErodeImageFilter({double radiusX = 0.0, double radiusY = 0.0}) {
    // TODO(fzyzcjy): implement erode. https://github.com/flutter/flutter/issues/101085
    throw UnimplementedError('ImageFilter.erode not implemented for HTML renderer.');
  }

  @override
  ui.ImageFilter createMatrixImageFilter(
    Float64List matrix4, {
    ui.FilterQuality filterQuality = ui.FilterQuality.low
  }) => EngineImageFilter.matrix(matrix: matrix4, filterQuality: filterQuality);

  @override
  ui.ImageFilter composeImageFilters({required ui.ImageFilter outer, required ui.ImageFilter inner}) {
    // TODO(ferhat): add implementation and remove the "ignore".
    // ignore: avoid_unused_constructor_parameters
    throw UnimplementedError('ImageFilter.erode not implemented for HTML renderer.');
  }

  @override
  Future<ui.Codec> instantiateImageCodec(
    Uint8List list, {
    int? targetWidth,
    int? targetHeight,
    bool allowUpscaling = true}) async {
    final DomBlob blob = createDomBlob(<dynamic>[list.buffer]);
    return HtmlBlobCodec(blob);
  }

  @override
  Future<ui.Codec> instantiateImageCodecFromUrl(
    Uri uri, {
    WebOnlyImageCodecChunkCallback? chunkCallback}) {
      return futurize<ui.Codec>((Callback<ui.Codec> callback) {
        callback(HtmlCodec(uri.toString(), chunkCallback: chunkCallback));
        return null;
      });
  }

  @override
  void decodeImageFromPixels(
    Uint8List pixels,
    int width,
    int height,
    ui.PixelFormat format,
    ui.ImageDecoderCallback callback, {
    int? rowBytes,
    int? targetWidth,
    int? targetHeight,
    bool allowUpscaling = true
  }) {
    void executeCallback(ui.Codec codec) {
      codec.getNextFrame().then((ui.FrameInfo frameInfo) {
        callback(frameInfo.image);
      });
    }
    ui.createBmp(pixels, width, height, rowBytes ?? width, format).then(
      executeCallback);
  }

  @override
  ui.ImageShader createImageShader(
    ui.Image image,
    ui.TileMode tmx,
    ui.TileMode tmy,
    Float64List matrix4,
    ui.FilterQuality? filterQuality
  ) => EngineImageShader(image, tmx, tmy, matrix4, filterQuality);

  @override
  ui.Path createPath() => SurfacePath();

  @override
  ui.Path copyPath(ui.Path src) => SurfacePath.from(src as SurfacePath);

  @override
  ui.Path combinePaths(ui.PathOperation op, ui.Path path1, ui.Path path2) {
    throw UnimplementedError('combinePaths not implemented in HTML renderer.');
  }

  @override
  ui.TextStyle createTextStyle({
    ui.Color? color,
    ui.TextDecoration? decoration,
    ui.Color? decorationColor,
    ui.TextDecorationStyle? decorationStyle,
    double? decorationThickness,
    ui.FontWeight? fontWeight,
    ui.FontStyle? fontStyle,
    ui.TextBaseline? textBaseline,
    String? fontFamily,
    List<String>? fontFamilyFallback,
    double? fontSize,
    double? letterSpacing,
    double? wordSpacing,
    double? height,
    ui.TextLeadingDistribution? leadingDistribution,
    ui.Locale? locale,
    ui.Paint? background,
    ui.Paint? foreground,
    List<ui.Shadow>? shadows,
    List<ui.FontFeature>? fontFeatures,
    List<ui.FontVariation>? fontVariations
  }) => EngineTextStyle(
    color: color,
    decoration: decoration,
    decorationColor: decorationColor,
    decorationStyle: decorationStyle,
    decorationThickness: decorationThickness,
    fontWeight: fontWeight,
    fontStyle: fontStyle,
    textBaseline: textBaseline,
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: fontSize,
    letterSpacing: letterSpacing,
    wordSpacing: wordSpacing,
    height: height,
    locale: locale,
    background: background,
    foreground: foreground,
    shadows: shadows,
    fontFeatures: fontFeatures,
    fontVariations: fontVariations,
  );

  @override
  ui.ParagraphStyle createParagraphStyle({
    ui.TextAlign? textAlign,
    ui.TextDirection? textDirection,
    int? maxLines,
    String? fontFamily,
    double? fontSize,
    double? height,
    ui.TextHeightBehavior? textHeightBehavior,
    ui.FontWeight? fontWeight,
    ui.FontStyle? fontStyle,
    ui.StrutStyle? strutStyle,
    String? ellipsis,
    ui.Locale? locale
  }) => EngineParagraphStyle(
    textAlign: textAlign,
    textDirection: textDirection,
    maxLines: maxLines,
    fontFamily: fontFamily,
    fontSize: fontSize,
    height: height,
    textHeightBehavior: textHeightBehavior,
    fontWeight: fontWeight,
    fontStyle: fontStyle,
    strutStyle: strutStyle,
    ellipsis: ellipsis,
    locale: locale,
  );

  @override
  ui.StrutStyle createStrutStyle({
    String? fontFamily,
    List<String>? fontFamilyFallback,
    double? fontSize,
    double? height,
    ui.TextLeadingDistribution? leadingDistribution,
    double? leading,
    ui.FontWeight? fontWeight,
    ui.FontStyle? fontStyle,
    bool? forceStrutHeight
  }) => EngineStrutStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: fontSize,
    height: height,
    leadingDistribution: leadingDistribution,
    leading: leading,
    fontWeight: fontWeight,
    fontStyle: fontStyle,
    forceStrutHeight: forceStrutHeight,
  );

  @override
  ui.ParagraphBuilder createParagraphBuilder(ui.ParagraphStyle style) =>
    CanvasParagraphBuilder(style as EngineParagraphStyle);

  @override
  void renderScene(ui.Scene scene) {
    _viewEmbedder.addSceneToSceneHost((scene as SurfaceScene).webOnlyRootElement);
    frameTimingsOnRasterFinish();
  }

  @override
  void clearFragmentProgramCache() { }

  @override
  Future<ui.FragmentProgram> createFragmentProgram(String assetKey) {
    return Future<HtmlFragmentProgram>.value(HtmlFragmentProgram());
  }
}
