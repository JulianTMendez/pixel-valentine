import 'package:flutter/material.dart';
import 'package:pixels/pixels.dart';
import 'package:pixorama_client/pixorama_client.dart';
import 'package:confetti/confetti.dart';

import '../../main.dart';

class Pixorama extends StatefulWidget {
  const Pixorama({super.key});

  @override
  State<Pixorama> createState() => _PixoramaState();
}

class _PixoramaState extends State<Pixorama> {
  // The pixel image controller contains our image data and handles updates.
  PixelImageController? _imageController;

  // Track the currently selected color and the pixels painted in the current stroke.
  int _selectedColorIndex =
      5; // Default to Red for the heart reveal (index 5 in rPlace)
  final Set<int> _paintedInStroke = {};

  final GlobalKey _editorKey = GlobalKey();

  // Confetti!
  late ConfettiController _confettiController;
  final Set<int> _heartPixelIndices = {};
  bool _hasCelebrated = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _listenToUpdates();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _initializeHeartPixelIndices(int width, int height) {
    if (_heartPixelIndices.isNotEmpty) return;

    // Use the same logic as the server to identify which pixels belong to the heart
    const List<String> heartTemplate = [
      "      XXXXXX         XXXXXX       ",
      "    XX......XXXX.XXXX......XX     ",
      "   X............X............X    ",
      "  X.....i.........u.....uuu...X   ",
      "  X...............u....u...u..X   ",
      " X......i.........u....u...u...X  ",
      " X......i.........uuuu..uuu....X  ",
      " X......i......................X   ",
      "  X.....i......v.....v eeee...X   ",
      "  X.....i.......v...v..e......X   ",
      "   X.............v.v...eeee..X    ",
      "    X.............v....e....X     ",
      "     X.................eeeeX      ",
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

    final startX = (width - 34) ~/ 2;
    final startY = (height - 24) ~/ 2;

    for (int y = 0; y < heartTemplate.length; y++) {
      final row = heartTemplate[y];
      for (int x = 0; x < row.length; x++) {
        if (row[x] != ' ') {
          final int pixelIndex = (startY + y) * width + (startX + x);
          if (pixelIndex >= 0 && pixelIndex < width * height) {
            _heartPixelIndices.add(pixelIndex);
          }
        }
      }
    }
  }

  void _checkCompletion() {
    if (_imageController == null || _hasCelebrated) return;

    // Check if every heart pixel is filled (color index != 2)
    bool isFull = true;
    for (final index in _heartPixelIndices) {
      if (_imageController!.pixels.getUint8(index) == 2) {
        isFull = false;
        break;
      }
    }

    if (isFull) {
      setState(() {
        _hasCelebrated = true;
      });
      _confettiController.play();
    }
  }

  Future<void> _listenToUpdates() async {
    while (true) {
      try {
        final imageUpdates = client.pixorama.imageUpdates();
        await for (final update in imageUpdates) {
          if (update is ImageData) {
            _initializeHeartPixelIndices(update.width, update.height);
            setState(() {
              _imageController = PixelImageController(
                pixels: update.pixels,
                palette: PixelPalette.rPlace(),
                width: update.width,
                height: update.height,
              );
            });
            _checkCompletion();
          } else if (update is ImageUpdate) {
            setState(() {
              _imageController?.setPixelIndex(
                pixelIndex: update.pixelIndex,
                colorIndex: update.colorIndex,
              );
            });
            _checkCompletion();
          }
        }
      } on MethodStreamException catch (_) {
        setState(() {
          _imageController = null;
        });
      }
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  void _handlePaint(Offset globalPosition) {
    if (_imageController == null) return;

    final RenderBox? renderBox =
        _editorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final Offset localPosition = renderBox.globalToLocal(globalPosition);
    final size = renderBox.size;
    final int width = _imageController!.width;
    final int height = _imageController!.height;

    // PixelEditor centers the pixel grid while maintaining aspect ratio.
    final double gridAspectRatio = width / height;
    final double widgetAspectRatio = size.width / size.height;

    double actualGridWidth, actualGridHeight, offsetX, offsetY;
    if (widgetAspectRatio > gridAspectRatio) {
      // Widget is wider than grid (height constrained)
      actualGridHeight = size.height;
      actualGridWidth = size.height * gridAspectRatio;
      offsetX = (size.width - actualGridWidth) / 2;
      offsetY = 0;
    } else {
      // Widget is taller than grid (width constrained)
      actualGridWidth = size.width;
      actualGridHeight = size.width / gridAspectRatio;
      offsetX = 0;
      offsetY = (size.height - actualGridHeight) / 2;
    }

    final double relativeX = localPosition.dx - offsetX;
    final double relativeY = localPosition.dy - offsetY;

    // Bounds check within the actual grid area
    if (relativeX >= 0 &&
        relativeX < actualGridWidth &&
        relativeY >= 0 &&
        relativeY < actualGridHeight) {
      final int centerX = (relativeX / actualGridWidth * width).floor();
      final int centerY = (relativeY / actualGridHeight * height).floor();

      // Brush Radius: 2 means 5x5 area
      const int radius = 1;
      for (int dy = -radius; dy <= radius; dy++) {
        for (int dx = -radius; dx <= radius; dx++) {
          final int x = centerX + dx;
          final int y = centerY + dy;

          if (x >= 0 && x < width && y >= 0 && y < height) {
            final int pixelIndex = y * width + x;

            if (!_paintedInStroke.contains(pixelIndex)) {
              _paintedInStroke.add(pixelIndex);
              client.pixorama.setPixel(
                pixelIndex: pixelIndex,
                colorIndex: _selectedColorIndex,
              );
            }
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF121212), // Sleek Dark Background
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Center(
            child: _imageController == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      CircularProgressIndicator(color: Colors.pinkAccent),
                      SizedBox(height: 20),
                      Text(
                        'Connecting to the Heart Server...',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onPanStart: (details) {
                            _paintedInStroke.clear();
                            _handlePaint(details.globalPosition);
                          },
                          onPanUpdate: (details) {
                            _handlePaint(details.globalPosition);
                          },
                          onPanEnd: (_) {
                            _paintedInStroke.clear();
                          },
                          child: KeyedSubtree(
                            key: _editorKey,
                            child: PixelEditor(
                              controller: _imageController!,
                              onSetPixel: (details) {
                                _selectedColorIndex = details.colorIndex;

                                final int width = _imageController!.width;
                                final int height = _imageController!.height;
                                final int centerX =
                                    details.tapDetails.index % width;
                                final int centerY =
                                    details.tapDetails.index ~/ width;

                                const int radius = 1;
                                for (int dy = -radius; dy <= radius; dy++) {
                                  for (int dx = -radius; dx <= radius; dx++) {
                                    final int x = centerX + dx;
                                    final int y = centerY + dy;
                                    if (x >= 0 &&
                                        x < width &&
                                        y >= 0 &&
                                        y < height) {
                                      final int pIndex = y * width + x;
                                      client.pixorama.setPixel(
                                        pixelIndex: pIndex,
                                        colorIndex: details.colorIndex,
                                      );
                                    }
                                  }
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          _hasCelebrated
                              ? '🎊 MAGICAL HEART REVEALED! 🎊'
                              : '🎨 Drag to paint! Reveal the secret message.',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.red,
              Colors.pink,
              Colors.white,
              Colors.orange,
              Colors.yellow,
            ],
          ),
        ],
      ),
    );
  }
}
