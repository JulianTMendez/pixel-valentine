// lib/src/endpoints/pixorama_endpoint.dart

import 'dart:typed_data';

import 'package:pixorama_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

class PixoramaEndpoint extends Endpoint {
  static const _imageWidth = 64;
  static const _imageHeight = 64;
  static const _numPixels = _imageWidth * _imageHeight;

  static const _numColorsInPalette = 16;
  static const _defaultPixelColor = 2; // Usually background
  static const _outlineColor = 0; // Black for outline
  static const _revealedColor = 0; // Black for revealed message

  static const List<String> _heartAndMessage = [
    "      XXXXXX         XXXXXX       ",
    "    XX......XXXX.XXXX......XX     ",
    "   X............X............X    ",
    "  X...........................X   ",
    "  X..l.....l1111.v.......veeeeX   ",
    " X...l....l.....1.v.....v.e....X  ",
    " X...l....l.....1..v...v..eeee.X  ",
    " X...l....l.....1...v.v...e....X   ",
    "  X..lllll.lllll.....v....eeeeX   ",
    "  X...........................X   ",
    "   X.........................X    ",
    "    X.......................X     ",
    "     X.....................X      ",
    "      X...................X       ",
    "       X.................X        ",
    "        X...............X         ",
    "         X.............X          ",
    "          X...........X           ",
    "           X.........X            ",
    "            X.......X             ",
    "             X.....X              ",
    "              X...X               ",
    "               X.X                ",
    "                X                 ",
  ];

  late final Uint8List _pixelData;
  late final Set<int> _messagePixels;
  late final Set<int> _outlinePixels;

  PixoramaEndpoint() {
    _pixelData = Uint8List(_numPixels)
      ..fillRange(0, _numPixels, _defaultPixelColor);
    _messagePixels = {};
    _outlinePixels = {};
    _initializeHeartAndMessage();
    print(
      'Initialized Pixorama: ${_outlinePixels.length} outline pixels, ${_messagePixels.length} message pixels.',
    );
  }

  void _initializeHeartAndMessage() {
    const startX = (_imageWidth - 34) ~/ 2;
    const startY = (_imageHeight - 24) ~/ 2;

    for (int y = 0; y < _heartAndMessage.length; y++) {
      final row = _heartAndMessage[y];
      for (int x = 0; x < row.length; x++) {
        final char = row[x];
        final pixelIndex = (startY + y) * _imageWidth + (startX + x);
        if (pixelIndex < 0 || pixelIndex >= _numPixels) continue;

        if (char == 'X') {
          _pixelData[pixelIndex] = _outlineColor;
          _outlinePixels.add(pixelIndex);
        } else if (RegExp(r'[a-zA-Z]').hasMatch(char)) {
          _messagePixels.add(pixelIndex);
        }
      }
    }
  }

  static const _channelPixelAdded = 'pixel-added';

  Future<void> setPixel(
    Session session, {
    required int colorIndex,
    required int pixelIndex,
  }) async {
    if (colorIndex < 0 || colorIndex >= _numColorsInPalette) {
      throw FormatException('colorIndex is out of range: $colorIndex');
    }
    if (pixelIndex < 0 || pixelIndex >= _numPixels) {
      throw FormatException('pixelIndex is out of range: $pixelIndex');
    }

    int finalColor = colorIndex;

    // 1. Protect Outline: Outline always stays black.
    if (_outlinePixels.contains(pixelIndex)) {
      finalColor = _outlineColor;
    }
    // 2. Secret Message: Once revealed (or if filling with any non-background color), it stays black.
    else if (_messagePixels.contains(pixelIndex)) {
      if (_pixelData[pixelIndex] == _revealedColor ||
          (colorIndex != _defaultPixelColor)) {
        finalColor = _revealedColor;
      }
    }

    _pixelData[pixelIndex] = finalColor;

    session.messages.postMessage(
      _channelPixelAdded,
      ImageUpdate(
        pixelIndex: pixelIndex,
        colorIndex: finalColor,
      ),
    );
  }

  /// Returns a stream of image updates.
  Stream<dynamic> imageUpdates(Session session) async* {
    var updateStream = session.messages.createStream<ImageUpdate>(
      _channelPixelAdded,
    );

    yield ImageData(
      pixels: _pixelData.buffer.asByteData(),
      width: _imageWidth,
      height: _imageHeight,
    );

    await for (var imageUpdate in updateStream) {
      yield imageUpdate;
    }
  }
}
